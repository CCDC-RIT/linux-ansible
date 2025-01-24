#!/bin/bash

: '
Name: StabVest_Setup.sh
Author: Guac0
A helper program for SOAR to set up the service file on demand.

You may wish to customize the following:
* RestartSec, which controls the number of seconds between execution cycles. Default 60.
* ExecStart, which is the path to the instance of stabvest.sh that you are using. Default "/bin/obvioustmp".
* Various paths and parameters used to disguise this service as something normal. For example, by default this service is disguised as the fictional "obvioustmp" helper service.
* The timestomp time, default $timestomp.

Usage:
* Deploy this script and the main stabvest script file to an innocuous location and filename on the target machine (set to 0755 or similar permissions).
* Edit the stabvest script to have the desired backup location and service to backup.
* Edit this script to have the correct path to the stabvest script (ExecStart)
* Run this script with bash or similar.
* If necessary, execution of stabvest can be paused/restarted by stopping/starting the service described in this file (default: obvioustmp).
'

# Make sure these have the same values as the ansible deploy script uses!
# You should change these from the defaults since this script repo is probably public and red team can see...
deploydir="/bin"
servicename="obvioustmp"
timestomp_start_year=2000
timestomp_end_year=2005

# check for root and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit 1
fi

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

# Replaces ansible deploy if that is not available.
# Assumes that this file is colocated with "stabvest.sh".
# Moves this file and the main script to their deploy locations and timestomps them.
# THIS FILE MUST BE EXECUTED BY PATH (not source) FOR MOVE TO WORK
if [ "$1" = "local" ]; then
    # The following commands will also change the last modify time of /bin, but that's okay. I think. TODO
    mv stabvest.sh "$deploydir/$servicename"
    chown root:root "$deploydir/$servicename"
    chmod 750 "$deploydir/$servicename"
    random_date=$(generate_random_date)
    touch -t "$random_date" "$deploydir/$servicename"
    mv stabvest_setup.sh "$deploydir/$servicename-helper"
    chown root:root "$deploydir/$servicename-helper"
    chmod 750 "$deploydir/$servicename-helper"
    random_date=$(generate_random_date)
    touch -t "$random_date" "$deploydir/$servicename-helper"
fi
#todo sbin?
# Create the systemd service file
cat << EOF > /etc/systemd/system/$servicename.service
[Unit]
Description=Helper daemon
After=network.target

[Service]
Type=simple
ExecStart=$deploydir/$servicename
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Timestomp the service file
random_date=$(generate_random_date)
touch -t "$random_date" /etc/systemd/system/$servicename.service

# Reload systemd daemon
systemctl daemon-reload

# Enable the service
systemctl enable $servicename.service

# Start the service
systemctl start $servicename.service
