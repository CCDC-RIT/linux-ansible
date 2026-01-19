#!/bin/bash
# iptables firewall hardening - lite
# knightswhosayni
set -euox pipefail

ANSIBLE_CONTROLLER=192.168.1.18

RED='\e[0;31m'
GREEN='\e[0;32m'
RESET='\e[0m'
PURPLE="\033[0;35m"
CYAN="\e[1;36m"
BLUE="\e[1;34m"
YELLOW="\e[0;33m"
ORANGE="\033[38;5;208m"

write-line() {
    echo -e "$1${RESET}\n"
}

if [[ $EUID -ne 0 ]]; then
  write-line "${RED} RUN AS ROOT"
  exit
fi

write-line "${GREEN}Backup existing rules"
iptables-save >> /etc/iptables_rules.v4_pre_lite

write-line "${BLUE}Accept policies"
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

write-line "${BLUE}Flush rules"
iptables -F INPUT
iptables -F OUTPUT

write-line "${BLUE}Allows all traffic from Ansible"
iptables -A INPUT -s $ANSIBLE_CONTROLLER -j ACCEPT

write-line "${BLUE}Allow SSH to Ansible"
iptables -A OUTPUT -p tcp -d $ANSIBLE_CONTROLLER --dport 22 -j ACCEPT

write-line "${BLUE}Allow SSH from Ansible"
iptables -A OUTPUT -p tcp -s $ANSIBLE_CONTROLLER --sport 22 -j ACCEPT

write-line "${BLUE}Allow SSH from Ansible"
iptables -A OUTPUT -p tcp -s $ANSIBLE_CONTROLLER --sport 22 -j ACCEPT

write-line "${BLUE}Allow HTTPS out"
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

write-line "${BLUE}Allow HTTP out"
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT

# how to do scored services?

write-line "${BLUE}Allow related and established connections in"
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

write-line "${BLUE}Allow related and established connections out"
iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

write-line "${BLUE}Allow related loopback in"
iptables -A INPUT -i lo -j ACCEPT

write-line "${BLUE}Allow related loopback out"
iptables -A OUTPUT -o lo -j ACCEPT

write-line "${ORANGE}Block everything else"
iptables -P INPUT DROP
iptables -P OUTPUT DROP

write-line "${GREEN}Save new rules"
iptables-save >> /etc/iptables_rules.v4
