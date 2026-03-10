#!/bin/bash

mkdir -p /opt/backups

install -m 0755 -d /etc/apt/keyrings
curl -o /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
chmod 0644 /etc/apt/keyrings/docker.asc

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt install docker-ce docker-compose-plugin -y