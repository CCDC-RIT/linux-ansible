#!/bin/bash

fixes() {
    change_rule_status "test" "no"
}

PUBLIC="Public"
DMZ="DMZ"
PRIVATE="Private"
Management="Management"

FIREWALL_IP=""
read -s -p "Enter firewall IP: " FIREWALL_IP
echo ""

USER=""
read -s -p "Enter username: " USER
echo ""

PASSWORD=""
read -s -p "Enter password: " PASSWORD
echo ""

echo "Obtaining API key"
sleep 1
RAW=$(curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST https://$FIREWALL_IP/api/?type=keygen -d "user=$USER&password=$PASSWORD")
API_KEY=$(awk -v str="$RAW" 'BEGIN { split(str, parts, "<key>|</key>"); print parts[2] }')

echo "Overriding template for services..."
sleep 1
curl -ks -X POST "https://$FIREWALL_IP/api/" \
    -d "type=config&action=override&key=$API_KEY" \
    --data-urlencode "xpath=/config/shared/service"

create_rule() {
    local rule_name="$1"
    local from_zone="$2"
    local to_zone="$3"
    local source_ip="$4"
    local dest_ip="$5"
    local services="$6"
    local application="$7"
    local action="$8"

    local service_xml=""
    for svc in $services; do
        service_xml+="<member>$svc</member>"
    done

    echo "Creating rule $rule_name with services: $services"
    curl -k -X POST "https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY" \
        --data-urlencode "xpath=/config/devices/entry/vsys/entry[@name='vsys1']/rulebase/security/rules" \
        --data-urlencode "element=<entry name='$rule_name'>
            <from><member>$from_zone</member></from> 
            <to><member>$to_zone</member></to> 
            <source><member>$source_ip</member></source> 
            <destination><member>$dest_ip</member></destination> 
            <service>$service_xml</service> 
            <application><member>$application</member></application> 
            <action>$action</action>
        </entry>"
    echo ""
}

change_rule_status() {
    local rule_name="$1"
    local action="$2"

    echo "Changing status of $rule_name to $action"
    curl -k -X POST "https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY" \
    --data-urlencode "xpath=/config/devices/entry/vsys/entry[@name='vsys1']/rulebase/security/rules" \
    --data-urlencode "/entry[@name=$rule_name]&element=<disabled>$action</disabled>"
    echo ""
}

create_service() {
    local protocol="$1"
    local port_number="$2"

    echo "Creating $service_name with $protocol port $port_number"
    curl -ks -X POST "https://$FIREWALL_IP/api/" \
        -d "type=config" \
        -d "action=set" \
        -d "key=$API_KEY" \
        -d "xpath=/config/shared/service" \
        --data-urlencode "element=<entry name='$protocol-$port_number'>
            <protocol>
                <$protocol>
                    <port>$port_number</port>
                </$protocol>
            </protocol>
        </entry>"
}

initial() {
    # All win out to dc
    # UDP: 53

    # DC out
    # UDP: 53

    # All win to CA
    # TCP: 135
    # UDP: 135

    # from ansible to all win 
    # TCP: 5985, 5986
    # from all outside to all win
    # TCP: 3389
    # UDP: 3389
    # From All Win to Wazuh and Graylog 
    # TCP: 1514, 1515, 80, 443

    # create_rule "test" "any" "any" "any" "any" "service-http" "any" "allow"
    # create_rule "Windows-to-DC-88" "any" "any" "any" "any" "88" "any" "allow"

    # All Win to DC
    # TCP: 88,135,389,445,464,636,3268
    # UDP: 53, 88,123,135,389,445,464,636
    create_service "tcp-88" "tcp" "88"
    create_service "tcp-135" "tcp" "135"
    create_service "tcp-389" "tcp" "389"
    create_service "tcp-445" "tcp" "445"
    create_service "tcp-464" "tcp" "464"
    create_service "tcp-636" "tcp" "636"
    create_service "tcp-3268" "tcp" "3268"
    create_service "udp-53" "udp" "53"
    create_service "udp-88" "udp" "88"
    create_service "udp-123" "udp" "123"
    create_service "udp-135" "udp" "135"
    create_service "udp-389" "udp" "389"
    create_service "udp-445" "udp" "445"
    create_service "udp-464" "udp" "464"
    create_service "udp-636" "udp" "636"
}

the_rules_to_end_all_rule() {
    create_rule "All-Win-To-DC" "DMZ" "Private" "DMZ" "any" "any" "tcp-88 tcp-135 tcp-389 tcp-445 tcp-464 tcp-636 tcp-3268" "any" "allow"
}

commit_changes() {
    echo "Committing changes"
    curl -k -X POST "https://$FIREWALL_IP/api/?type=commit&key=$API_KEY" \
	    --data-urlencode "cmd=<commit><description>blue4life</description></commit>"
    echo ""
}

if [ "$1" = "fix" ]; then
    fixes
    commit_changes
    exit
fi

initial
the_rules_to_end_all_rule
commit_changes