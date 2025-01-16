#!/bin/bash

API_KEY=$(curl -H "Content-Type: application/x-www-form-urlencoded" -X POST https://firewall/api/?type=keygen -d "user=$USER&password=$PASSWORD")