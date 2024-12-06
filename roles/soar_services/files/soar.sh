#!/bin/bash
: '
Author: Guac0

Provides a SOAR-analogue for service uptime.

Supported breaks:
* Stopped service
* Firewall rule blocking service
* Bad config file
* Bad content file
* Interface down

touch -amt 202312312359 "/usr/share/fonts/roboto-mono/apache/content/content.zip"

Requirements:
* Valid route to 8.8.8.8 (for network connectivity testing)
* ran with root access
* only iptables is active, no other firewall
* fill out the variables listed directly below this line
'

declare -a ports=(80 443) #array
servicename="apache2"
configdir="/var/apache2"
contentdir="/var/www/html"
backupdir="/usr/share/fonts/roboto-mono/$servicename"
timestomp=202312312359

# check for root and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit 1
fi

echo "   Starting Service Mitigations Script   "

#####################################
############ Network ################
#####################################
echo ""
echo "     Network     "
# Check that machine has internet connectivity
# Ping until timeout of 2 seconds or 1 successful packet
# auto determine the primary network interface. should work regardless of it is DOWN or UP. 
iface=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}' | head -n 1)

if [ -z "$iface" ]; then
    echo "No primary network interface found, skipping network connectivity tests."
else 
    if ping -w 2 -c 1 8.8.8.8 &> /dev/null; then
        echo "Network appears to be online (8.8.8.8 is reachable). Perhaps a firewall rule is blocking connection to the scoring IP?"
    else
        echo "Network appears to be offline. Attempting to bring the primary interface to an UP state..."
        ip link set "$iface" up
        if ping -w 2 -c 1 8.8.8.8 &> /dev/null; then
            echo "Network is still offline. Either the network config is broken, or there is a firewall/routing issue."
            exit 1
        else
            echo "Network mitigations successful, connectivity restored."
            exit 0
        fi
    fi
fi

#####################################
######### Service Status ############
#####################################
echo ""
echo "     Service Status     "
# Check if the service is running. If not running, start it.
if systemctl is-active --quiet "$servicename"; then
    echo "Service '$servicename' is already running."
else
    echo "Service '$servicename' is not running. Attempting to start it."
    systemctl start "$servicename"
    systemctl enable "$servicename"

    # Verify if the service started successfully
    if systemctl is-active --quiet "$servicename"; then
        echo "Service '$servicename' started successfully."
        exit 0
    else
        echo "Failed to start service '$servicename'."
        exit 1
    fi
fi

#####################################
############# Firewall ##############
#####################################
echo ""
echo "     Firewall     "
echo "Disabling unwanted firewall managers (ufw, firewalld)"
# iptables tables to check
declare -a tables=("filter" "nat" "mangle" "raw")

ufw disable
systemctl stop ufw
systemctl disable ufw

systemctl stop firewalld
systemctl disable firewalld

echo ""
echo "Backing up iptables rules..."
# # Backup Old Rules ( iptables -t mangle-restore < /etc/ip_rules_old ) [for forensics and etc]
timestamp=$(date +%Y%m%d%H%M%S)
iptables-save > "$backupdir/iptables_rules_backup-$timestamp"
touch -amt timestomp "$backupdir/iptables_rules_backup-$timestamp"
#ip6tables-save >/etc/ip6_rules_old

echo ""
# Loop through all provided ports
for port in "${ports[@]}"; do
    echo "Scanning and removing deny rules for port $port..."

    # Loop through all iptables tables
    for table in "${tables[@]}"; do
        echo "Scanning table: $table"

        # Find all DENY rules in the specified table for both inbound and outbound chains (INPUT and OUTPUT)
        deny_rules=$(iptables -t "$table" -L INPUT -v -n | grep -E "DPT:$port|SPT:$port")
        deny_rules_output=$(iptables -t "$table" -L OUTPUT -v -n | grep -E "DPT:$port|SPT:$port")

        # Combine both chains' results
        deny_rules="$deny_rules"$'\n'"$deny_rules_output"

        if [ -z "$deny_rules" ]; then
            echo "No DENY rules found for port $port in table $table."
        else
            # Loop through all matching rules and remove them
            while IFS= read -r rule; do
                # Extract the rule number
                rule_number=$(echo "$rule" | awk '{print $1}')
                echo "Removing rule number $rule_number for port $port in table $table..."
                iptables -t "$table" -D INPUT "$rule_number"
            done <<< "$deny_rules"
        fi
    done
