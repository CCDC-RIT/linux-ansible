#!/bin/bash
: '
Name: StabVest
Author: Guac0

Provides a Security Operations Automated Response (SOAR)-analogue for service uptime.
TLDR:
    You put the stab vest on a critical service on a VM.
    It does absolutely nothing until the service gets shanked (disabled by red team).
    However, once the knife is in the wound (service is disabled), the vest says "nah bro" and removes the knife (gets the service back online).
    This is done by automatically detecting symptons of common service break methods and remediating them every 60 seconds (configurable).
    It does NOT do anything to prevent Red Team from gaining access to the system, and it does NOT kick them out when they attempt to mess with the service.

Supported breaks:
* Service was stopped
* Service was uninstalled
* Firewall rule blocking service
* Bad config file
* Bad content file
* Bad service binary
* Bad systemd config file
* Network interface down
* Some additional breaks are also detected but cannot be automatically remediated. Available information about these is logged to "log.txt" in the root of the backup directory (see below).

If you make changes to the contents of any of the backed up directories, you must load the changes into the StabVest backup database BEFORE THE NEXT CYCLE (default: 60 seconds)!!!
Example for reloading ALL configured backup directories for the enabled service:
    bash stabvest.sh backup
Example for config:
    zip -r "$backupdir/config/backup.zip" "$configdir"
Verbose example for config:
    zip -r "/usr/share/fonts/roboto-mono/apache2/config/backup.zip" "/etc/apache2"
Also make sure to timestomp it:
    touch -amt 1808281821 "/usr/share/fonts/roboto-mono/apache/config/backup.zip"
Full example if youre backing up the webroot for apache2:
    zip -r "/usr/share/fonts/roboto-mono/apache2/content/backup.zip" "/var/www/html"
    touch -amt 1808281821 "/usr/share/fonts/roboto-mono/apache/content/backup.zip"

TODO
* fix firewall
* timestomp dirs and/or recursive timestomp - partially done?
* test install service if missing
* test all the service integrity stuff
* test the backup mode
* backup /usr/share folders? benchmark the processing power needed...

Requirements:
* Run this script with root access
* This script file must be automatically executed every 60 seconds in some manner (cronjob/service). See the accompying setup script for suggestions.
* This script file should be set to 0755 or similar permissions, and it is recommended to timestomp it to an innocuous value.
* Only iptables is intended to be active, no other firewalls (as others are automatically disabled by this script)
* Each instance of this script can only be used on one service at a time. For additional instances, make a copy of this script and make sure to change the backup path, and have a separate form of persistance running this script (i.e. for two critical services, have two services running two copies of this script)
* Fill out the variables listed directly below this line. These determine the backup directory to use and the directories that should be included in the backup.
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
# /usr/share/apache2

# Nginx
declare -a ports=(80 443)
servicename="nginx"
packagename="nginx"
binarypath="/usr/sbin/nginx"
configdir="/etc/nginx"
contentdir="/var/www/html"
# /usr/lib/nginx
# /usr/share/nginx

# MySQL
#declare -a ports=(3306)
#servicename="mysql"
#packagename="mysql-server"
#binarypath="/usr/bin/msql"
#configdir="/etc/mysql"
#contentdir="/var/lib/mysql"

# PostGreSQL
#declare -a ports=(3306)
#servicename="mysql"
#packagename="mysql-server"
#binarypath="/usr/bin/msql"
#configdir="/etc/mysql"
#contentdir="/usr/local/pgsql/data" # or /var/lib/postgresql/[version]/data/



#####################################
############ BACKUP  MODE ###########
#####################################

# "Special" mode designed to be manually executed by operator to reset the backups.
# Use when you must make changes to the service (i.e. modifying the config file or updating to a newer version).
#   You may wish to temporarily stop the automatic backup script while you are making your changes, then run this special backup mode, then restart the automatic script.
# Archives any existing backup files and re-creates master backups based on current live files at run time.
# Note: re-archives ALL of the configured directories. Make sure they're all secured and that Red Team didn't pull a funny between you stopping and starting the automatic script!
# Intended to be executed using the same script file as the automated process uses so that all config and backup dirs are the same.
# Usage: execute the script with "backup" as the first argument

# TODO: what happens to file permissions?????

