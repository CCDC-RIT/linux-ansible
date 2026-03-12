#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "RUN AS ROOT"
  exit 1
fi

curl https://github.com/falcosecurity/falcosidekick/releases/latest/download/falcosidekick-linux-amd64.tar.gz -o falcosidekick.tar.gz
tar -xzvf falcosidekick.tar.gz
mv falcosidekick /usr/local/bin/falcosidekick