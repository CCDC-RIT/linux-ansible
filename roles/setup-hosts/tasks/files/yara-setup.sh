#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "RUN AS ROOT"
fi

unzip -o /opt/yara.zip -d /opt/yara/

# unzip yara
tar -xzf /opt/yara/yara.tar.gz -C /opt/yara/
cd /opt/yara/yara-4.5.4/

# build and install it
./build.sh
make install

# fix a shared library
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

# unzip rules
cd /opt/yara/
unzip -o Linux.zip
unzip -o Multi.zip
unzip -o yara-forge-rules-full.zip

# compile rules
yarac /opt/yara/Linux/* /opt/yara/Multi/* /opt/yara/packages/full/yara-rules-full.yar /opt/yara/compiled_rules.yarac