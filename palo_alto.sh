#!/bin/bash
# REPLACE ALL UNKNOWN VARIABLES BEFORE RUNNING

if [ "$EUID" -ne 0 ]
  then echo "bruh"
  exit
fi

# Define host local IPs
INTERNAL_LOCAL_WINDOWS="172.20.240.10"
INTERNAL_GLOBAL_WINDOWS="172.25.23.97"
INTERNAL_LOCAL_DEBIAN="172.20.240.20"
INTERNAL_GLOBAL_DEBIAN="172.25.23.20"

USER_LOCAL_UBUNTU_WEB="172.20.242.10"
USER_GLOBAL_UBUNTU_WEB="172.25.23.23"
USER_LOCAL_WINDOWS="172.20.242.200"
USER_GLOBAL_UBUNTU_WEB="172.25.23.27"
USER_LOCAL_UBUNTU_WORKSTATION="172.25.23.101"
USER_GLOBAL_UBUNTU_WORKSTATION=""

PUBLIC_LOCAL_SPLUNK="172.20.241.20"
PUBLIC_GLOBAL_SPLUNK="172.25.23.9"
PUBLIC_LOCAL_CENTOS="172.20.241.30"
PUBLIC_GLOBAL_CENTOS="172.25.23.11"
PUBLIC_LOCAL_FEDORA="172.20.241.40"
PUBLIC_GLOBAL_FEDORA="172.25.23.39"

EXTERNAL_WINDOWS="172.31.3.5"

# Define zone names
INTERNAL_ZONE="Internal"
USER_ZONE="User"
PUBLIC_ZONE="Public"
EXTERNAL_ZONE="External"
SCORING="any"

# Define Palo Alto variables
FIREWALL_IP="172.20.242.150"
API_KEY=""
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

  # URL encode the `xpath` and `element` strings
  local encoded_xpath
  local encoded_element
  encoded_xpath=$(echo -n "$xpath" | jq -sRr @uri)
  encoded_element=$(echo -n "$element" | jq -sRr @uri)

  # Construct the final URL
  local url="${BASE_URL}&xpath=${encoded_xpath}&element=${encoded_element}"

  # Make the API call
  curl -k -X POST "$url"
}

# Inbound Rules
create_rule "In-SSH-Internal-Debian" "$EXTERNAL_ZONE" "$INTERNAL_ZONE" "$SCORING" "$INTERNAL_LOCAL_DEBIAN" "application-default" "tcp-22" "allow"
create_rule "In-Docker-Internal-Windows" "$EXTERNAL_ZONE" "$INTERNAL_ZONE" "$SCORING" "$INTERNAL_LOCAL_DEBIAN" "application-default" "tcp-8080" "allow"
create_rule "In-DNS-Internal-Windows" "$EXTERNAL_ZONE" "$INTERNAL_ZONE" "$SCORING" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-53" "allow"
create_rule "In-NTP-Internal_Windows" "$EXTERNAL_ZONE" "$INTERNAL_ZONE" "$SCORING" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-123" "allow"
create_rule "In-Web-80-User-Ubuntu-Web" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_UBUNTU_WEB" "application-default" "tcp-80" "allow"
create_rule "In-Web-443-User-Ubuntu-Web" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_UBUNTU_WEB" "application-default" "tcp-443" "allow"
create_rule "In-AD-TCP-88-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "In-AD-TCP-135-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "In-AD-TCP-389-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "In-AD-TCP-445-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "In-AD-TCP-464-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "In-AD-TCP-636-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "In-AD-TCP-3268-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-3268" "allow"
create_rule "In-AD-UDP-88-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-88" "allow"
create_rule "In-AD-UDP-123-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-123" "allow"
create_rule "In-AD-UDP-135-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-135" "allow"
create_rule "In-AD-UDP-389-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-389" "allow"
create_rule "In-AD-UDP-445-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-445" "allow"
create_rule "In-AD-UDP-464-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-464" "allow"
create_rule "In-AD-UDP-636-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-636" "allow"
create_rule "In-User-DNS-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-53" "allow"
create_rule "In-SSH-User-Ubuntu-Workstation" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_UBUNTU_WORKSTATION" "application-default" "tcp-22" "allow"
create_rule "In-Web-80-User-Ubuntu-Workstation" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_UBUNTU_WORKSTATION" "application-default" "tcp-80" "allow"
create_rule "In-Web-443-User-Ubuntu-Workstation" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_UBUNTU_WORKSTATION" "application-default" "tcp-443" "allow"
create_rule "In-Splunk-9997-Public-Splunk" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_SPLUNK" "application-default" "tcp-9997" "allow"
create_rule "In-Splunk-8000-Public-Splunk" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_SPLUNK" "application-default" "tcp-8000" "allow"
create_rule "In-Splunk-8089-Public-Splunk" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_SPLUNK" "application-default" "tcp-8089" "allow"
create_rule "In-Ecomm-80-Public-CentOS" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_CENTOS" "application-default" "tcp-80" "allow"
create_rule "In-Ecomm-443-Public-CentOS" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_CENTOS" "application-default" "tcp-443" "allow"
create_rule "In-SMTP-25-Public-Fedora" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_FEDORA" "application-default" "tcp-25" "allow"
create_rule "In-SMTP-587-Public-Fedora" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_FEDORA" "application-default" "tcp-587" "allow"
create_rule "In-POP3-110-Public-Fedora" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_FEDORA" "application-default" "tcp-110" "allow"
create_rule "In-POP3-995-Public-Fedora" "$EXTERNAL_ZONE" "$PUBLIC_ZONE" "$SCORING" "$PUBLIC_LOCAL_FEDORA" "application-default" "tcp-995" "allow"

