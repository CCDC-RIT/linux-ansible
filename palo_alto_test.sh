#!/bin/bash

fixes() {
    change_rule_status "test" "no"
}

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
}

change_rule_status() {
    local rule_name="$1"
    local action="$2"

    curl -k -X POST "https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY" \
    --data-urlencode "xpath=/config/devices/entry/vsys/entry[@name='vsys1']/rulebase/security/rules" \
    --data-urlencode "/entry[@name=$rule_name]&element=<disabled>$action</disabled>"
}

inital() {
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

    create_rule "test" "any" "any" "any" "any" "service-http" "any" "allow"
}

if [ "$1" -eq "init" ]; then
    initial()
elif [ "$1" -eq "fix" ]; then
    fixes()
elif [ $# -gt 1 || $# -eq 0]; then
    echo "only one parameter allowed"
    exit
else
    echo "invalid parameter, use 'init' or 'fix'"
    exit
fi

curl -k -X POST "https://$FIREWALL_IP/api/?type=commit&key=$API_KEY" \
	--data-urlencode "cmd=<commit><description>blue4life</description></commit>"