# Check if the first argument is "backup" to execute in backup mode
if [ "$1" -eq "backup" ]; then

    # Redirect all output to both terminal and log file
    touch $backupdir/log_manual.txt
    exec > >(tee -a $backupdir/log_manual.txt) 2>&1

    timestamp=$(date +%Y%m%d%H%M%S)
    echo ""
    echo "   Starting Service Mitigations Script - Backup Only Mode   "
    echo "Time: $timestamp"

    #####################################
    ######### MAKE THE BACKUPS ##########
    #####################################

    original_dirs=(
        "/lib/systemd/system/$servicename.service" #override?? /etc/systemd/system/apache2.service
        "$binarypath"
        "$configdir"
        "$contentdir"
    )
    backup_dirs=(
        "$backupdir/systemd"
        "$backupdir/binary"
        "$backupdir/config"
        "$backupdir/data"
    )
    is_single_files=(
        true
        true
        false
        false
    )

    # Ensure arrays are the same length
    if [ "${#original_dirs[@]}" -ne "${#backup_dirs[@]}" ]; then
        echo "Error: Mismatched backup and original directory arrays."
        exit 1
    fi

    for i in "${!original_dirs[@]}"; do
        original_dir="${original_dirs[$i]}"
        backup_dir="${backup_dirs[$i]}"
        is_single_file="${is_single_files[$i]}"
        
        echo ""
        echo "     Service Backup - $(basename "$backup_dir")     "
        echo ""

        # Create the backup directory if it doesn't exist (should NOT exist...)
        if [ ! -d "$backup_dir" ]; then
            sudo mkdir -p "$backup_dir"
            touch -amt $timestomp "$backup_dir"
        else
            # If backup already exists, "archive" them by appending the current time to their name.
            new_filename="$backup_dir-$timestamp"
            echo "Archiving existing backup files to $new_filename..."
            mv "$backup_dir" "$new_filename"
            touch -amt $timestomp "$new_filename"
        fi
        # First time setup: make a (hopefully good...) backup that future iterations will restore from.
        echo "Making a new master backup at $backup_dir/backup.zip..."
        zip -q -r "$backup_dir/backup.zip" "$original_dir"
        touch -amt $timestomp "$backup_dir/backup.zip"
    done

    # Do not perform regular script operations after all backups are finished.
    echo ""
    echo "Backup is finished to $backupdir. Script exiting..."
    touch -amt $timestomp "$backupdir/log_manual.txt"
    exit 0
fi



#####################################
#### REGULAR (AUTOMATED) MODE #######
#####################################

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
        sudo apt update && sudo apt install -y "$packagename" # TODO does APT UPDATE make it take too long?
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
######### Service Integrity #########
#####################################
original_dirs=(
    "/lib/systemd/system/$servicename.service" #override?? /etc/systemd/system/apache2.service
    "$binarypath"
    "$configdir"
    "$contentdir"
)
backup_dirs=(
    "$backupdir/systemd"
    "$backupdir/binary"
    "$backupdir/config"
    "$backupdir/data"
)
is_single_files=(
    true
    true
    false
    false
)

# Ensure arrays are the same length
if [ "${#original_dirs[@]}" -ne "${#backup_dirs[@]}" ]; then
    echo "Error: Mismatched backup and original directory arrays."
    exit 1
fi

for i in "${!original_dirs[@]}"; do
    original_dir="${original_dirs[$i]}"
    backup_dir="${backup_dirs[$i]}"
    is_single_file="${is_single_files[$i]}"
    
    echo ""
    echo "     Service Integrity - $(basename "$backup_dir")     "
    echo ""

    # Create the backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        sudo mkdir -p "$backup_dir"
        touch -amt $timestomp "$backup_dir"
    fi
    # Check if the original "good" backup file already exists.
    if [ -f "$backup_dir/backup.zip" ]; then
        # Check if the backup and the active config are different.
        # unzip backup into temp dir
        rm -rf "$backup_dir/tmp"
        mkdir -p "$backup_dir/tmp"
        touch -amt $timestomp "$backup_dir/tmp" # not really needed since it'll be yeeted asap...
        # absolute path funnies: will create "$backup_dir/tmp/etc/apache2" if doing apache2 config
        unzip -q "$backup_dir/backup.zip" -d "$backup_dir/tmp" # TODO what's the resulting timestamps on this? Not that it matters...

        if diff -qr "$original_dir" "$backup_dir/tmp$original_dir" &> /dev/null; then
            echo "Live files match the backup files. No action needed."
            rm -rf "$backup_dir/tmp"
        else
            echo "Live files differ from the backup. Restoring backup..."
            echo "Creating backup file of current (bad) files..."
            new_backup_file_path="$backup_dir/bad_backup-$timestamp.zip"
            zip -q -r "$new_backup_file_path" "$original_dir"
            touch -amt $timestomp "$new_backup_file_path"

            echo "Restoring known good configuration..."
            # Now that we have an extra backup, attempt to restore the "good" config.
            rm -rf "$original_dir"
            if [ "$is_single_file" = false ] ; then
                mkdir -p "$original_dir" # this breaks if its just one file, so only do it if its a dir
                # no need for timestomp. What would we even timestomp it to? TODO: does diff throw a fit if its different times?
            fi
            #absolute path funnies
            #unzip -q "$backup_dir/config/config.zip" -d "$original_dir"
            unzip -q "$backup_dir/config/config.zip" -d /  # TODO what's the resulting timestamps on this? Not that it matters...
            systemctl restart "$servicename"
            rm -rf "$backup_dir/tmp"
            echo "Service restarted and tmp files deleted."
            exit 0
        fi
    else
        # First time setup: make a (hopefully good...) backup that future iterations will restore from.
        echo "No backup file found, making a new master backup at $backup_dir/backup.zip..."
        zip -q -r "$backup_dir/backup.zip" "$original_dir"
        touch -amt $timestomp "$backup_dir/backup.zip"
    fi
done

echo ""
echo "   Service Mitigation Script Complete   "
touch -amt $timestomp "$backupdir/log.txt"