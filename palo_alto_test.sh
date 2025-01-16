#!/bin/bash

FIREWALL_IP=""
read -s -p "Enter firewall IP: " FIREWALL_IP

USER=""
read -s -p "Enter username: " USER

PASSWORD=""
read -s -p "Enter password: " PASSWORD

API_KEY=$(curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST https://$FIREWALL_IP/api/?type=keygen -d "user=$USER&password=$PASSWORD")
echo $API_KEY