# Outbound Rules
create_rule "Out-SSH-Internal-Debian" "$INTERNAL_ZONE" "$EXTERNAL_ZONE" "$INTERNAL_LOCAL_DEBIAN" "$SCORING" "application-default" "tcp-22" "allow"
create_rule "Out-Docker-Internal-Debian" "$INTERNAL_ZONE" "$EXTERNAL_ZONE" "$INTERNAL_LOCAL_DEBIAN" "$SCORING" "application-default" "tcp-8080" "allow"
create_rule "Out-DNS-Internal-Windows" "$INTERNAL_ZONE" "$EXTERNAL_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$SCORING" "application-default" "udp-53" "allow"
create_rule "Out-NTP-Internal-Windows" "$INTERNAL_ZONE" "$EXTERNAL_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$SCORING" "application-default" "udp-123" "allow"
create_rule "Out-Web-80-User-Ubuntu-Web" "$USER_ZONE" "$EXTERNAL_ZONE" "$USER_LOCAL_UBUNTU_WEB" "$SCORING" "application-default" "tcp-80" "allow"
create_rule "Out-Web-443-User-Ubuntu-Web" "$USER_ZONE" "$EXTERNAL_ZONE" "$USER_LOCAL_UBUNTU_WEB" "$SCORING" "application-default" "tcp-443" "allow"
create_rule "In-AD-TCP-88-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "In-AD-TCP-135-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "In-AD-TCP-389-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "In-AD-TCP-445-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "In-AD-TCP-464-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "In-AD-TCP-636-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "In-AD-TCP-3268-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "tcp-3268" "allow"
create_rule "In-AD-UDP-88-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-88" "allow"
create_rule "In-AD-UDP-123-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-123" "allow"
create_rule "In-AD-UDP-135-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-135" "allow"
create_rule "In-AD-UDP-389-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-389" "allow"
create_rule "In-AD-UDP-445-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-445" "allow"
create_rule "In-AD-UDP-464-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-464" "allow"
create_rule "In-AD-UDP-636-User-Windows" "$EXTERNAL_ZONE" "$USER_ZONE" "$SCORING" "$USER_LOCAL_WINDOWS" "application-default" "udp-636" "allow"
create_rule "Out-DNS-User-Windows" "$USER_ZONE" "$EXTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$SCORING" "application-default" "udp-53" "allow"
create_rule "Out-SSH-User-Ubuntu-Workstation" "$USER_ZONE" "$EXTERNAL_ZONE" "$USER_LOCAL_UBUNTU_WORKSTATION" "$SCORING" "application-default" "tcp-22" "allow"
create_rule "Out-Web-User-80-Ubuntu-Workstation" "$USER_ZONE" "$EXTERNAL_ZONE" "$USER_LOCAL_UBUNTU_WORKSTATION" "$SCORING" "application-default" "tcp-80" "allow"
create_rule "Out-Web-User-443-Ubuntu-Workstation" "$USER_ZONE" "$EXTERNAL_ZONE" "$USER_LOCAL_UBUNTU_WORKSTATION" "$SCORING" "application-default" "tcp-443" "allow"
create_rule "Out-Splunk-9997-Public-Splunk" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_SPLUNK" "$SCORING" "application-default" "tcp-9997" "allow"
create_rule "Out-Splunk-8000-Public-Splunk" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_SPLUNK" "$SCORING" "application-default" "tcp-8000" "allow"
create_rule "Out-Splunk-8089-Public-Splunk" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_SPLUNK" "$SCORING" "application-default" "tcp-8089" "allow"
create_rule "Out-Ecomm-80-Public-CentOS" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_CENTOS" "$SCORING" "application-default" "tcp-80" "allow"
create_rule "Out-Ecomm-443-Public-CentOS" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_CENTOS" "$SCORING" "application-default" "tcp-443" "allow"
create_rule "Out-SMTP-25-Public-Fedora" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_FEDORA" "$SCORING" "application-default" "tcp-25" "allow"
create_rule "Out-SMTP-587-Public-Fedora" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_FEDORA" "$SCORING" "application-default" "tcp-587" "allow"
create_rule "Out-POP3-110-Public-Fedora" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_FEDORA" "$SCORING" "application-default" "tcp-110" "allow"
create_rule "Out-POP3-995-Public-Fedora" "$PUBLIC_ZONE" "$EXTERNAL_ZONE" "$PUBLIC_LOCAL_FEDORA" "$SCORING" "application-default" "tcp-995" "allow"

