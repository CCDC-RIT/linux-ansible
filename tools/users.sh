#!/bin/bash

USERS=(
    "admiral"
    "emperor"
    "orion"
    "bigdipper"
    "captain"
    "ambassador"
    "challenger"
    "nebula"
    "neo"
    "soldier"
    "apollo"
    "explorer"
    "nova"
    "leia"
    "littledipper"
    "sol"
    "astronaut"
    "spacerock"
    "luna"
    "navigator"
    "halley"
    "luke"
    "callisto"
)

if [ "$EUID" -ne 0 ]; then
    echo "Need root to remove users"
    exit
fi

users() {
    usernames=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd)
    specials=("dd" "data" "dog" "black" "white" "grey" "gray" "blue")

    # Username the one being evaluated
    # User is predefined
    for username in $usernames; do
        for special in "${specials[@]}"; do
            if [[ "$username" =~ $special ]]; then
                echo "Special user $username found, proceed with caution"
                continue 2
            fi
        done

        for user in "${USERS[@]}"; do
            found=0
            if [ "$username" == "$user" ]; then
                found=1
            fi

            if [ $found -eq 0 ]; then
                echo "Removing user $username"
                userdel "$username"
                break
            fi
        done
    
    done
}

users