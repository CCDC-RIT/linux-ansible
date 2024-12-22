#!/bin/bash
: '
Author: Guac0

Provides a SOAR-analogue for service uptime.
If a basic break is detected (network interface problems, service stopped), script will fix it and exit before checking service config/firewall.
Firewall and service config/content fixes do not stop the script; all fixes will be attempted.

Supported breaks:
* Stopped service
* Firewall rule blocking service
* Bad config file
* Bad content file
* Bad service binary
* Interface down

If you make changes to the contents of $configdir or $contentdir, you must load the changes into the SOAR script BEFORE THE NEXT CYCLE (default: 60 seconds)!!!
Example for config:
zip -r "$backupdir/config/config.zip" "$configdir"
Verbose example for config:
zip -r "/usr/share/fonts/roboto-mono/apache2/config/config.zip" "/etc/apache2"
Also make sure to timestomp it:
touch -amt 1808281821 "/usr/share/fonts/roboto-mono/apache/config/config.zip"

Example for content:
zip -r "/usr/share/fonts/roboto-mono/apache2/content/content.zip" "/var/www/html"
touch -amt 1808281821 "/usr/share/fonts/roboto-mono/apache/content/content.zip"

TODO
* fix firewall
* timestomp dirs and/or recursive timestomp
* test install service if missing
* test backup binary
* backup service file
* save backup dir path as a shell variable to make it easier for blue team?

Requirements:
* ran with root access
* only iptables is intended to be active, no other firewall (as others are automatically disabled by this)
* Each instance of this script can only be used on one service at a time. For additional instances, make sure to change the backup path and have a separate form of persistance running this SOAR script (i.e. for two critical services, have two services running two copies of this script)
* fill out the variables listed directly below this line
'

# generic variables
backupdir="/usr/share/fonts/roboto-mono/$servicename"
timestomp=1808281821

# Apache2
declare -a ports=(80 443)
servicename="apache2"
packagename="apache2"
binarypath="/usr/sbin/apache2"
configdir="/etc/apache2"
contentdir="/var/www/html"

# MySQL
#declare -a ports=(3306)
#servicename="mysql"
#packagename="mysql-server"
#binarypath="/usr/bin/msql"
#configdir="/etc/mysql"
#contentdir="/var/lib/mysql"



# check for root and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit 1
fi

# Redirect all output to both terminal and log file
touch $backupdir/log.txt
exec > >(tee -a $backupdir/log.txt) 2>&1

timestamp=$(date +%Y%m%d%H%M%S)
echo ""
echo "   Starting Service Mitigations Script   "
echo "Time: $timestamp"

#####################################
############ Network ################
#####################################
echo ""
echo "     Network     "
echo ""
# Check that machine has internet connectivity
# Ping until timeout of 2 seconds or 1 successful packet
# auto determine the primary network interface. should work regardless of it is DOWN or UP. 
iface=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}' | head -n 1)

if [ -z "$iface" ]; then
    echo "No primary network interface found, skipping network connectivity tests."
else
    # Check if the interface is up
    if ip link show "$iface" | grep -q "state UP"; then
        echo "Interface $iface is up."
    else
        echo "Interface $iface is down, setting it to up."
        ip link set "$iface" up
        exit 0
    fi

    # Check if the interface has an IP address assigned
    if ip addr show "$iface" | grep -q "inet "; then
        echo "Interface $iface has an IP address assigned."
    else
        echo "Interface $iface does not have an IP address. Operator must manually fix this error."
        exit 1
    fi

    # Check if the interface is part of the correct routing table (default gateway exists)
    if ip route show | grep -q "$iface"; then
        echo "Interface $iface is part of the routing table."
    else
        echo "Interface $iface is not part of the routing table. Does it have a valid route to the default gateway and/or is one configured? Operator must manually fix this error."
        exit 1
    fi

    : '
    if ping -w 2 -c 1 8.8.8.8 &> /dev/null; then
        echo "Network appears to be online (8.8.8.8 is reachable). Perhaps a firewall rule is blocking connection to the scoring IP?"
    else
        echo "Network appears to be offline. Attempting to bring the primary interface to an UP state..."
        ip link set "$iface" up
        if ping -w 2 -c 1 8.8.8.8 &> /dev/null; then
            echo "Network is still offline. Either the network config is broken, or there is a firewall/routing issue.  Operator must manually fix this error."
            exit 1
        else
            echo "Network mitigations successful, connectivity restored."
            exit 0
        fi
    fi
    '
