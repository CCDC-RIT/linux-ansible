#!/bin/bash
RED='\e[0;31m'
GREEN='\e[0;32m'
RESET='\e[0m'
PURPLE="\033[0;35m"
CYAN="\e[1;36m"
BLUE="\e[1;34m"
YELLOW="\e[0;33m"

echo -e "\nDOCKER INVENTORY SCRIPT\n\n"

if [[ $EUID -ne 0 ]]; then
  echo -e "\n${RED}WARNING: Not running as root. Results may be incomplete.\n\n${RESET}"
fi

echo -e "${BLUE}DOCKER CONTAINER INVENTORY \n${RESET}"

echo -e "${PURPLE}RUNNING CONTAINERS: \n${RESET}"
docker ps

echo -e "${PURPLE}ALL CONTAINERS: \n${RESET}"
docker ps -a

echo -e "${PURPLE}AVAILABLE IMAGES:\n${RESET}"
docker images


echo -e "${BLUE}\n\nDOCKER SECURITY AUDITING \n\n${RESET}"

echo -e "${PURPLE}Checking users in Docker group...\n${RESET}"
if getent group docker >/dev/null; then
  getent group docker | cut -d: -f4 | tr ',' '\n' | sed '/^$/d'
else
  printf "${YELLOW}No docker group found.\n${RESET}"
fi

printf "${PURPLE}Checking Docker socket permissions...\n${RESET}"
if [[ -S /var/run/docker.sock ]]; then
  perms=$(stat -c "%a %U:%G" /var/run/docker.sock)
  if [[ $(stat -c "%a" /var/run/docker.sock) -ge 666 ]]; then
    printf "${RED}ALERT: docker.sock is world-writable (%s)\n${RESET}" "$perms"
  else
    printf "${GREEN}OK: docker.sock permissions (%s)\n${RESET}" "$perms"
  fi
else
  printf "${RED}docker.sock not found.\n${RESET}"
fi

printf "${PURPLE}Containers running as root:\n${RESET}"

echo -e "${BLUE}Searching for Dockerfiles...\n${RESET}"
mapfile -t DOCKERFILES < <(
  sudo find / -type f -iname 'Dockerfile*' \
    -not -path '/proc/*' \
    -not -path '/sys/*' \
    -not -path '/dev/*' \
    -not -path '/run/*' \
    -not -path '/tmp/*' \
    -not -path '/var/lib/docker/*' \
    -not -path '/run/user/*' \
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
  -not -path '/var/lib/docker/*' \
  -not -path '/run/user/*' \
  2>/dev/null
)
if [[ ${#COMPOSEFILES[@]} -eq 0 ]]; then
  printf "${RED}No Docker compose files found.\n${RESET}"
else
  for file in "${COMPOSEFILES[@]}"; do
    printf "${GREEN}%s\n${RESET}" "$file"
  done
fi