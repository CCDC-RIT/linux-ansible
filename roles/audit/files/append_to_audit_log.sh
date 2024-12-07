#!/bin/sh
# $1 is the task name to log
# $2 is the content to log
echo -e "\033[1;34m>>>>>>>>>> $1 <<<<<<<<\033[0m" >> /opt/audit_log.txt
echo "$2" >> /opt/audit_log.txt