#!/bin/bash

# A helper program for SOAR to set up the service file on demand.
# You may wish to change RestartSec, default is 60

# check for root and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit 1
fi

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