fi

#####################################
######### Service Install ###########
#####################################
echo ""
echo "     Service Install Status     "
echo ""
# Check service status. If non-zero, it's not found.
if ! systemctl status "$servicename" &> /dev/null; then
    echo "Service $servicename is not installed or unavailable. Reinstalling $packagename..."

    # Reinstall the package using apt, yum, or dnf
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y "$packagename"
    elif command -v yum &> /dev/null; then
        sudo yum install -y "$packagename"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$packagename"
    else
        echo "Package manager not supported. Install $packagename manually. Operator must manually fix this error."
        exit 1
    fi

    # Start and enable the service
    sudo systemctl start "$servicename"
    sudo systemctl enable "$servicename"
    echo "Service $servicename reinstalled and started."
    exit 0
else
    echo "Service $servicename is already installed and active."
fi

#####################################
######### Service Status ############
#####################################
echo ""
echo "     Service Status     "
echo ""
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
        echo "Failed to start service '$servicename'. Operator must manually fix this error."
        exit 1
    fi
fi

#####################################
############# Firewall ##############
#####################################
#echo ""
#echo "     Firewall     "
#echo ""
#echo "Disabling unwanted firewall managers (ufw, firewalld)"
## iptables tables to check
#declare -a tables=("filter" "nat" "mangle" "raw")
#
#ufw disable
#systemctl stop ufw
#systemctl disable ufw
#
#systemctl stop firewalld
#systemctl disable firewalld
#
#echo ""
#echo "Backing up iptables rules..."
## # Backup Old Rules ( iptables -t mangle-restore < /etc/ip_rules_old ) [for forensics and etc]
#iptables-save > "$backupdir/iptables_rules_backup-$timestamp"
#touch -amt $timestomp "$backupdir/iptables_rules_backup-$timestamp"
##ip6tables-save >/etc/ip6_rules_old
#
## Loop through all provided ports
#for port in "${ports[@]}"; do
#    # Loop through all iptables tables
#    for table in "${tables[@]}"; do
#        echo ""
#        echo "Scanning port $port on table $table..."
#
#        # Check and remove rules in INPUT chain
#        while :; do
#            deny_rules=$(iptables -t "$table" -L INPUT -v -n --line-numbers | grep -E "DPT:$port|SPT:$port")
#            if [ -z "$deny_rules" ]; then
#                break
#            fi
#            # Extract and remove the first rule
#            rule_number=$(echo "$deny_rules" | awk 'NR==1 {print $1}')
#            echo "Removing INPUT rule number $rule_number for port $port in table $table..."
#            iptables -t "$table" -D INPUT "$rule_number"
#        done
#
#        # Check and remove rules in OUTPUT chain
#        while :; do
#            deny_rules=$(iptables -t "$table" -L OUTPUT -v -n --line-numbers | grep -E "DPT:$port|SPT:$port")
#            if [ -z "$deny_rules" ]; then
#                break
#            fi
#            # Extract and remove the first rule
#            rule_number=$(echo "$deny_rules" | awk 'NR==1 {print $1}')
#            echo "Removing OUTPUT rule number $rule_number for port $port in table $table..."
#            iptables -t "$table" -D OUTPUT "$rule_number"
#        done
#    done
#done

#####################################
######### Service Binary ############
#####################################
echo ""
echo "     Service Binary     "
echo ""
# Create the backup directory if it doesn't exist
if [ ! -d "$backupdir" ]; then
    sudo mkdir -p "$backupdir/binary"
