#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "bruh"
  exit
fi

# Define host local IPs
INTERNAL_WINDOWS="172.20.240.10"
INTERNAL_DEBIAN="172.20.240.20"

USER_UBUNTU_WEB="172.20.242.10"
USER_WINDOWS="172.20.242.200"
USER_UBUNTU_WORKSTATION="" # REPLACE BEFORE RUNNING

PUBLIC_SPLUNK="172.20.241.20"
PUBLIC_CENTOS="172.20.241.30"
PUBLIC_FEDORA="172.20.241.40"

EXTERNAL_WINDOWS="172.31.3.5"

# Define Palo Alto variables
FIREWALL_IP="172.20.242.150"
API_KEY=""    # REPLACE BEFORE RUNNING
BASE_URL="https://$FIREWALL_IP/api/?type=config&action=set&key=$API_KEY"

create_rule() {
  local rule_name="$1"
  local from_zone="$2"
  local to_zone="$3"
  local source="$4"
  local destination="$5"
  local application="$6"
  local service="$7"
  local action="$8"

  local xpath="/config/devices/entry/vsys/entry[@name='vsys1']/rulebase/security/rules"
  local element="<entry name='$rule_name'><from><member>$from_zone</member></from><to><member>$to_zone</member></to><source><member>$source</member></source><destination><member>$destination</member></destination><application><member>$application</member></application><service><member>$service</member></service><action>$action</action></entry>"
  
  curl -k -X GET "$BASE_URL&xpath=$xpath&element=$element"
}

# Inbound Rules
create_rule "In-SSH-Internal-Debian" "External" "Internal" "any" "$INTERNAL_DEBIAN" "application-default" "tcp-22" "allow"
create_rule "In-Docker-Internal-Windows" "External" "Internal" "any" "$INTERNAL_DEBIAN" "application-default" "tcp-8080" "allow"
create_rule "In-DNS-Internal-Windows" "External" "Internal" "any" "$INTERNAL_WINDOWS" "application-default" "udp-53" "allow"
create_rule "In-NTP-Internal_Windows" "External" "Internal" "any" "$INTERNAL_WINDOWS" "application-default" "udp-123" "allow"
create_rule "In-Web-80-User-Ubuntu-Web" "External" "User" "any" "$USER_UBUNTU_WEB" "application-default" "tcp-80" "allow"
create_rule "In-Web-443-User-Ubuntu-Web" "External" "User" "any" "$USER_UBUNTU_WEB" "application-default" "tcp-443" "allow"
# tcp remoteip=$domainSubnet localport=88,135,389,445,464,636,3268
create_rule "In-AD-TCP-88-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "In-AD-TCP-135-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "In-AD-TCP-389-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "In-AD-TCP-445-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "In-AD-TCP-464-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "In-AD-TCP-636-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "In-AD-TCP-3268-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-3268" "allow"
# udp remoteip=$domainSubnet localport=88,123,135,389,445,464,636
create_rule "In-AD-UDP-88-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-88" "allow"
create_rule "In-AD-UDP-123-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-123" "allow"
create_rule "In-AD-UDP-135-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-135" "allow"
create_rule "In-AD-UDP-389-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-389" "allow"
create_rule "In-AD-UDP-445-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-445" "allow"
create_rule "In-AD-UDP-464-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-464" "allow"
create_rule "In-AD-UDP-636-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-636" "allow"
create_rule "In-User-DNS-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-53" "allow"
create_rule "In-DHCP-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-???" "allow"
create_rule "In-SSH-User-Ubuntu-Workstation" "External" "User" "any" "$USER_UBUNTU_WORKSTATION" "application-default" "tcp-22" "allow"
create_rule "In-Web-80-User-Ubuntu-Workstation" "External" "User" "any" "$USER_UBUNTU_WORKSTATION" "application-default" "tcp-80" "allow"
create_rule "In-Web-443-User-Ubuntu-Workstation" "External" "User" "any" "$USER_UBUNTU_WORKSTATION" "application-default" "tcp-443" "allow"
create_rule "In-Splunk-9997-Public-Splunk" "External" "Public" "any" "$PUBLIC_SPLUNK" "application-default" "tcp-9997" "allow"
create_rule "In-Splunk-8000-Public-Splunk" "External" "Public" "any" "$PUBLIC_SPLUNK" "application-default" "tcp-8000" "allow"
create_rule "In-Splunk-8089-Public-Splunk" "External" "Public" "any" "$PUBLIC_SPLUNK" "application-default" "tcp-8089" "allow"
create_rule "In-Ecomm-80-Public-CentOS" "External" "Public" "any" "$PUBLIC_CENTOS" "application-default" "tcp-80" "allow"
create_rule "In-Ecomm-443-Public-CentOS" "External" "Public" "any" "$PUBLIC_CENTOS" "application-default" "tcp-443" "allow"
create_rule "In-SMTP-25-Public-Fedora" "External" "Public" "any" "$PUBLIC_FEDORA" "application-default" "tcp-25" "allow"
create_rule "In-SMTP-587-Public-Fedora" "External" "Public" "any" "$PUBLIC_FEDORA" "application-default" "tcp-587" "allow"
create_rule "In-POP3-110-Public-Fedora" "External" "Public" "any" "$PUBLIC_FEDORA" "application-default" "tcp-110" "allow"
create_rule "In-POP3-995-Public-Fedora" "External" "Public" "any" "$PUBLIC_FEDORA" "application-default" "tcp-995" "allow"

