#!/bin/bash
RED='\e[0;31m'
GREEN='\e[0;32m'
RESET='\e[0m'
PURPLE="\033[0;35m"

echo -e "\n${GREEN}DOCKER INVENTORY SCRIPT\n\n${RESET}"

echo -e "${PURPLE}RUNNING CONTAINERS: \n${RESET}"
docker ps

echo -e "${PURPLE}ALL CONTAINERS: \n${RESET}"
docker ps -a

echo -e "${PURPLE}AVAILABLE IMAGES:\n${RESET}"
docker images