#!/bin/bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Error: /etc/os-release not found. Cannot determine OS."
    exit 1
fi

DISTRO_ID=${ID_LIKE:-$ID}
case "$DISTRO_ID" in
    ubuntu*|debian*)
        apt-get install gcc python3-setuptools python3-dev python3-pip virtualenv -y

        install -m 0755 -d /etc/apt/keyrings
        curl -o /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
        chmod 0644 /etc/apt/keyrings/docker.asc

        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt update
        apt install docker-ce docker-compose-plugin -y
        ;;
    rhel*|rocky*|alma*|centos*|fedora*)
        rpm --import "https://download.docker.com/linux/rhel/gpg"
        curl -o /etc/yum.repos.d/docker-ce.repo "https://download.docker.com/linux/rhel/docker-ce.repo"
        sed -i '/^\[docker-ce-nightly\]/,/^\[/ { /^\[docker-ce-nightly\]/d; /^\[/!d }' /etc/yum.repos.d/docker-ce.repo
        sed -i '/^\[docker-ce-test\]/,/^\[/ s/^enabled=.*/enabled=0/' "/etc/yum.repos.d/docker-ce.repo"
        dnf install docker-ce docker-ce-cli containerd.io -y
        if [ "$DISTRO_ID" == *"8"* ]; then
            dnf remove runc -y
            dnf install container-selinux -y
        fi
        systemctl enable --now docker
        systemctl start docker
        ;;
    fedora*)
        rpm --import "https://download.docker.com/linux/fedora/gpg"
        curl -o /etc/yum.repos.d/docker-ce.repo "https://download.docker.com/linux/fedora/docker-ce.repo"
        sed -i '/^\[docker-ce-nightly\]/,/^\[/ { /^\[docker-ce-nightly\]/d; /^\[/!d }' /etc/yum.repos.d/docker-ce.repo
        sed -i '/^\[docker-ce-test\]/,/^\[/ s/^enabled=.*/enabled=0/' "/etc/yum.repos.d/docker-ce.repo"
        dnf install docker-ce docker-ce-cli containerd.io -y
        systemctl enable --now docker
        systemctl start docker
        ;;
    *)
        echo "Unknown or unsupported distribution: $ID"
        exit 1
        ;;
esac

touch password_manager.db
touch default_credentials.txt

gunzip password-manager-latest.tar.gz
docker load < password-manager-latest.tar
docker compose up -d