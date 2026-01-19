#!/bin/bash

$WEBSERVER="192.168.1.1:8080"

if [[ $EUID -ne 0 ]]; then
  echo "RUN AS ROOT"
fi

sudo apt update -y
sudo apt install -y yara lsof vim curl openssl iptables snoopy lynis iptables-persistent jq unzip git

curl $WEBSERVER/tools/docker-enum.sh -o docker-enum.sh
curl $WEBSERVER/tools/connmon.py -o connmon.py
curl $WEBSERVER/tools/pquery.py -o pquery.py