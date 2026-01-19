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
git clone https://github.com/CCDC-RIT/linux-ansible

write-line "Copy tools directory to /var/ccdc..."
mkdir -p /var/ccdc
cp linux-ansible/tools/ -r /var/ccdc

write-line "Clone other repositories"
cd /var/ccdc
git clone https://github.com/CCDC-RIT/YaraRules
git clone https://github.com/python/cpython.git

write-line "Files finished downloading... \nHost http server  in /var/ccdc with:\n python3 -m http.server 8080"