#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "RUN AS ROOT"
  exit 1
fi

curl -L https://github.com/falcosecurity/falcosidekick/releases/download/2.33.0/falcosidekick_2.33.0_linux_amd64.tar.gz -o falcosidekick.tar.gz
tar -xzvf falcosidekick.tar.gz
mv falcosidekick /usr/local/bin/falcosidekick
chown root:root /usr/local/bin/falcosidekick