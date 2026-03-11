#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "RUN AS ROOT"
  exit 1
fi

curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

cat << EOF > /etc/apt/sources.list.d/falcosecurity.list
deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main
EOF

apt-get update -y
FALCO_FRONTEND=noninteractive apt-get install -y falco