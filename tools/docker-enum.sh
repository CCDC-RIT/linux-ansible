#!/bin/bash
RED='\e[0;31m'
GREEN='\e[0;32m'
RESET='\e[0m'
PURPLE="\033[0;35m"
CYAN="\e[1;36m"
BLUE="\e[1;34m"
YELLOW="\e[0;33m"
ORANGE="\033[38;5;208m"

echo -e "\nDOCKER INVENTORY SCRIPT\n\n"

if [[ $EUID -ne 0 ]]; then
  echo -e "\n${RED}WARNING: Not running as root. Results may be incomplete.\n\n${RESET}"
fi

if command -v docker &> /dev/null
then
    :
else
    echo "Docker is not installed/not running\n"
    exit 1
fi

echo -e "${BLUE}DOCKER CONTAINER INVENTORY \n${RESET}"

echo -e "${PURPLE}RUNNING CONTAINERS: \n${RESET}"
running_containers=$(docker ps)
running_containers_bool=true
if [ "$(echo "$running_containers" | wc -l)" -lt 2 ]; then
    echo -e "${RED}No running containers.${RESET}"
    running_containers_bool=false
else
    echo "$running_containers"
fi

echo -e "\n${PURPLE}ALL CONTAINERS: \n${RESET}"
docker ps -a

echo -e "\n${PURPLE}IMAGES ON DISK:\n${RESET}"
(
  echo "REPOSITORY TAG IMAGE_ID SIZE"
  NO_COLOR=true docker images --format "{{.Repository}} {{.Tag}} {{.ID}} {{.Size}}"
) | column -t

echo -e "\n${PURPLE}HOST VOLUME MOUNTS:\n${RESET}"
for cid in $(docker ps -q); do
    name=$(docker inspect --format '{{.Name}}' "$cid" | sed 's#^/##')

    mounts=$(docker inspect --format '{{json .Mounts}}' "$cid")

    [[ "$mounts" == "[]" ]] && continue

    echo "Container '$name' ($cid) has host volume mounts:"
     echo "$mounts" | jq -r '.[] | "\(.Source) -> \(.Destination) (\(.Mode))"' | while read line; do
        if [[ "$line" == *"(rw)"* ]]; then
            echo -e "${ORANGE}${line}${RESET}"
        else
            echo -e "${line}"
        fi
    done
done

echo -e "\n${PURPLE}DOCKER PUBLISHED PORTS:\n${RESET}"
(
    echo "CONTAINER ID PROTO HOST_IP HOST_PORT CONT_PORT"
    for cid in $(docker ps -q); do
        # Fetch Name, Mode, and Port JSON in one go using '|' as delimiter
        IFS='|' read -r name mode ports <<< "$(docker inspect --format '{{.Name}}|{{.HostConfig.NetworkMode}}|{{json .NetworkSettings.Ports}}' "$cid")"
        name=${name#/} 

        # Handle --net=host
        if [[ "$mode" == "host" ]]; then
            echo -e "${RED}$name ${cid::12} TCP/UDP * * (Host_Net)${RESET}"
            continue
        fi

        # Parse, Filter (0.0.0.0/127.0.0.1), and Format
        if [[ "$ports" != "null" ]]; then
            echo "$ports" | jq -r '
                to_entries[] | select(.value) | .key as $kp | .value[] | 
                select(.HostIp == "0.0.0.0" or .HostIp == "127.0.0.1") | 
                "\($kp) \(.HostIp) \(.HostPort)"' | \
            while read -r kp hip hport; do
                 # kp=80/tcp -> ${kp#*/}=tcp, ${kp%/*}=80
                 echo "$name ${cid::12} ${kp#*/} $hip $hport ${kp%/*}"
            done
        fi
    done
) | column -t


echo -e "${BLUE}\n\nDOCKER SECURITY AUDITING \n\n${RESET}"

echo -e "${PURPLE}Checking users in Docker group...\n${RESET}"
if getent group docker >/dev/null; then
  getent group docker | cut -d: -f4 | tr ',' '\n' | sed '/^$/d'
else
  printf "${YELLOW}No docker group found.\n${RESET}"
fi

printf "\n${PURPLE}Checking Docker socket permissions...\n${RESET}"
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

printf "\n${PURPLE}Privileged Container IDs:\n\n${RESET}"
if $running_containers_bool; then
    docker inspect --format='{{.ID}} {{.HostConfig.Privileged}}' $(docker ps --format '{{.ID}}') | awk '$2 == "true" {print $1}'
fi

printf "\n${PURPLE}Checking Docker daemon logging level:\n\n${RESET}"
LOG_LEVEL="info"   # Docker default
if [[ -f /etc/docker/daemon.json && -s /etc/docker/daemon.json ]]; then
    if command -v jq >/dev/null 2>&1; then
        LOG_LEVEL=$(jq -r '."log-level" // "info"' /etc/docker/daemon.json)
    else
        echo "${YELLOW}jq not installed; assuming default log level${RESET}"
    fi
else
    PS_ARGS=$(ps -o args= -C dockerd 2>/dev/null | head -n 1)
    if [[ "$PS_ARGS" =~ --log-level=([^[:space:]]+) ]]; then
        LOG_LEVEL="${BASH_REMATCH[1]}"
    fi
fi
if [[ "$LOG_LEVEL" != "info" ]]; then
    printf "${RED}Docker log level is ${LOG_LEVEL}${RESET}\n"
else
    printf "${GREEN}Docker log level is info${RESET}\n"
fi

printf "\n${PURPLE}Checking for dangerous container capabilities...\n\n${RESET}"
BAD_CAPS=(
  CAP_SYS_ADMIN
  CAP_NET_ADMIN
  CAP_SYS_MODULE
  CAP_SYS_PTRACE
  CAP_DAC_OVERRIDE
  CAP_NET_RAW
)
for cid in $(docker ps -q); do
    name=$(docker inspect --format '{{.Name}}' "$cid" | sed 's#^/##')

    # Get CapAdd array (may be null)
    caps=$(docker inspect --format '{{json .HostConfig.CapAdd}}' "$cid")

    # Skip containers with no added caps
    [[ "$caps" == "null" ]] && continue

    for deny in "${BAD_CAPS[@]}"; do
        if echo "$caps" | grep -q "\"$deny\""; then
            printf "${RED}ALERT: Container ${name} ${cid} has dangerous capability: ${deny} ${RESET}\n"
        fi
    done
done

echo -e "\n${BLUE}Searching for Dockerfiles...\n${RESET}"
mapfile -t DOCKERFILES < <(
  find / -type f -iname 'Dockerfile*' \
    -not -path '/proc/*' \
    -not -path '/sys/*' \
    -not -path '/dev/*' \
    -not -path '/run/*' \
    -not -path '/tmp/*' \
    -not -path '/var/lib/docker/*' \
    -not -path '/run/user/*' \
    -not -path '/usr/share/man/*'\
    -not -path '/usr/share/vim/*'\
    2>/dev/null
)
if [[ ${#DOCKERFILES[@]} -eq 0 ]]; then
  printf "${RED}No Dockerfiles found.${RESET}\n"
else
  for file in "${DOCKERFILES[@]}"; do
    printf "${GREEN}%s\n${RESET}" "$file"
  done
fi

echo -e "${BLUE}Searching for Docker compose files...\n${RESET}"
mapfile -t COMPOSEFILES < <(
  find / -type f \( \
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
  printf "${RED}No Docker compose files found.${RESET}\n"
else
  for file in "${COMPOSEFILES[@]}"; do
    printf "${GREEN}%s\n${RESET}" "$file"
  done
fi