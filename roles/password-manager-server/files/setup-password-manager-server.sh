#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)"
  exit 1
fi

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