done

#####################################
######### Service Config ############
#####################################
echo ""
echo "     Service Config     "
# Create the backup directory if it doesn't exist
if [ ! -d "$backupdir/config" ]; then
    sudo mkdir -p "$backupdir/config"
fi
# Check if the original "good" backup file already exists.
if [ -f "$backupdir/config/config.zip" ]; then
    # Check if the backup and the active config are different.
    # unzip backup into temp dir
    rm -rf "$backupdir/config/tmp"
    mkdir -p "$backupdir/config/tmp"
    unzip -q "$backupdir/config/config.zip" -d "$(dirname "$backupdir/config/tmp")"

    if diff -qr "$configdir" "$backupdir/config/tmp" &> /dev/null; then
        echo "Configuration matches the backup. No action needed."
    else
        echo "Configuration differs from the backup. Restoring backup..."
        echo "Creating backup file of current (bad) config dir..."
        timestamp=$(date +%Y%m%d%H%M%S)
        new_backup_file_path="$backupdir/config/config-$timestamp.zip"
        zip -r "$new_backup_file_path" "$configdir"
        touch -amt TIMESTAMP "$new_backup_file_path"

        echo "Restoring known good configuration..."
        # Now that we have an extra backup, attempt to restore the "good" config.
        rm -rf "$configdir"
        mkdir -p "$configdir"
        unzip -q "$backupdir/config/config.zip" -d "$(dirname "$configdir")"
        systemctl restart "$service"
        rm -rf "$backupdir/config/tmp"
    fi
else
    # First time setup: make a (hopefully good...) backup that future iterations will restore from.
    echo "No backup file found, making a new master backup..."
    zip -r "$backupdir/config/config.zip" "$configdir"
    touch -amt TIMESTAMP "$backupdir/config/config.zip"
fi

#####################################
######### Service Content ###########
#####################################
echo ""
echo "     Service Content     "
# Create the backup directory if it doesn't exist
if [ ! -d "$backupdir/content" ]; then
    sudo mkdir -p "$backupdir/content"
fi
# Check if the original "good" backup file already exists.
if [ -f "$backupdir/content/content.zip" ]; then
    # Check if the backup and the active content are different.
    # unzip backup into temp dir
    rm -rf "$backupdir/content/tmp"
    mkdir -p "$backupdir/content/tmp"
    unzip -q "$backupdir/content/content.zip" -d "$(dirname "$backupdir/content/tmp")"

    if diff -qr "$contentdir" "$backupdir/content/tmp" &> /dev/null; then
        echo "Content matches the backup. No action needed."
    else
        echo "Content differs from the backup. Restoring backup..."
        echo "Creating backup file of current (bad) content dir..."
        timestamp=$(date +%Y%m%d%H%M%S)
        new_backup_file_path="$backupdir/content/content-$timestamp.zip"
        zip -r "$new_backup_file_path" "$contentdir"
        touch -amt TIMESTAMP "$backupdir/content/content-$timestamp.zip"

        echo "Restoring known good content..."
        # Now that we have an extra backup, attempt to restore the "good" content.
        rm -rf "$contentdir"
        mkdir -p "$contentdir"
        unzip -q "$backupdir/content/content.zip" -d "$(dirname "$contentdir")"
        systemctl restart "$service"
        rm -rf "$backupdir/content/tmp"
    fi
else
    # First time setup: make a (hopefully good...) backup that future iterations will restore from.
    echo "No backup file found, making a new master backup..."
    zip -r "$backupdir/content/content.zip" "$contentdir"
    touch -amt TIMESTAMP "$backupdir/content/content.zip"
fi