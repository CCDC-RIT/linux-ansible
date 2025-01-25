#!/bin/bash
: '
Name: StabVest
Author: Guac0

Provides a Security Orchestration, Automations, Response (SOAR)-analogue for service uptime.
TLDR:
    You put the stab vest on a critical service on a VM.
    It does absolutely nothing until the service gets shanked (disabled by red team).
    The vest stops the knife from penetrating and injuring the person, but the wearer still feels the impact and needs to take a minute to get their breath back (script fixes downed service during its next activation cycle).
    This is done by automatically detecting symptoms of common service break methods and remediating them every 60 seconds (configurable).
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

Log File Notes
* Exists as "log.txt" in the root of $backupdir
* Lines padded with "=" are section breaks
* Lines padded with "!" are misc important information alerts, like paths of new backups
* Lines padded with "+" are successful remediations
* Lines padded with "-" are unsuccessful remediations that need manual fixing by the operator

If you make changes to the contents of any of the backed up directories, you must load the changes into the StabVest backup database BEFORE THE NEXT CYCLE (default: 60 seconds)!!!
Example for reloading ALL configured backup directories for the enabled service:
    bash stabvest.sh backup
Example for config:
    zip -r "$backupdir/config/backup.zip" "$configdir"
Verbose example for config:
    zip -r "/usr/share/fonts/roboto-mono/apache2/config/backup.zip" "/etc/apache2"
Also make sure to timestomp it:
    touch -t 1808281821 "/usr/share/fonts/roboto-mono/apache/config/backup.zip"
Full example if youre backing up the webroot for apache2:
    zip -r "/usr/share/fonts/roboto-mono/apache2/content/backup.zip" "/var/www/html"
    touch -t 1808281821 "/usr/share/fonts/roboto-mono/apache/content/backup.zip"

TODO
* benchmark used cpu time and compare to frequency
* test on rhel
* get drew to break it again

Requirements:
* Run this script with root access
* This script file must be automatically executed every 60 seconds in some manner (cronjob/service). See the accompying setup script for suggestions.
* This script file should be set to 0750 or similar permissions, and it is recommended to timestomp it to an innocuous value.
* Only iptables is intended to be active, no other firewalls (as others are automatically disabled by this script)
* Each instance of this script can only be used on one service at a time. For additional instances, make a copy of this script and make sure to change the backup path, and have a separate form of persistance running this script (i.e. for two critical services, have two services running two copies of this script)
* Fill out the variables listed directly below this line. These determine the backup directory to use and the directories that should be included in the backup.
'

############### Apache2 ###############
#declare -a ports=( 80 443 )
########## Ubuntu ##########
#servicename="apache2"
#packagename="apache2"
#binarypath="/usr/sbin/apache2"
#configdir="/etc/apache2"
#contentdir="/var/www/html"
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
########## RHEL ############
#servicename="httpd"
#packagename="httpd"
#binarypath="/usr/sbin/httpd"
#configdir="/etc/httpd/"
#contentdir="/var/www/html"
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
# /usr/share/apache2

############### Nginx ###############
#declare -a ports=( 80 443 ) # use numbers only, no named alias like "http"
########## Ubuntu ##########
#servicename="nginx"
#packagename="nginx"
#binarypath="/usr/sbin/nginx"
#configdir="/etc/nginx"
#contentdir="/var/www/html"
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
########## RHEL ############
#servicename="nginx"
#packagename="nginx"
#binarypath="/usr/sbin/nginx"
#configdir="/etc/nginx"
#contentdir="/usr/share/nginx/html"
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
# /usr/lib/nginx
# /usr/share/nginx

############### MySQL ###############
#declare -a ports=( 3306 )
########## Ubuntu ##########
#servicename="mysql"
#packagename="mysql-server"
#binarypath="/usr/bin/msql"
#configdir="/etc/mysql"
#contentdir="" # it's /var/lib/mysql, but data may change during comp so don't back it up... probably.
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
########## RHEL ############
#servicename="mysqld"
#packagename="mysql-server"
#binarypath="/usr/libexec/mysqld"
#configdir="/etc/my.cnf"
#contentdir="" # it's /var/lib/mysql, but data may change during comp so don't back it up... probably.
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""

