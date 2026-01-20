#!/bin/bash

ANSIBLE_CONTROLLER_IP="192.168.1.1"
PASSWORD_MANAGER_IP="192.168.1.2"

if [[ $EUID != 0 ]]; then
    echo "Script must be run as root!!!!"
    exit 1
fi

if [[ -d "/opt/ccdc-password-manager-client" ]]; then
    echo "Password Manager Client already instealled"
    exit 1
fi

echo "Ensure you set ANSIBLE_CONTROLLER_IP and PASSWORD_MANAGER_IP"

mkdir -p /opt/ccdc-password-manager-client
scp blueteam@$ANSIBLE_CONTROLLER_IP:/opt/passwordmanager/ccdc-password-manager-client /opt/ccdc-password-manager-client/
scp blueteam@$ANSIBLE_CONTROLLER_IP:/opt/passwordmanager/ccdc-password-manager-client.service /etc/systemd/system/pwclient.service

mkdir -p /etc/ccdc-password-manager
touch /etc/ccdc-password-manager/token.txt

echo "$PASSWORD_MANAGER_IP" > /etc/ccdc-password-manager/server_ip_address.txt

chmod -R 600 /etc/ccdc-password-manager/
chown -R root:root /etc/ccdc-password-manager/

systemctl daemon-reload
systemctl enable pwclient
systemctl start pwclient