fi
# Check if the original "good" backup file already exists.
if [ -f "$backupdir/binary/binary.zip" ]; then
    # Check if the backup and the active binary are different.
    # unzip backup into temp dir
    rm -rf "$backupdir/binary/tmp"
    mkdir -p "$backupdir/binary/tmp"
    # absolute path funnies: will create "$backupdir/binary/tmp/$binarypath"
    unzip -q "$backupdir/binary/binary.zip" -d "$backupdir/binary/tmp"

    if diff -qr "$binarypath" "$backupdir/binary/tmp$binarypath" &> /dev/null; then
        echo "Binary matches the backup. No action needed."
    else
        echo "Binary differs from the backup. Restoring backup..."
        echo "Creating backup file of current (bad) binary dir..."
        new_backup_file_path="$backupdir/binary/binary-$timestamp.zip"
        zip -q -r "$new_backup_file_path" "$binarypath"
        touch -amt $timestomp "$new_backup_file_path"

        echo "Restoring known good binary..."
        # Now that we have an extra backup, attempt to restore the "good" binary.
        rm -rf "$binarypath"
        mkdir -p "$binarypath"
        #absolute path funnies
        #unzip -q "$backupdir/binary/binary.zip" -d "$binarypath"
        unzip -q "$backupdir/binary/binary.zip" -d /
        systemctl restart "$servicename"
        rm -rf "$backupdir/binary/tmp"
        echo "Service restarted and tmp files deleted."
        exit 0
    fi
else
    # First time setup: make a (hopefully good...) backup that future iterations will restore from.
    echo "No backup file found, making a new master backup..."
    # Even though we just have a single file, we still zip it so that we can hide the file name
    zip -q -r "$backupdir/binary/binary.zip" "$binarypath"
    touch -amt $timestomp "$backupdir/binary/binary.zip"
fi

#####################################
######### Service Config ############
#####################################
echo ""
echo "     Service Config     "
echo ""
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
    # absolute path funnies: will create "$backupdir/config/tmp/etc/apache2"
    unzip -q "$backupdir/config/config.zip" -d "$backupdir/config/tmp"

    if diff -qr "$configdir" "$backupdir/config/tmp$configdir" &> /dev/null; then
        echo "Configuration matches the backup. No action needed."
    else
        echo "Configuration differs from the backup. Restoring backup..."
        echo "Creating backup file of current (bad) config dir..."
        new_backup_file_path="$backupdir/config/config-$timestamp.zip"
        zip -q -r "$new_backup_file_path" "$configdir"
        touch -amt $timestomp "$new_backup_file_path"

        echo "Restoring known good configuration..."
        # Now that we have an extra backup, attempt to restore the "good" config.
        rm -rf "$configdir"
        mkdir -p "$configdir"
        #absolute path funnies
        #unzip -q "$backupdir/config/config.zip" -d "$configdir"
        unzip -q "$backupdir/config/config.zip" -d /
        systemctl restart "$servicename"
        rm -rf "$backupdir/config/tmp"
        echo "Service restarted and tmp files deleted."
        exit 0
    fi
else
    # First time setup: make a (hopefully good...) backup that future iterations will restore from.
    echo "No backup file found, making a new master backup..."
    zip -q -r "$backupdir/config/config.zip" "$configdir"
    touch -amt $timestomp "$backupdir/config/config.zip"
fi

#####################################
######### Service Content ###########
#####################################
echo ""
echo "     Service Content     "
echo ""
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
    # absolute path funnies: will create "$backupdir/content/tmp/var/www/html/blah blah blah"
    unzip -q "$backupdir/content/content.zip" -d "$backupdir/content/tmp"

    if diff -qr "$contentdir" "$backupdir/content/tmp$contentdir" &> /dev/null; then
        echo "Content matches the backup. No action needed."
    else
        echo "Content differs from the backup. Restoring backup..."
        echo "Creating backup file of current (bad) content dir..."
        new_backup_file_path="$backupdir/content/content-$timestamp.zip"
        zip -q -r "$new_backup_file_path" "$contentdir"
        touch -amt $timestomp "$backupdir/content/content-$timestamp.zip"

        echo "Restoring known good content..."
        # Now that we have an extra backup, attempt to restore the "good" content.
        rm -rf "$contentdir"
        mkdir -p "$contentdir"
        #unzip -q "$backupdir/content/content.zip" -d "$backupdir/content/tmp/"
        unzip -q "$backupdir/content/content.zip" -d /
        systemctl restart "$servicename"
        rm -rf "$backupdir/content/tmp"
        echo "Service restarted and tmp files deleted."
        exit 0
    fi
else
    # First time setup: make a (hopefully good...) backup that future iterations will restore from.
    echo "No backup file found, making a new master backup..."
    zip -q -r "$backupdir/content/content.zip" "$contentdir"
    touch -amt $timestomp "$backupdir/content/content.zip"
fi

echo ""
echo "   Service Mitigation Script Complete   "
touch -amt $timestomp "$backupdir/content/log.txt"