# Outbound Rules
create_rule "Out-SSH-Internal-Debian" "Internal" "External" "$INTERNAL_DEBIAN" "any" "application-default" "tcp-22" "allow"
create_rule "Out-Docker-Internal-Debian" "Internal" "External" "$INTERNAL_DEBIAN" "any" "application-default" "tcp-8080" "allow"
create_rule "Out-DNS-Internal-Windows" "Internal" "External" "$INTERNAL_WINDOWS" "any" "application-default" "udp-53" "allow"
create_rule "Out-NTP-Internal-Windows" "Internal" "External" "$INTERNAL_WINDOWS" "any" "application-default" "udp-123" "allow"
create_rule "Out-Web-80-User-Ubuntu-Web" "User" "External" "$USER_UBUNTU_WEB" "any" "application-default" "tcp-80" "allow"
create_rule "Out-Web-443-User-Ubuntu-Web" "User" "External" "$USER_UBUNTU_WEB" "any" "application-default" "tcp-443" "allow"
# tcp remoteip=$domainSubnet localport=88,135,389,445,464,636,3268
create_rule "In-AD-TCP-88-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "In-AD-TCP-135-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "In-AD-TCP-389-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "In-AD-TCP-445-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "In-AD-TCP-464-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "In-AD-TCP-636-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "In-AD-TCP-3268-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "tcp-3268" "allow"
# udp remoteip=$domainSubnet localport=88,123,135,389,445,464,636
create_rule "In-AD-UDP-88-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-88" "allow"
create_rule "In-AD-UDP-123-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-123" "allow"
create_rule "In-AD-UDP-135-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-135" "allow"
create_rule "In-AD-UDP-389-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-389" "allow"
create_rule "In-AD-UDP-445-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-445" "allow"
create_rule "In-AD-UDP-464-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-464" "allow"
create_rule "In-AD-UDP-636-User-Windows" "External" "User" "any" "$USER_WINDOWS" "application-default" "udp-636" "allow"
create_rule "Out-DNS-User-Windows" "User" "External" "$USER_WINDOWS" "any" "application-default" "udp-53" "allow"
create_rule "Out-DHCP-Users-Windows" "User" "External" "$USER_WINDOWS" "any" "application-default" "tcp-???" "allow"
create_rule "Out-SSH-User-Ubuntu-Workstation" "User" "External" "$USER_UBUNTU_WORKSTATION" "any" "application-default" "tcp-22" "allow"
create_rule "Out-Web-User-80-Ubuntu-Workstation" "User" "External" "$USER_UBUNTU_WORKSTATION" "any" "application-default" "tcp-80" "allow"
create_rule "Out-Web-User-443-Ubuntu-Workstation" "User" "External" "$USER_UBUNTU_WORKSTATION" "any" "application-default" "tcp-443" "allow"
create_rule "Out-Splunk-9997-Public-Splunk" "Public" "External" "$PUBLIC_SPLUNK" "any" "application-default" "tcp-9997" "allow"
create_rule "Out-Splunk-8000-Public-Splunk" "Public" "External" "$PUBLIC_SPLUNK" "any" "application-default" "tcp-8000" "allow"
create_rule "Out-Splunk-8089-Public-Splunk" "Public" "External" "$PUBLIC_SPLUNK" "any" "application-default" "tcp-8089" "allow"
create_rule "Out-Ecomm-80-Public-CentOS" "Public" "External" "$PUBLIC_CENTOS" "any" "application-default" "tcp-80" "allow"
create_rule "Out-Ecomm-443-Public-CentOS" "Public" "External" "$PUBLIC_CENTOS" "any" "application-default" "tcp-443" "allow"
create_rule "Out-SMTP-25-Public-Fedora" "Public" "External" "$PUBLIC_FEDORA" "any" "application-default" "tcp-25" "allow"
create_rule "Out-SMTP-587-Public-Fedora" "Public" "External" "$PUBLIC_FEDORA" "any" "application-default" "tcp-587" "allow"
create_rule "Out-POP3-110-Public-Fedora" "Public" "External" "$PUBLIC_FEDORA" "any" "application-default" "tcp-110" "allow"
create_rule "Out-POP3-995-Public-Fedora" "Public" "External" "$PUBLIC_FEDORA" "any" "application-default" "tcp-995" "allow"

