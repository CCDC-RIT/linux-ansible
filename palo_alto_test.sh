#!/bin/bash

FIREWALL_IP=""
read -s -p "Enter firewall IP: " FIREWALL_IP

USER=""
read -s -p "Enter username: " USER

PASSWORD=""
read -s -p "Enter password: " PASSWORD

RAW=$(curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST https://$FIREWALL_IP/api/?type=keygen -d "user=$USER&password=$PASSWORD")
API_KEY=$(awk -v str="$RAW" 'BEGIN { split(str, parts, "<key>|</key>"); print parts[2] }')
echo $API_KEY
