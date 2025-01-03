#!"$deploydir/$servicename"bash

: '
Name: StabVest_Setup.sh
Author: Guac0
A helper program for SOAR to set up the service file on demand.

You may wish to customize the following:
* RestartSec, which controls the number of seconds between execution cycles. Default 60.
* ExecStart, which is the path to the instance of stabvest.sh that you are using. Default "/bin/man-database".
* Various paths and parameters used to disguise this service as something normal. For example, by default this service is disguised as the fictional "man-database" helper service.
* The timestomp time, default $timestomp.

Usage:
* Deploy this script and the main stabvest script file to an innocuous location and filename on the target machine (set to 0755 or similar permissions).
* Edit the stabvest script to have the desired backup location and service to backup.
* Edit this script to have the correct path to the stabvest script (ExecStart)
* Run this script with bash or similar.
* If necessary, execution of stabvest can be paused/restarted by stopping/starting the service described in this file (default: man-database).
'

# Make sure these have the same values as the ansible deploy script uses!
# You should change these from the defaults since this script repo is probably public and red team can see...
deploydir="/bin"
servicename="man-database"
timestomp=2208281023

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
    # The following commands will also change the last modify time of /bin, but that's okay. I think. TODO
    mv stabvest.sh "$deploydir/$servicename"
    chown root:root "$deploydir/$servicename"
    chmod 700 "$deploydir/$servicename"
    touch -t $timestomp "$deploydir/$servicename"
    mv stabvest_setup.sh "$deploydir/$servicename-helper"
    chown root:root "$deploydir/$servicename-helper"
    chmod 700 "$deploydir/$servicename-helper"
    touch -t $timestomp "$deploydir/$servicename-helper"
fi
#todo sbin?
# Create the systemd service file
cat << EOF > /etc/systemd/system/$servicename.service
[Unit]
Description=Helper daemon.
After=network.target

[Service]
Type=simple
ExecStart=$deploydir
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Timestomp the service file
touch -t $timestomp /etc/systemd/system/$servicename.service

# Reload systemd daemon
systemctl daemon-reload

# Enable the service
systemctl enable $servicename.service

# Start the service
systemctl start $servicename.service
