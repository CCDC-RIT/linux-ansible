#!/bin/bash
# iptables firewall hardening - heavy
# knightswhosayni
set -euo pipefail

ANSIBLE_CONTROLLER=192.168.1.62 # best way to do this? env var?
PASSWORD_MANAGER=192.168.1.63
STABVEST_CONTROLLER=192.168.1.64
SCORING_IP=192.168.1.65
CONTROLLER_IN_SCOPE_IP=""

RED="\e[0;31m"
GREEN="\e[0;32m"
RESET="\e[0m"
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

write-line "${BLUE}Allow scoring in"
iptables -A INPUT -s $SCORING_IP -j ACCEPT

write-line "${BLUE}Allow scoring out"
iptables -A OUTPUT -d $SCORING_IP -j ACCEPT

write-line "${BLUE}Allows all traffic from Ansible"
iptables -A INPUT -s $ANSIBLE_CONTROLLER -j ACCEPT

write-line "${BLUE}Allow SSH to Ansible"
iptables -A OUTPUT -p tcp -d $ANSIBLE_CONTROLLER --dport 22 -j ACCEPT

write-line "${BLUE}Allow SSH from Ansible"
iptables -A INPUR -p tcp -s $ANSIBLE_CONTROLLER --dport 22 -j ACCEPT

write-line "${BLUE}Allow HTTPS out"
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

write-line "${BLUE}If laptops in scope, allow ip in on all firewalls"
if [ -n "$CONTROLLER_IN_SCOPE_IP" ]; then
    write-line "${GREEN}IP defined; applying rule"
    iptables -A INPUT -s $CONTROLLER_IN_SCOPE_IP -j ACCEPT
else
    write-line "${RED}IP not defined; continuing"
fi

# fun
write-line "${BLUE}Allow output to password manager server"
iptables -A OUTPUT -p tcp -d $PASSWORD_MANAGER --dport 443 -j ACCEPT

# check if this machine is the password manager server
write-line "${BLUE}Allow inbound if this is the password manager server"
MATCH=$(ip -o -4 addr list | awk '{print $4}' | cut -d/ -f1 | grep -F -x "$PASSWORD_MANAGER")
if [ -n "$MATCH" ]; then
    write-line "${GREEN}Match found; applying rule"
    iptables -A INPUT -p tcp -d $PASSWORD_MANAGER --dport 443 -j ACCEPT
else
    write-line "${RED}No match found; continuing"
fi

write-line "${BLUE}Allow output to stabvest server"
iptables -A OUTPUT -p tcp -d $STABVEST_CONTROLLER --dport 443 -j ACCEPT

write-line "${ORANGE}Block everything else"
iptables -P INPUT DROP
iptables -P OUTPUT DROP

write-line "${GREEN}Save new rules"
iptables-save >> /etc/iptables_rules.v4
