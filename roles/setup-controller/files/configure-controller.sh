#!/bin/bash

set -euo pipefail

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Error: /etc/os-release not found. Cannot determine OS."
    exit 1
fi

# Iterate through each directory in /home to find the user that has linux-ansible
for user_dir in /home/*; do
    if [ -d "$user_dir/linux-ansible" ]; then
        home_user=$(basename "$user_dir")
        break
    fi
done

if [[ ! -d /"home/$home_user/.ssh" ]]; then
    mkdir -p /"home/$home_user/.ssh"
    chown "$home_user:$home_user" /"home/$home_user/.ssh"
    chmod 700 /"home/$home_user/.ssh"
fi

if [[ ! -f "/home/$home_user/.ssh/id_ed25519" ]]; then
    ssh-keygen -t ed25519 -f "/home/$home_user/.ssh/id_ed25519" -N \"\" -q
    chown "$home_user:$home_user" /"home/$home_user/.ssh/id_ed25519"
    chmod 640 /"home/$home_user/.ssh/id_ed25519"
fi

mkdir -p /opt/backups

curl -L https://github.com/VirusTotal/yara/archive/refs/tags/v4.5.4.tar.gz -o "/home/$home_user/linux-ansible/roles/setup-hosts-other/files/yara.tar.gz"
curl -L https://github.com/CCDC-RIT/YaraRules/raw/refs/heads/main/Linux.zip -o "/home/$home_user/linux-ansible/roles/setup-hosts-other/files/Linux.zip"
curl -L https://github.com/CCDC-RIT/YaraRules/raw/refs/heads/main/Multi.zip -o "/home/$home_user/linux-ansible/roles/setup-hosts-other/files/Multi.zip"
curl -L https://github.com/YARAHQ/yara-forge/releases/latest/download/yara-forge-rules-full.zip -o "/home/$home_user/linux-ansible/roles/setup-hosts-other/files/yara-forge-rules-full.zip"
chown -R "$home_user:$home_user" "/home/$home_user/linux-ansible/roles/setup-hosts-other/files/"

apt remove docker-compose-v2 -y

install -m 0755 -d /etc/apt/keyrings
curl -o /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
chmod 0644 /etc/apt/keyrings/docker.asc

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt install docker-ce docker-compose-plugin -y
systemctl restart docker

docker pull ghcr.io/ccdc-rit/password-manager:latest
docker save ghcr.io/ccdc-rit/password-manager:latest > "/home/$home_user/linux-ansible/roles/password-manager-server/files/password-manager-latest.tar"

gzip "/home/$home_user/linux-ansible/roles/password-manager-server/files/password-manager-latest.tar" --force

curl -L https://raw.githubusercontent.com/CCDC-RIT/Password-Manager/refs/heads/main/docker-compose.yml -o "/home/$home_user/linux-ansible/roles/password-manager-server/files/docker-compose.yml"

if [ ! -d "/home/$home_user/linux-ansible/roles/password-manager-client/files" ]; then
    mkdir -p "/home/$home_user/linux-ansible/roles/password-manager-client/files"
fi

curl -L https://github.com/CCDC-RIT/Password-Manager/raw/refs/heads/main/client/linux -o "/home/$home_user/linux-ansible/roles/password-manager-client/files/ccdc-password-manager-client"
curl -L https://raw.githubusercontent.com/CCDC-RIT/Password-Manager/refs/heads/main/client/linux.service  -o "/home/$home_user/linux-ansible/roles/password-manager-client/files/ccdc-password-manager-client.service"

chown -R "$home_user:$home_user" "/home/$home_user/linux-ansible/roles/password-manager-server/files/"
chown -R "$home_user:$home_user" "/home/$home_user/linux-ansible/roles/password-manager-client/files/"
chmod 0774 "/home/$home_user/linux-ansible/roles/password-manager-client/files/ccdc-password-manager-client"
chmod 0664 "/home/$home_user/linux-ansible/roles/password-manager-client/files/ccdc-password-manager-client.service"