# Between Rules
# tcp remoteip=$domainSubnet localport=88,135,389,445,464,636,3268
create_rule "Between-AD-TCP-88-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "Between-AD-TCP-135-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "Between-AD-TCP-389-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "Between-AD-TCP-445-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "Between-AD-TCP-464-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "Between-AD-TCP-636-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "Between-AD-TCP-3268-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "tcp-3268" "allow"
# udp remoteip=$domainSubnet localport=88,123,135,389,445,464,636
create_rule "Between-AD-UDP-88-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-88" "allow"
create_rule "Between-AD-UDP-135-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-135" "allow"
create_rule "Between-AD-UDP-389-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-389" "allow"
create_rule "Between-AD-UDP-445-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-445" "allow"
create_rule "Between-AD-UDP-464-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-464" "allow"
create_rule "Between-AD-UDP-636-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-636" "allow"
create_rule "Between-AD-UDP-3268-User-Windows" "User" "Internal" "$USER_WINDOWS" "$INTERNAL_WINDOWS" "application-default" "udp-3268" "allow"
# tcp remoteip=$domainSubnet localport=88,135,389,445,464,636,3268
create_rule "Between-AD-TCP-88-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "Between-AD-TCP-135-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "Between-AD-TCP-389-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "Between-AD-TCP-445-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "Between-AD-TCP-464-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "Between-AD-TCP-636-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "Between-AD-TCP-3268-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "tcp-3268" "allow"
# udp remoteip=$domainSubnet localport=88,123,135,389,445,464,636
create_rule "Between-AD-UDP-88-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-88" "allow"
create_rule "Between-AD-UDP-123-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-123" "allow"
create_rule "Between-AD-UDP-135-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-135" "allow"
create_rule "Between-AD-UDP-389-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-389" "allow"
create_rule "Between-AD-UDP-445-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-445" "allow"
create_rule "Between-AD-UDP-464-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-464" "allow"
create_rule "Between-AD-UDP-636-Internal-Windows" "Internal" "User" "$INTERNAL_WINDOWS" "$USER_WINDOWS" "application-default" "udp-636" "allow"

# Default Deny Rules
create_rule "Default-Deny-Inbound" "any" "any" "any" "any" "application-default" "any" "deny"
create_rule "Default-Deny-Outbound" "any" "any" "any" "any" "application-default" "any" "deny"