############### PostGreSQL ###############
#declare -a ports=( 5432 )
########## Ubuntu ##########
#servicename="postgresql"
#packagename="postgresql"
#binarypath="/usr/lib/postgresql/<version>/bin/"
#configdir="/etc/postgresql/"
#contentdir="/var/lib/postgresql/" # or /var/lib/postgresql/[version]/data/
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
########## RHEL ############
#servicename="postgresql"
#packagename="postgresql-server"
#binarypath="/usr/pgsql-<version>/bin/"
#configdir="/var/lib/pgsql/"
#contentdir="/var/lib/postgresql/" # or /var/lib/postgresql/[version]/data/
#miscdir1="" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""

############### InfluxDB ###############
#declare -a ports=( 8086 8088 )
########## Ubuntu ##########
#servicename="influxdb"
#packagename="influxdb2"
#binarypath="/usr/bin/influxd"
#configdir="/etc/influxdb"
#contentdir="" # content is stored at the "dir=XYZ" line in the config file (/var/lib/influxdb). however, we dont want to back up and restore it as it may change.
#miscdir1="/etc/default/influxdb2" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""
########## RHEL ############
#servicename="influxdb"
#packagename="influxdb2"
#binarypath="/usr/bin/influxd"
#configdir="/etc/influxdb"
#contentdir="" # content is stored at the "dir=XYZ" line in the config file (/var/lib/influxdb). however, we dont want to back up and restore it as it may change.
#miscdir1="/etc/default/influxdb2" # Optional bonus files/dirs to secure. Leave blank if none.
#miscdir2=""
#miscdir3=""

# TODO docker??



# generic variables regardless of the service to back up
backupdir="/usr/share/obvioustmp/$servicename"
timestomp_start_year=2000
timestomp_end_year=2005



# check for root and #exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    #exit 1
fi

# Make the backup dir if not found
if [ ! -d "$backupdir" ]; then
    mkdir -p "$backupdir"
fi

# note that restored files retain the perms and timestamp of their original file