# Between Rules
create_rule "Between-AD-TCP-88-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "Between-AD-TCP-135-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "Between-AD-TCP-389-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "Between-AD-TCP-445-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "Between-AD-TCP-464-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "Between-AD-TCP-636-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "Between-AD-TCP-3268-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "tcp-3268" "allow"
create_rule "Between-AD-UDP-88-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-88" "allow"
create_rule "Between-AD-UDP-135-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-135" "allow"
create_rule "Between-AD-UDP-389-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-389" "allow"
create_rule "Between-AD-UDP-445-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-445" "allow"
create_rule "Between-AD-UDP-464-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-464" "allow"
create_rule "Between-AD-UDP-636-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-636" "allow"
create_rule "Between-AD-UDP-3268-User-Windows" "$USER_ZONE" "$INTERNAL_ZONE" "$USER_LOCAL_WINDOWS" "$INTERNAL_LOCAL_WINDOWS" "application-default" "udp-3268" "allow"
create_rule "Between-AD-TCP-88-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-88" "allow"
create_rule "Between-AD-TCP-135-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-135" "allow"
create_rule "Between-AD-TCP-389-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-389" "allow"
create_rule "Between-AD-TCP-445-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-445" "allow"
create_rule "Between-AD-TCP-464-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-464" "allow"
create_rule "Between-AD-TCP-636-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-636" "allow"
create_rule "Between-AD-TCP-3268-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "tcp-3268" "allow"
create_rule "Between-AD-UDP-88-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-88" "allow"
create_rule "Between-AD-UDP-123-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-123" "allow"
create_rule "Between-AD-UDP-135-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-135" "allow"
create_rule "Between-AD-UDP-389-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-389" "allow"
create_rule "Between-AD-UDP-445-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-445" "allow"
create_rule "Between-AD-UDP-464-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-464" "allow"
create_rule "Between-AD-UDP-636-Internal-Windows" "$INTERNAL_ZONE" "$USER_ZONE" "$INTERNAL_LOCAL_WINDOWS" "$USER_LOCAL_WINDOWS" "application-default" "udp-636" "allow"

# Default Deny Rules
create_rule "Default-Deny-Inbound" "any" "any" "any" "any" "application-default" "any" "deny"
create_rule "Default-Deny-Outbound" "any" "any" "any" "any" "application-default" "any" "deny"

# Allow DHCP
create_rule "Allow-DHCP-67-Any" "$SCORING" "$SCORING" "$SCORING" "$SCORING" "application-default" "udp-67" "allow"
create_rule "Allow-DHCP-68-Any" "$SCORING" "$SCORING" "$SCORING" "$SCORING" "application-default" "udp-68" "allow"
