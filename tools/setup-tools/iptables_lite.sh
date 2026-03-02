#!/bin/bash
# iptables firewall hardening - lite
# knightswhosayni
set -euo pipefail

ANSIBLE_CONTROLLER=192.168.1.62 # best way to do this? env var?
PASSWORD_MANAGER=192.168.1.63
STABVEST_CONTROLLER=192.168.1.64
CONTROLLER_IN_SCOPE_IP=""

tcp_ports=
udp_ports=

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
  write-line "${RED}RUN AS ROOT"
  exit
fi

while getopts "t:u:" flag; do
    case $flag in
    t) tcp_ports="$OPTARG";;
    u) udp_ports="$OPTARG";;
    ?) write-line "${BLUE}iptables_lite${RESET} - ${GREEN}LITE${RESET} iptables rules for bash
run with the following optiions:
    ${BLUE}-t${RESET} x,y,z - tcp ports separated by commas
    ${BLUE}-u${RESET} a,b,c - udp ports separated by commas"
    exit;;
    esac
done

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
iptables -A INPUT -p tcp -s $ANSIBLE_CONTROLLER --dport 22 -j ACCEPT

write-line "${BLUE}Allow HTTPS out"
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

write-line "${BLUE}Allow HTTP out"
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT

write-line "${BLUE}Allow DNS tcp"
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

write-line "${BLUE}Allow DNS udp"
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

write-line "${BLUE}Scored TCP ports"
if [ -n "${tcp_ports}" ]; then
    write-line "${GREEN}Adding rules for scored tcp ports"
    
    IFS=',' read -ra ports <<< "$tcp_ports"
    for i in "${ports[@]}"; do
        iptables -A OUTPUT -p tcp --dport $i -j ACCEPT
    done
else
    write-line "${RED}NO TCP SCORED PORTS DEFINED; ignoring"
fi

write-line "${BLUE}Scored UDP ports"
if [ -n "${udp_ports}" ]; then
    write-line "${GREEN}Adding rules for scored udp ports"
    
    IFS=',' read -ra ports <<< "$udp_ports"
    for i in "${ports[@]}"; do
        iptables -A OUTPUT -p udp --dport $i -j ACCEPT
    done
else
    write-line "${RED}NO TCP SCORED PORTS DEFINED; ignoring"
fi

write-line "${BLUE}Allow related and established connections in"
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

write-line "${BLUE}Allow related and established connections out"
iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

write-line "${BLUE}Allow related loopback in"
iptables -A INPUT -i lo -j ACCEPT

write-line "${BLUE}Allow related loopback out"
iptables -A OUTPUT -o lo -j ACCEPT

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
