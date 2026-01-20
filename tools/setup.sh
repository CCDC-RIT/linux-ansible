#!/bin/bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Make sure to run this script as root"
  exit 1
fi

BLUETEAM_USER="blueteam"
BACKUP_DIR="/opt/backup"
QUARANTINE_DIR="/opt/quarantine"
INVENTORY_DIR="/opt/inventory"
AUDIT_DIR="/opt/audit"
SSH_PUBKEY_FILE="${HOME}/.ssh/id_ed25519.pub"

# prompt for blueteam password
while true; do
  read -s -p "Enter password for ${BLUETEAM_USER}: " BLUETEAM_PASS
  echo
  read -s -p "Confirm password: " BLUETEAM_PASS_CONFIRM
  echo

  if [ "$BLUETEAM_PASS" != "$BLUETEAM_PASS_CONFIRM" ]; then
    echo "Passwords do not match. Try again."
  elif [ -z "$BLUETEAM_PASS" ]; then
    echo "Password cannot be empty."
  else
    break
  fi
done

# generate hash of password
if command -v openssl &>/dev/null; then
  BLUETEAM_PASSWORD_HASH=$(openssl passwd -6 "$BLUETEAM_PASS")
else
  echo "openssl not found, cannot hash password"
  exit 1
fi

unset BLUETEAM_PASS BLUETEAM_PASS_CONFIRM

# detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_FAMILY=""
  case "${ID_LIKE:-} $ID" in
    *alpine*)
      OS_FAMILY="Alpine"
      ;;
    *debian*|*ubuntu*)
      OS_FAMILY="Debian"
      ;;
    *rhel*|*centos*|*fedora*)
      OS_FAMILY="RedHat"
      ;;
    *suse*)
      OS_FAMILY="Suse"
      ;;
    *)
      echo "Unsupported OS"
      exit 1
      ;;
  esac
else
  echo "Cannot detect OS"
  exit 1
fi

echo "[*] Detected OS family: $OS_FAMILY"

# make blueteam user
if ! id "${BLUETEAM_USER}" &>/dev/null; then
  if [ "$OS_FAMILY" = "Alpine" ]; then
    useradd -m -s /bin/sh -p "${BLUETEAM_PASSWORD_HASH}" "${BLUETEAM_USER}"
  else
    useradd -m -s /bin/bash -p "${BLUETEAM_PASSWORD_HASH}" "${BLUETEAM_USER}"
  fi
fi

# make blueteam group
groupadd -f "${BLUETEAM_USER}"

# add blueteam user to admin groups
case "$OS_FAMILY" in
  RedHat)
    groupadd -f wheel
    usermod -aG wheel,adm,blueteam "${BLUETEAM_USER}"
    ;;
  Debian)
    usermod -aG sudo,adm,blueteam "${BLUETEAM_USER}"
    ;;
esac
b
# add key to blueteam user
# if [ -f "$SSH_PUBKEY_FILE" ]; then
#   echo "[*] Installing SSH key"
#   mkdir -p /home/${BLUETEAM_USER}/.ssh
#   cat "$SSH_PUBKEY_FILE" >> /home/${BLUETEAM_USER}/.ssh/authorized_keys
#   chown -R ${BLUETEAM_USER}:${BLUETEAM_USER} /home/${BLUETEAM_USER}/.ssh
#   chmod 700 /home/${BLUETEAM_USER}/.ssh
#   chmod 600 /home/${BLUETEAM_USER}/.ssh/authorized_keys
# else
#   echo "[!] SSH public key not found, skipping"
# fi

# create backup, quarantine, inventory, and audit directories
mkdir -p "$BACKUP_DIR" "$QUARANTINE_DIR" "$INVENTORY_DIR" "$AUDIT_DIR"
chown -R ${BLUETEAM_USER}:${BLUETEAM_USER} \
  "$BACKUP_DIR" "$QUARANTINE_DIR" "$INVENTORY_DIR" "$AUDIT_DIR"
chmod 755 "$INVENTORY_DIR" "$AUDIT_DIR"

# update and upgrade packages, then install based on OS
echo "[*] Installing required packages..."
case "$OS_FAMILY" in
  Debian)
    apt update -y
    apt install -y \
      yara lsof vim curl openssl iptables snoopy lynis iptables-persistent jq unzip git || true
    ;;
  RedHat)
    dnf makecache -y
    dnf install -y \
      yara lsof vim curl openssl iptables snoopy lynis jq unzip git || true
    ;;
  Suse)
    zypper refresh
    zypper install -y \
      yara lsof vim curl openssl iptables lynis jq unzip git || true
    ;;
esac

# set PATH in environment
grep -q '^PATH=' /etc/environment || echo \
'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"' \
>> /etc/environment

# delete yararules directory if present
rm -rf /opt/yararules
# create yararules directory
mkdir -p /opt/yararules

# download yara forge rules
curl -L \
  https://github.com/YARAHQ/yara-forge/releases/latest/download/yara-forge-rules-full.zip \
  -o /var/tmp/forge.zip || true

# unzip yara forge rules
unzip -o /var/tmp/forge.zip -d /opt/yararules || true

# download RIT CCDC yara rules
git clone https://github.com/CCDC-RIT/YaraRules \
  /opt/yararules/YaraRules || true

# compile yara rules
if command -v yarac &>/dev/null; then
  yarac \
    /opt/yararules/YaraRules/Linux/* \
    /opt/yararules/YaraRules/Multi/* \
    /opt/yararules/packages/full/yara-rules-full.yar \
    /opt/yararules/compiled.linux || true
fi

echo "[*] Setup complete"

# install required packages
sudo apt-get update
sudo apt-get install -y python3-pip libffi-dev libssl-dev git sshpass 

# install required python modules
pip3 install pywinrm pypsrp ansible passlib ansible-core

echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc

# make directories
sudo chmod -R 777 /opt

mkdir -p /opt/audit
mkdir -p /opt/inventory

# make ssh key
ssh-keygen -t ed25519 -C "ansible@rit-ccdc" -f /opt/inventory -N ""
cp /opt/inventory $HOME/.ssh/inventory
cp /opt/inventory.pub $HOME/.ssh/inventory.pub

# Install required ansible collections
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general --force
ansible-galaxy collection install ansible.posix



echo 'Ensure that you source ~/.bashrc! Or just run this: export PATH=$HOME/.local/bin:\$PATH'