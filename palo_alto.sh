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
    create_service "tcp" "22"
    create_service "tcp" "80"
    create_service "tcp" "88"
    create_service "tcp" "135"
    create_service "tcp" "389"
    create_service "tcp" "443"
    create_service "tcp" "445"
    create_service "tcp" "464"
    create_service "tcp" "636"
    create_service "tcp" "1514"
    create_service "tcp" "1515"
    create_service "tcp" "1516"
    create_service "tcp" "3268"
    create_service "tcp" "3389"
    create_service "tcp" "5985"
    create_service "tcp" "5986"
    create_service "tcp" "8086"
    create_service "tcp" "8088"
    create_service "tcp" "9000"
    create_service "tcp" "9200"
    create_service "tcp" "9300"
    create_service "tcp" "9300-9400"
    create_service "tcp" "27017"
    create_service "tcp" "55000"

    create_service "udp" "53"
    create_service "udp" "88"
    create_service "udp" "123"
    create_service "udp" "135"
    create_service "udp" "389"
    create_service "udp" "445"
    create_service "udp" "464"
    create_service "udp" "636"
    create_service "udp" "3389"
}

the_rules_to_end_all_rule() {
    create_rule "All-Win-To-DC-TCP" "any" "any" "any" "any" "tcp-88 tcp-135 tcp-389 tcp-445 tcp-464 tcp-636 tcp-3268" "any" "allow"
    create_rule "All-Win-To-DC-UDP" "any" "any" "any" "any" "udp-53 udp-88 udp-123 udp-135 udp-389 udp-445 udp-464 udp-636" "any" "allow"
    create_rule "All-To-Ansible-TCP" "any" "any" "any" "any" "tcp-5985 tcp-5986" "any" "allow"
    create_rule "All-To-RDP-TCP" "any" "any" "any" "any" "tcp-3389" "any" "allow"
    create_rule "All-To-RDP-UDP" "any" "any" "any" "any" "udp-3389" "any" "allow"
    create_rule "All-To-Web-TCP" "any" "any" "any" "any" "tcp-80 tcp-443" "any" "allow"
    create_rule "All-To-SSH-TCP" "any" "any" "any" "any" "tcp-22" "any" "allow"
    create_rule "All-To-Graylog-TCP" "any" "any" "any" "any" "tcp-9000 tcp-9200 tcp-9300 tcp-27017" "any" "allow"
    create_rule "All-To-Wazuh-TCP" "any" "any" "any" "any" "tcp-443 tcp-1514 tcp-1515 tcp-1516 tcp-9200 tcp-9300-9400 tcp-55000" "any" "allow"
    create_rule "All-To-InfluxDB-TCP" "any" "any" "any" "any" "tcp-8086 tcp-8088" "any" "allow"
}

commit_changes() {
    echo "Committing changes"
    curl -k -X POST "https://$FIREWALL_IP/api/?type=commit&key=$API_KEY" \
	    --data-urlencode "cmd=<commit><description>blue4life</description></commit>"
    echo ""
}

backup_changes() {
    local backup_dir="$HOME/asa/osa"
    local backup_file="$backup_dir/running-config-$(date +%d_%H-%M).xml"

    echo "Backing up configuration"
    sleep 1
    curl -kG "https://$FIREWALL_IP/api/?type=export&category=configuration&key=$API_KEY" > "$backup_file"
    echo ""

    echo "Uploading backup $(basename "$backup_file")..."
    curl -k -F key="$API_KEY" -F file=@"$backup_file" "https://$FIREWALL_IP/api/?type=import&category=configuration"
    echo ""
}

revert_changes() {
    local backup_dir="$HOME/asa/osa"
    local backups
    local index
    local selected_backup

    backups=($(ls -t "$backup_dir"/*.xml 2>/dev/null))

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "Error: No backup files found in $backup_dir"
        return 1
    fi

    echo "Available Palo Alto Backup Files:"
    for i in "${!backups[@]}"; do
        echo "$((i + 1)). ${backups[$i]}"
    done

    while true; do
        read -p "Enter the number of the backup to restore (1-${#backups[@]}): " index

        if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= ${#backups[@]} )); then
            selected_backup="${backups[$index-1]}"
            echo "Selected backup: $selected_backup"
            break
        else
            echo "Invalid input. Please enter a number between 1 and ${#backups[@]}."
        fi
    done

    echo "Restoring configuration..."
    curl -k -X POST "https://${FIREWALL_IP}/api/?type=import&category=configuration&key=${API_KEY}" \
     --form "file=@${selected_backup}"
    echo ""

    selected_backup=$(basename $selected_backup)

    echo "Loading configuration..."
    curl -k -X GET "https://${FIREWALL_IP}/api/?type=op&cmd=<load><config><from>${selected_backup}</from></config></load>&key=${API_KEY}"
    echo ""
}

harden() {
    echo "Disabling insecure access protocols"
    curl -k -X GET "https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY" \
        --data-urlencode "xpath=/config/devices/entry[@name='localhost.localdomain']/deviceconfig/system/service" \
        --data-urlencode "element=<disable-http>yes</disable-http><disable-snmp>yes</disable-snmp><disable-telnet>yes</disable-telnet>"
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
                # initial
                # the_rules_to_end_all_rule
                harden
                break
                ;;
            "b")
                backup_changes
                break
                ;;
            "r")
                revert_changes
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    done
}

menu
commit_changes
exit