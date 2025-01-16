#!/bin/bash

PALO_ALTO="172.20.254.85"
API_KEY=$(curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST https://firewall/api/?type=keygen -d "user=$USER&password=$PASSWORD")