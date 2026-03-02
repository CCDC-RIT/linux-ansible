#!/bin/bash
# build python from src
# use env PY_VERSION to set version to build
set -euox pipefail

SERVER_HOST=192.168.1.62 # improve

# determine package manager
if command -v apt > /dev/null 2>&1; then
    pacman="apt"
elif command -v dnf > /dev/null 2>&1; then
    pacman="dnf"
else
    exit 1
fi

# install dependencies
if [ $pacman == "apt" ]; then
    sudo apt update -y
    sudo apt install git pkg-config -y
    sudo apt install build-essential gdb lcov pkg-config \
        libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
        libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
        lzma lzma-dev tk-dev uuid-dev zlib1g-dev libzstd-dev \
        inetutils-inetd -y
else
    sudo dnf install epel-release
    sudo /usr/bin/crb enable
    sudo dnf install git pkg-config dnf-plugins-core -y
    sudo dnf builddep python3 -y
fi

# ~~clone repo~~; download from local server instead
rm -rf cpython
#git clone https://github.com/python/cypthon.git
wget --no-parent -r http://${SERVER_HOST}/cpython/
cd cpython

# switch to version if defined
if [ -v PY_VERSION ]; then
    git switch $PY_VERSION
fi

# compile
./configure --enable-optimizations --with-lto
make -s -j $(nproc)

# install
sudo make install
