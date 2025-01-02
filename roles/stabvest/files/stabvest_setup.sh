#!/bin/bash

: '
Name: StabVest_Setup.sh
Author: Guac0
A helper program for SOAR to set up the service file on demand.

You may wish to customize the following:
* RestartSec, which controls the number of seconds between execution cycles. Default 60.
* ExecStart, which is the path to the instance of stabvest.sh that you are using. Default /bin/man-database.
* Various paths and parameters used to disguise this service as something normal. For example, by default this service is disguised as the fictional "man-database" helper service.
* The timestomp time, default 2208281023.

Usage:
* Deploy this script and the main stabvest script file to an innocuous location and filename on the target machine (set to 0755 or similar permissions).
* Edit the stabvest script to have the desired backup location and service to backup.
* Edit this script to have the correct path to the stabvest script (ExecStart)
* Run this script with bash or similar.
* If necessary, execution of stabvest can be paused/restarted by stopping/starting the service described in this file (default: man-database).
'

# check for root and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit 1
fi

# Replaces ansible deploy if that is not available.
# Assumes that this file is colocated with "stabvest.sh".
# Moves this file and the main script to their deploy locations and timestomps them.
# THIS FILE MUST BE EXECUTED BY PATH (not source) FOR MOVE TO WORK
if [ "$1" = "local" ]; then
    mv stabvest.sh /bin/man-database
    chown root:root /bin/man-database
    chmod 700 /bin/man-database
    touch -t 2208281023 /bin/man-database
    mv stabvest_setup.sh /bin/man-database-helper
    chown root:root /bin/man-database-helper
    chmod 700 /bin/man-database-helper
    touch -t 2208281023 /bin/man-database-helper
fi
#todo sbin?
# Create the systemd service file
cat << EOF > /etc/systemd/system/man-database.service
[Unit]
Description=Database daemon for man-db.
After=network.target

[Service]
Type=simple
ExecStart=/bin/man-database
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Timestomp the service file
touch -t 2208281023 /etc/systemd/system/man-database.service

# Reload systemd daemon
systemctl daemon-reload

# Enable the service
systemctl enable man-database.service

# Start the service
systemctl start man-database.service
