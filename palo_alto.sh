#!/bin/bash

fixes() {
    # For disabling rules, yes -> disabled and no -> enabled
    change_rule_status "intrazone-default" "yes"
    change_rule_status "interzone-default" "yes"
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
echo ""

if [ -z "$API_KEY" ]; then
    echo "Failed to retrieve API key"
    exit
fi

echo "Overriding template for services..."
sleep 1
curl -ks -X POST "https://$FIREWALL_IP/api/" \
    -d "type=config&action=override&key=$API_KEY" \
    --data-urlencode "xpath=/config/shared/service" \
    --data-urlencode "element=<override></override>"
echo ""

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

    if [ "$action" = "yes" ]; then
        echo "Disabling $rule_name"
    else
        echo "Enabling $rule_name"
    fi

    curl -k -X POST "https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY" \
    --data-urlencode "xpath=/config/devices/entry/vsys/entry[@name='vsys1']/rulebase/security/rules/entry[@name='$rule_name']" \
    --data-urlencode "element=<disabled>$action</disabled>"
    echo ""
}

create_service() {
    local protocol="$1"
    local port_number="$2"

    echo "Creating service $protocol-$port_number"
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
    echo ""
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
    create_service "tcp" "88"
    create_service "tcp" "135"
    create_service "tcp" "389"
    create_service "tcp" "445"
    create_service "tcp" "464"
    create_service "tcp" "636"
    create_service "tcp" "3268"

    create_service "udp" "53"
    create_service "udp" "88"
    create_service "udp" "123"
    create_service "udp" "135"
    create_service "udp" "389"
    create_service "udp" "445"
    create_service "udp" "464"
    create_service "udp" "636"
}

the_rules_to_end_all_rule() {
    # All Win to DC
    # TCP: 88,135,389,445,464,636,3268
    # UDP: 53,88,123,135,389,445,464,636
    create_rule "All-Win-DMZ-To-DC-Private-TCP" "DMZ" "Private" "any" "any" "tcp-88 tcp-135 tcp-389 tcp-445 tcp-464 tcp-636 tcp-3268" "any" "allow"
    create_rule "All-Win-DMZ-To-DC-Private-UDP" "DMZ" "Private" "any" "any" "udp-53 udp-88 udp-123 udp-135 udp-389 udp-445 udp-464 udp-636" "any" "allow"
    create_rule "All-Win-Private-To-DC-DMZ-TCP" "Private" "DMZ" "any" "any" "tcp-88 tcp-135 tcp-389 tcp-445 tcp-464 tcp-636 tcp-3268" "any" "allow"
    create_rule "All-Win-Private-To-DC-DMZ-UDP" "Private" "DMZ" "any" "any" "udp-53 udp-88 udp-123 udp-135 udp-389 udp-445 udp-464 udp-636" "any" "allow"
}

commit_changes() {
    echo "Committing changes"
    curl -k -X POST "https://$FIREWALL_IP/api/?type=commit&key=$API_KEY" \
	    --data-urlencode "cmd=<commit><description>blue4life</description></commit>"
    echo ""
}

backup_changes() {
    local backup_dir="$HOME/asa/osa"
    local backup_file="$backup_dir/running-config.xml"
    local old_backup="$backup_dir/running-config-old.xml"
    local older_backup="$backup_dir/running-config-old.xml~"

    echo "Removing old backups locally..."
    rm -f "$older_backup" "$old_backup"

    echo "Rotating backups..."
    if [ -f "$old_backup" ]; then
        mv "$old_backup" "$older_backup"
    fi
    if [ -f "$backup_file" ]; then
        mv "$backup_file" "$old_backup"
    fi

    echo "Backing up configuration"
    sleep 1
    curl -kG "https://$FIREWALL_IP/api/?type=export&category=configuration&key=$API_KEY" > $backup_file
    echo ""

    echo "Removing old backups from Palo Alto..."
    for file in "running-config.xml" "running-config-old.xml" "running-config-old.xml~"; do
        echo "Deleting $file from firewall..."
        curl -k -X GET "https://$FIREWALL_IP/api/?type=op&cmd=<delete><config><saved>$file</saved></config></delete>&key=$API_KEY"
    done
    echo ""

    echo "Uploading new backups to Palo Alto..."
    for file in "$backup_file" "$old_backup" "$older_backup"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "Uploading $filename..."
            curl -k -F key="$API_KEY" -F file=@"$file" "https://$FIREWALL_IP/api/?type=import&category=configuration"
        fi
    done
    echo ""
}

revert_changes() {
    local iteration="$1"
    local backup_file_path="$HOME/asa/osa/running-config"

    case "$iteration" in
        1)  backup_file_path+=".xml" ;;
        2)  backup_file_path+="-old.xml" ;;
        3)  backup_file_path+="-old.xml~" ;;
        *)  backup_file_path+=".xml" ;;  # Default case
    esac

    local backup_file_name=(basename "$backup_file_path")

    echo "Reverting changes from backup iteration $iteration"
    curl -k -F key=$API_KEY -F file=@$backup_file_path "https://$FIREWALL_IP/api/?type=import&category=configuration"
    curl -k -X GET "https://$FIREWALL_IP/api/?type=op&cmd=<load><config><from>$backup_file_name</from></config></load>&key=$API_KEY"
    echo ""
}

menu() {
    local CHOICE=""
    
    while true; do
        read -p "Are you (i)nitializing, (f)ixing, (b)acking up, or (r)everting? " CHOICE
        echo ""

        case "$CHOICE" in
            "f")
                fixes
                break
                ;;
            "i")
                initial
                the_rules_to_end_all_rule
                break
                ;;
            "b")
                backup_changes
                break
                ;;
            "r")
                local ITERATION=""
                read -p "Enter backup iteration number (1 is latest): " ITERATION
                echo ""
                revert_changes "$ITERATION"
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    done
}

commit_changes
exit