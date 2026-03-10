#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)"
  exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Error: /etc/os-release not found."
    exit 1
fi

case "$ID" in
    ubuntu)
        echo "Configuring for Ubuntu..."
        apt-get update
        apt-get install -y ca-certificates curl gnupg gcc python3-setuptools python3-dev python3-pip virtualenv
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;

    debian)
        echo "Configuring for Debian..."
        apt-get update
        apt-get install -y ca-certificates curl gnupg gcc python3-setuptools python3-dev python3-pip virtualenv
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $VERSION_CODENAME stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;

    rocky|almalinux|rhel)
        echo "Configuring for RHEL-based system: $ID $VERSION_ID"
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        
        # Address potential conflicts with buildah/podman
        dnf remove -y runc
        
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable --now docker
        ;;

    fedora)
        echo "Configuring for Fedora..."
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable --now docker
        ;;

    *)
        echo "Unsupported distribution: $ID"
        exit 1
        ;;
esac




touch password_manager.db
touch default_credentials.txt

if [ ! -f "starting_clients.txt" ]; then
    touch starting_clients.txt
fi

if [ -f "password-manager-latest.tar.gz" ]; then
    gunzip password-manager-latest.tar.gz
fi

docker load < password-manager-latest.tar
docker compose up -d