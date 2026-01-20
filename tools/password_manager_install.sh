#!/bin/bash

ANSIBLE_CONTROLLER_IP="192.168.1.1"

if [[ $EUID != 0 ]]; then
    echo "Script must be run as root!!!!"
    exit 1
fi

if [[ -f "/opt/ccdc-password-manager/Password-Manager/docker-compose.yml" ]]; then
    echo "Password Manager Server already instealled"
    exit 1
fi

# Get Password Manager Server from ansible controller
mkdir -p /opt/ccdc-password-manager/
scp blueteam@$ANSIBLE_CONTROLLER_IP:/opt/passwordmanager/Password-Manager /opt/ccdc-password-manager/
chown -R blueteam:blueteam /opt/ccdc-password-manager
scp blueteam@$ANSIBLE_CONTROLLER_IP:/opt/passwordmanager/starting_clients.txt /opt/ccdc-password-manager/Password-Manager/starting_clients.txt

# Install Docker
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker compose -f /opt/ccdc-password-manager/Password-Manager/docker-compose.yml up -d