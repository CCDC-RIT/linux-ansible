#!/bin/bash
RED='\e[0;31m'
GREEN='\e[0;32m'
RESET='\e[0m'
PURPLE="\033[0;35m"
CYAN="\e[1;36m"
BLUE="\e[1;34m"

echo -e "\nDOCKER INVENTORY SCRIPT\n\n"

echo -e "${BLUE}DOCKER CONTAINER INVENTORY \n${RESET}"

echo -e "${PURPLE}RUNNING CONTAINERS: \n${RESET}"
docker ps

echo -e "${PURPLE}ALL CONTAINERS: \n${RESET}"
docker ps -a

echo -e "${PURPLE}AVAILABLE IMAGES:\n${RESET}"
docker images

echo -e "${BLUE}Searching for Dockerfiles...\n${RESET}"
mapfile -t DOCKERFILES < <(
  sudo find / -type f -iname 'Dockerfile*' \
    -not -path '/proc/*' \
    -not -path '/sys/*' \
    -not -path '/dev/*' \
    -not -path '/run/*' \
    -not -path '/tmp/*' \
    -not -path '/mnt/*' \
    2>/dev/null
)
if [[ ${#DOCKERFILES[@]} -eq 0 ]]; then
  printf "${RED}No Dockerfiles found.\n${RESET}"
else
  for file in "${DOCKERFILES[@]}"; do
    printf "${GREEN}%s\n${RESET}" "$file"
  done
fi

echo -e "${BLUE}Searching for Docker compose files...\n${RESET}"
mapfile -t COMPOSEFILES < <(
  sudo find / -type f \( \
    -iname 'docker-compose.yml' \
    -o -iname 'docker-compose.yaml' \
    -o -iname 'compose.yml' \
    -o -iname 'compose.yaml' \
  \) \
  -not -path '/proc/*' \
  -not -path '/sys/*' \
  -not -path '/dev/*' \
  -not -path '/run/*' \
  -not -path '/tmp/*' \
  -not -path '/mnt/*' \
  2>/dev/null
)
if [[ ${#COMPOSEFILES[@]} -eq 0 ]]; then
  printf "${RED}No Docker compose files found.\n${RESET}"
else
  for file in "${COMPOSEFILES[@]}"; do
    printf "${GREEN}%s\n${RESET}" "$file"
  done
fi