#!/bin/bash

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "RUN AS ROOT"
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Error: /etc/os-release not found. Cannot determine OS."
    exit 1
fi

DISTRO_ID=${ID_LIKE:-$ID}
case "$DISTRO_ID" in
    debian*|ubuntu*|mint*|raspbian*)
        apt update
        apt install yara -y
        ;;
    rhel*|centos*)
        yum update -y
        yum install yara -y
        ;;
    alma*|fedora*|rocky*)
        dnf update -y
        dnf install yara -y
        ;;
    *)
        echo "Unknown or unsupported distribution: $ID"
        exit 1
        ;;
esac

unzip -o /opt/yara/yara.zip -d /opt/yara/

version=$(yara --version | awk '{print $2}')
if [[ "$version" != "4.5.4" ]]; then
    echo "Installing Yara Manually"
    tar -xzf /opt/yara/yara.tar.gz -C /opt/yara/
    cd /opt/yara/yara-4.5.4/
    ./build.sh
fi

unzip -o /opt/yara/Linux.zip -d /opt/yara/
unzip -o /opt/yara/Multi.zip -d /opt/yara/
unzip -o /opt/yara/yara-forge-rules-full.zip -d /opt/yara/

mkdir -p /opt/yara/rules/
mv /opt/yara/Linux/* /opt/yara/rules/
mv /opt/yara/Multi/* /opt/yara/rules/
mv /opt/yara/yara-forge-rules-full/* /opt/yara/rules

yarac 