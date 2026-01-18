#!/bin/bash

write-line() {
    echo -e "\e[38;5;208m$1\e[0m\n"
}

write-line "Beginning downloads server script..."
if ! command -v git &> /dev/null; then
    write-line "ERROR: GIT NOT FOUND"
    exit 1
fi
write-line "Cloning linux-ansible repo..."
write-line "Copy tools directory to /var/ccdc..."
git clone https://github.com/CCDC-RIT/linux-ansible
mkdir -p /var/ccdc
cp linux-ansible/tools/ -r /var/ccdc
cd /var/ccdc
git clone https://github.com/CCDC-RIT/YaraRules
write-line "Files finished downloading... \nHost http server  in /var/ccdc with:\n python3 -m http.server 8080"