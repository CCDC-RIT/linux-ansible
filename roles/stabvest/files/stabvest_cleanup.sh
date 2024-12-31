#!/bin/bash
: '
Name: StabVest_cleanup.sh
Author: Guac0

A development helper used for nuking all traces of StabVest from a system.
Operator must know the location of all deployed StabVest files, this does not automatically search for them.

TODO:
* mode that keeps backups but deletes other files so that this can be used in comp
'
#Options
servicepath="/etc/systemd/system/man-database.service"
setuppath="/bin/man-database-helper"
binarypath="/bin/man-database"
backupdir="/usr/share/fonts/roboto-mono/apache2"

# check for root and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit 1
fi

#delete service
systemctl stop $(basename $servicepath)
rm -rf $servicepath
systemctl daemon-reload

#delete scripts
rm -rf $setuppath
rm -rf $binarypath

# delete backups
rm -rf $backupdir