#####################################
########## PADDING FUNC #############
#####################################
# Used for prettier output for the most important alerts/section breaks
pad_string() {
    local input="$1"
    local char="$2"
    #local total_length=$3
    local total_length=75
    local input_length=${#input}
    local padding_length=$(( (total_length - input_length) / 2 ))
    
    # Generate padding
    local padding=$(printf '%*s' "$padding_length" '' | tr ' ' "$char")

    # Check if the string needs an extra dash on one side
    if (( (input_length + 2 * padding_length) < total_length )); then
        echo "${padding}${char}${input}${char}${padding}"
    else
        echo "${padding}${input}${padding}"
    fi
}



#####################################
########## TIMESTOMP FUNC ###########
#####################################
# Function to generate a random time for timestomp between two given years
generate_random_date() {
    # Generate a random year between given values
    local year=$(printf "%02d" $(( RANDOM % ($timestomp_end_year - $timestomp_start_year + 1) + $timestomp_start_year )))
    local year_short=$(printf "%02d" $(( year % 100 )))  # Get last two digits for YY
    local century=$(printf "%02d" $(( year / 100 )))    # Get first two digits for CC
    # Generate a random month (01 to 12)
    local month=$(printf "%02d" $(( RANDOM % 12 + 1 ))) 
    # Generate a random day (01 to 28)
    local day=$(printf "%02d" $(( RANDOM % 28 + 1 ))) 
    # Generate a random hour (00 to 23), minute (00 to 59), and second (00 to 59)
    local hour=$(printf "%02d" $(( RANDOM % 24 )))
    local minute=$(printf "%02d" $(( RANDOM % 60 )))
    local second=$(printf "%02d" $(( RANDOM % 60 )))
    # Combine into the format for `touch -t`: [[CC]YY]MMDDhhmm[.ss]
    local random_date="${year_short}${month}${day}${hour}${minute}.${second}"
    echo "$random_date"
}
# Function to recursively timestomp files and directories
timestomp_recursive() {
    local dir="$1"

    # Update timestamps for all files and directories in the current directory
    for item in "$dir"/*; do
        # Skip if the directory is empty to avoid errors
        [[ -e "$item" ]] || continue

        if [[ -d "$item" ]]; then
            # If item is a directory, recurse
            timestomp_recursive "$item"
        fi

        # Update the timestamps of the item (file or directory)
        random_date=$(generate_random_date)
        touch -t "$random_date" "$item"
        # Also make it owned by root for extra stealth and only root has perms
        chown root:root "$item"
        chmod 700 "$item"
    done

    # Finally, update the timestamp of the directory itself
    random_date=$(generate_random_date)
    touch -t "$random_date" "$dir"
    # Also make it owned by root for extra stealth and accessible only by root
    chown root:root "$dir"
    chmod 700 "$dir"
}



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

# TODO THIS IS SO OUTDATED

# Check if the first argument is "backup" to execute in backup mode
if [ "$1" = "backup" ]; then

    # Redirect all output to both terminal and log file
    touch $backupdir/log_manual.txt
    exec > >(tee -a $backupdir/log_manual.txt) 2>&1

    timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
    echo ""
    pad_string " Starting Service Mitigations Script - Backup Only Mode " "=" 75
    #echo "------Starting Script - Backup Only Mode------"
    echo "  Time: $timestamp"

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
        echo ""
        pad_string " ERROR: Mismatched backup and original directory arrays. " "-" 75
        #echo "ERROR: Mismatched backup and original directory arrays."
        exit 1
    fi

    for i in "${!original_dirs[@]}"; do
        original_dir="${original_dirs[$i]}"
        backup_dir="${backup_dirs[$i]}"
        is_single_file="${is_single_files[$i]}"
        
        echo ""
        pad_string " Service Backup - $(basename "$backup_dir") " "=" 75
        #echo "     Service Backup - $(basename "$backup_dir")     "
        #echo ""

        # Create the backup directory if it doesn't exist (should NOT exist...)
        if [ ! -d "$backup_dir" ]; then
            mkdir -p "$backup_dir"
        else
            # If backup already exists, "archive" them by appending the current time to their name.
            new_filename="$backup_dir-$timestamp"
            #echo "  Found existing backup - archiving existing files to $new_filename..."
            pad_string " Found existing backup - archiving existing files to: " "!" 75
            echo "    $new_filename"
            mv "$backup_dir" "$new_filename"
        fi
        # First time setup: make a (hopefully good...) backup that future iterations will restore from.
        echo "  Making a new master backup at $backup_dir/backup.zip..."
        if [ -d "$original_dir" ]; then
            #echo "$file is a directory."
            #only recurse if dir
            zip -q -r "$backup_dir/backup.zip" "$original_dir"
        else
            #echo "$file is not a directory."
            zip -q "$backup_dir/backup.zip" "$original_dir"
        fi
    done

    # Do not perform regular script operations after all backups are finished.
    echo ""
    echo "  Backup is finished to $backupdir. Script exiting..."
    # Recursively timestomp backup dir before #exiting. Make sure to do this after all prints are done for the log file...
    timestomp_recursive "$backupdir"
    touch -t "$timestomp" "$(dirname $backupdir)" #do the dir holding the backup dir too
    #exit 0
fi



#####################################
#### REGULAR (AUTOMATED) MODE #######
#####################################



# Redirect all output to both terminal and log file
touch $backupdir/log.txt
exec > >(tee -a $backupdir/log.txt) 2>&1

timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
echo ""
#echo "------Starting Service Mitigations Script------"
pad_string " Starting Service Mitigations Script " "=" 75
echo "  Time: $timestamp"

#####################################
############ Network ################
#####################################
echo ""
pad_string " Network " "=" 75
#echo "     Network     "
#echo ""
# Check that machine has internet connectivity
# auto determine the primary network interface. should work regardless of it is DOWN or UP. 
iface=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}' | head -n 1)

if [ -z "$iface" ]; then
    pad_string " ERROR: No primary network interface found, skipping network tests. " "-" 75
    #echo "ERROR: No primary network interface found, skipping network connectivity tests."
else
    # Check if the interface is up
    if ! ip link show "$iface" | grep -q "state UP"; then
        pad_string " Interface $iface is down, setting it to up. " "+" 75
        #echo "  Interface $iface is down, setting it to up."
        ip link set "$iface" up
        sleep 0.5 # need to wait a second for interface to come online, otherwise next checks will still error out
        #exit 0
    fi

    # Check if the interface has an IP address assigned
    if ! ip addr show "$iface" | grep -q "inet "; then
        pad_string " ERROR: Interface $iface does not have an IP address. " "-" 75
        pad_string " Operator must manually fix this error. " "-" 75
        #echo "ERROR: Interface $iface does not have an IP address. Operator must manually fix this error."
        #exit 1
    fi

    # Check if the interface is part of the correct routing table (default gateway exists)
    if ! ip route show | grep -q "$iface"; then
        pad_string " ERROR: Interface $iface is not part of the routing table. " "-" 75
        pad_string " Does it have a valid/configured route to the default gateway? " "-" 75
        pad_string " Operator must manually fix this error. " "-" 75
        #echo "ERROR: Interface $iface is not part of the routing table. Does it have a valid route to the default gateway and/or is one configured? Operator must manually fix this error."
        #exit 1
    fi

    echo "  No network configuration issues were found."
    echo "  If you still suspect network issues, make sure that all intermediate network devices are online using the ping command."

    # OLD: Ping until timeout of 2 seconds or 1 successful packet
    : '
    if ping -w 2 -c 1 8.8.8.8 &> /dev/null; then
        echo "  Network appears to be online (8.8.8.8 is reachable). Perhaps a firewall rule is blocking connection to the scoring IP?"
    else
        echo "  Network appears to be offline. Attempting to bring the primary interface to an UP state..."
        ip link set "$iface" up
        if ping -w 2 -c 1 8.8.8.8 &> /dev/null; then
            echo "  Network is still offline. Either the network config is broken, or there is a firewall/routing issue.  Operator must manually fix this error."
            #exit 1
        else
            echo "  Network mitigations successful, connectivity restored."
            #exit 0
        fi
    fi
    '
fi

#####################################
######### Service Install ###########
#####################################
# we need this because sometimes theres random other files needed for it to run, such as helper executables (apachectl)
echo ""
pad_string " Service Install Status " "=" 75
#echo "     Service Install Status     "
#echo ""
# Check service status. If non-zero, its not found.
: '
installed="false"
if command -v dpkg &> /dev/null; then
    if dpkg -l | grep -q "^ii  $packagename"; then
        installed="true"
    fi
elif command -v rpm &> /dev/null; then
    if rpm -q $packagename &>/dev/null; then
        installed="true"
    fi
fi
if $installed == "false"; then
'
if { command -v dpkg &> /dev/null && ! dpkg -s "$packagename" 2>/dev/null | grep -q '^Status: install'; } || { command -v rpm &> /dev/null && ! rpm -q "$packagename" &> /dev/null; }; then
    echo "  Service $servicename is not installed or unavailable. Reinstalling $packagename..."

    # Reinstall the package using apt, yum, or dnf
    if command -v apt &> /dev/null; then
        apt install -y "$packagename" >/dev/null
    elif command -v yum &> /dev/null; then
        yum install -y "$packagename" >/dev/null
    elif command -v dnf &> /dev/null; then
        dnf install -y "$packagename" >/dev/null
    else
        pad_string " ERROR: Package manager not supported. Install $packagename manually. " "-" 75
        pad_string " Operator must manually fix this error. " "-" 75
        #echo "ERROR: Package manager not supported. Install $packagename manually. Operator must manually fix this error."
        #exit 1
    fi

    # Start and enable the service
    systemctl start "$servicename"
    systemctl enable "$servicename"
    #echo "  Service $servicename reinstalled and started."
    pad_string " Service $servicename reinstalled and started. " "+" 75
    #exit 0
else
    echo "  Service $servicename is already installed and active."
fi

#####################################
######### Service Status ############
#####################################
echo ""
pad_string " Service Status " "=" 75
#echo "     Service Status     "
#echo ""
# Check if the service is running. If not running, start it.
if systemctl is-active --quiet "$servicename"; then
    echo "  Service $servicename is already running."
else
    echo "  Service $servicename is not running. Attempting to start it..."
    systemctl unmask "$servicename" # just in case
    systemctl start "$servicename"
    systemctl enable "$servicename"

    # Verify if the service started successfully
    if systemctl is-active --quiet "$servicename"; then
        #echo "  Service '$servicename' started successfully."
        pad_string " Service '$servicename' started successfully. " "+" 75
        #exit 0
    else
        pad_string " ERROR: Failed to start service '$servicename'. " "-" 75
        pad_string " Operator must manually fix this error. " "-" 75
        #echo "ERROR: Failed to start service '$servicename'. Operator must manually fix this error."
        #exit 1
    fi
fi

#####################################
############# Firewall ##############
#####################################
echo ""
pad_string " Firewall " "=" 75
#echo "     Firewall     "
#echo ""
echo "  Disabling unwanted firewall managers if found... (ufw, firewalld, nftables)"

## iptables tables to check
declare -a tables=("filter" "nat" "mangle" "raw" "security") # NAT cant have drop rules but whatev. RAW INPUT doesnt exist. Raw cant seem to drop packets.
declare -a chains=("INPUT" "OUTPUT" "PREROUTING" "POSTROUTING" "FORWARD") # not all tables have these chains but i cant think of a better way to do this. Also cant do custom chains unless you know the name
declare -a actions=("DROP" "REDIRECT" "TARPIT")

ufw disable
systemctl stop ufw
systemctl disable ufw
systemctl mask ufw

# RHEL
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld
systemctl stop nftables
systemctl disable nftables
systemctl mask nftables

# Enable iptables if its not running on this system
# Install iptables if not found
if ! command -v "iptables" &> /dev/null; then
    echo "iptables is not installed. Attempting to install it..."

    # Determine which package manager is available and install iptables
    if command -v "apt" &> /dev/null; then
        #echo "Using apt to install iptables..."
        apt install -y iptables &> /dev/null
    elif command -v "dnf" &> /dev/null; then
        #echo "Using dnf to install iptables..."
        dnf install -y iptables iptables-services iptables-utils &> /dev/null
    elif command -v "yum" &> /dev/null; then
        #echo "Using yum to install iptables..."
        yum install -y iptables-services &> /dev/null
    else
        echo "ERROR: No supported package manager found (apt, dnf, or yum). Install iptables manually."
        exit 1
    fi

    # Verify installation
    if command_exists iptables; then
        echo "iptables was successfully installed."
    else
        pad_string " ERROR: Package manager not supported. Install iptables-services manually. " "-" 75
    fi
fi

# Check if iptables service is available before enabling
if systemctl list-units --type=service --all | grep -q 'iptables.service'; then
    # Enable iptables if not active
    if ! systemctl is-active --quiet iptables; then
        systemctl unmask iptables
        systemctl start iptables
        systemctl enable iptables
    fi
#else
    #echo "iptables service not available on this system (likely Ubuntu)."
fi

# # Backup Old Rules ( iptables -t mangle-restore < /etc/ip_rules_old ) [for forensics and etc]
iptables-save > "$backupdir/iptables_rules_backup-$timestamp"
#ip6tables-save >/etc/ip6_rules_old

#Setup variable
rules_removed=false

echo "  Checking for iptables rules blocking scored traffic or all traffic... "
# Loop through all provided ports
for port in "${ports[@]}"; do
    # Loop through provided iptables tables
    for table in "${tables[@]}"; do
        # Loop through provided iptables chains
        #echo ""
        #echo "Scanning port $port on table $table..."
        for chain in "${chains[@]}"; do
            for action in "${actions[@]}"; do
                # Check and remove rules in chain until no more malicious rules are found
                while :; do
                    # Some notes:
                    # Rules blocking one port (without -m multiport) will have "spt:##" or "spt:##"
                    # Rules using -m multiport (regardless multiple ports are specified or not) will use the format "sports ##" or "dports ##"
                    # Using -n means that we always get numeric ports even if the user used an alias like http when adding the rule
                    deny_rules=$(iptables -t $table -L $chain -v -n --line-numbers 2> /dev/null | grep -E "$action" | grep -E "dpt:$port|spt:$port|dports.*\b$port\b|sports.*\b$port\b") #thank you mr chatgpt for regex or whatev this is.
                    if [ -z "$deny_rules" ]; then
                        # If no regular rules remain, check for drop all rules (do not contain a specific port). If its also empty, we're done.
                        #deny_rules=$(iptables -t $table -L $chain -v -n --line-numbers 2> /dev/null | grep -E "$action" | grep -Evi 'dpt:|spt:|port')
                        if [ -z "$deny_rules" ]; then
                            break
                        fi
                    fi

                    #set removal flag to true
                    rules_removed=true

                    # Extract and display the full text of the first rule before removing it
                    rule_text=$(echo "$deny_rules" | awk 'NR==1 {print $0}')
                    #echo "  $table table, $chain chain: Potentially malicious firewall rule found and deleted: $rule_text"
                    pad_string " Potentially malicious firewall rule found and deleted: " "+" 75
                    echo "    $table table, $chain chain: "
                    echo "    $rule_text"

                    # Extract and remove the first rule
                    rule_number=$(echo "$deny_rules" | awk 'NR==1 {print $1}')
                    #echo "Removing potentially malicious $chain rule number $rule_number for port $port in table $table..."
                    iptables -t $table -D "$chain" "$rule_number"
                done
            done
        done
    done
done

# If no rules were modified, then delete the backup as it is unneeded.
if [ "$rules_removed" = false ]; then
    rm "$backupdir/iptables_rules_backup-$timestamp"
    #echo "  No rules were removed, iptables backup file deleted due to being redundant."
else 
    echo ""
    pad_string " Old iptables IPv4 rules backed up to: " "!" 75
    echo "    $backupdir/iptables_rules_backup-$timestamp"
    echo "  Restore them with sudo iptables-restore < $backupdir/iptables_rules_backup-$timestamp"
    #echo "  Backed up iptables IPv4 rules to $backupdir/iptables_rules_backup-$timestamp."
fi



####################################
######## Service Integrity #########
####################################
# Initialize arrays
original_dirs=()
backup_dirs=()

# Add config variables to arrays only if they are not empty
if [ -n "$servicename" ]; then
    original_dirs+=("/lib/systemd/system/$servicename.service")
    backup_dirs+=("$backupdir/systemd")
fi

if [ -n "$binarypath" ]; then
    original_dirs+=("$binarypath")
    backup_dirs+=("$backupdir/binary")
fi

if [ -n "$configdir" ]; then
    original_dirs+=("$configdir")
    backup_dirs+=("$backupdir/config")
fi

if [ -n "$contentdir" ]; then
    original_dirs+=("$contentdir")
    backup_dirs+=("$backupdir/data")
fi

if [ -n "$miscdir1" ]; then
    original_dirs+=("$miscdir1")
    backup_dirs+=("$backupdir/misc1")
fi

if [ -n "$miscdir2" ]; then
    original_dirs+=("$miscdir2")
    backup_dirs+=("$backupdir/misc2")
fi

if [ -n "$miscdir3" ]; then
    original_dirs+=("$miscdir3")
    backup_dirs+=("$backupdir/misc3")
fi

# Ensure arrays are the same length
if [ "${#original_dirs[@]}" -ne "${#backup_dirs[@]}" ]; then
    echo ""
    #echo "     Service Integrity     "
    pad_string " Service Integrity " "=" 75
    pad_string " ERROR: Mismatched backup and original directory arrays. " "-" 75
    #echo "ERROR: Mismatched backup and original directory arrays."
    exit 1
fi

for i in "${!original_dirs[@]}"; do
    original_dir="${original_dirs[$i]}"
    backup_dir="${backup_dirs[$i]}"
    
    echo ""
    pad_string " Service Integrity - $(basename "$backup_dir") " "=" 75
    #echo "     Service Integrity - $(basename "$backup_dir")     "
    #echo ""

    # Create the backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
    fi
    # Check if the original "good" backup file already exists.
    if [ -f "$backup_dir/backup.zip" ]; then
        # Check if the backup and the active config are different.

        # unzip backup into temp dir
        rm -rf "$backup_dir/tmp"
        mkdir -p "$backup_dir/tmp"
        # absolute path funnies: will create "$backup_dir/tmp/etc/apache2" if doing apache2 config
        unzip -q "$backup_dir/backup.zip" -d "$backup_dir/tmp"

        # Compare content of all files, and compare file permissions of all files
        if diff -qr "$original_dir" "$backup_dir/tmp$original_dir" &> /dev/null && diff <(find "$original_dir" -type f -exec stat -c "%A %U %G" {} \; | sort) <(find "$backup_dir/tmp$original_dir" -type f -exec stat -c "%A %U %G" {} \; | sort) &> /dev/null; then
                echo "  Live files match the backup files. No action needed."
                rm -rf "$backup_dir/tmp"
        else
            echo "  Live files differ from the backup. Restoring backup..."
            pad_string " Creating backup file of current (bad) files to: " "!" 75
            echo "    $backup_dir/bad_backup-$timestamp.zip "
            chattr -R -i "$original_dir" #unimutable the file in case attackers messed with it. works on both directories and files
            #echo "  Creating backup file of current (bad) files to $backup_dir/bad_backup-$timestamp.zip..."
            new_backup_file_path="$backup_dir/bad_backup-$timestamp.zip"
            if [ -d "$original_dir" ]; then
                #echo "$file is a directory."
                #only recurse if dir
                zip -q -r "$new_backup_file_path" "$original_dir"
            else
                #echo "$file is not a directory."
                zip -q "$new_backup_file_path" "$original_dir"
            fi

            echo "  Restoring known good configuration..."
            # Now that we have an extra backup, attempt to restore the "good" config.
            if [ -d "$original_dir" ]; then
                rm -rf "$original_dir"
                mkdir -p "$original_dir" # this breaks if its just one file, so only do it if its a dir
                # no need for timestomp. What would we even timestomp it to? It's too hard to store that info and would be confusing.
            else 
                rm -rf "$original_dir"
            fi
            #absolute path funnies
            #unzip -q "$backup_dir/backup.zip" -d "$original_dir"
            unzip -q "$backup_dir/backup.zip" -d /
            systemctl restart "$servicename" # reload the config/content
            if [ "$(basename "$backup_dir")" = "systemd" ]; then
                systemctl daemon-reload
            fi
            rm -rf "$backup_dir/tmp"
            pad_string " File restore and service restart completed for $(basename "$backup_dir") section " "+" 75
            #echo "  Service restarted and tmp files deleted."
            #exit 0
        fi
    else
        # First time setup: make a (hopefully good...) backup that future iterations will restore from.
        pad_string " No backup file found, making a new master backup at: " "!" 75
        echo "    $backup_dir/backup.zip"
        if [ -d "$original_dir" ]; then
        #echo "$file is a directory."
            #only recurse if dir
            zip -q -r "$backup_dir/backup.zip" "$original_dir"
        else
            #echo "$file is not a directory."
            zip -q "$backup_dir/backup.zip" "$original_dir"
        fi
    fi
done

echo ""
pad_string " Service Mitigation Script Complete " "=" 75
echo ""
echo ""
echo ""
#echo "   Service Mitigation Script Complete   "
# Recursively timestomp backup dir before #exiting. Make sure to do this after all prints are done for the log file...
timestomp_recursive "$backupdir"
random_date=$(generate_random_date)
touch -t "$random_date" "$(dirname $backupdir)" #do the dir holding the backup dir too. will have a sus timestamp compared to the others but whatever

# note to self: 12 hrs of operation with 60sec cycles under moderate circumstances produces 30k lines of logs, 1.5mb. moderate = constant restore of all watched directories