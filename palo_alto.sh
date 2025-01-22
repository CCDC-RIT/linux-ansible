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

RAW=$(curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST https://$FIREWALL_IP/api/?type=keygen -d "user=$USER&password=$PASSWORD")
API_KEY=$(awk -v str="$RAW" 'BEGIN { split(str, parts, "<key>|</key>"); print parts[2] }')

create_rule() {
    local rule_name="$1"
    local from_zone="$2"
    local to_zone="$3"
    local source_ip="$4"
    local dest_ip="$5"
    local service="$6"
    local application="$7"
    local action="$8"
    
    echo "Creating rule $rule_name"
    curl -k -X POST "https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY" \
        --data-urlencode "xpath=/config/devices/entry/vsys/entry[@name='vsys1']/rulebase/security/rules" \
        --data-urlencode "element=<entry name='$rule_name'>
            <from><member>$from_zone</member></from> 
            <to><member>$to_zone</member></to> 
            <source><member>$source_ip</member></source> 
            <destination><member>$dest_ip</member></destination> 
            <service><member>$service</member></service> 
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
    local service_name="$1"
    local protocol="$2"
    local port_number="$3"

    echo "Creating $service_name with $protocol port $port_number"
    curl -ks -X POST "https://$FIREWALL_IP/api/" \
        -d "type=config&action=set&key=$API_KEY" \
        --data-urlencode "xpath=/config/shared/service" \
        --data-urlencode "element=<request>
            <set><config><shared><service>
            <entry name=$service_name>
            <protocol>
            <$protocol><port>$port_number</port></$protocol>
            </protocol></entry></service></shared></config></set></request>"
}

initial() {
    # All Win to DC
    # TCP: 88,135,389,445,464,636,3268
    # UDP: 53, 88,123,135,389,445,464,636

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
    create_service "tcp-88" "tcp" "88"
}

if [ "$1" = "init" ]; then
    echo "Running initial configuration"
    initial
elif [ "$1" = "fix" ]; then
    echo "Running fixes"
    fixes
elif [ $# -gt 1 -o $# -eq 0 ]; then
    echo "Only one parameter allowed!"
    exit
else
    echo "Invalid parameter, use 'init' or 'fix'"
    exit
fi

echo "Committing changes"
curl -k -X POST "https://$FIREWALL_IP/api/?type=commit&key=$API_KEY" \
	--data-urlencode "cmd=<commit><description>blue4life</description></commit>"
echo ""