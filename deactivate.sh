#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BASENAME=$(basename "$DIR")

if [ -f /etc/cron.d/sra_mysql_replication_monitor ]; then
    rm /etc/cron.d/sra_mysql_replication_monitor

    # Indicate that all has been set up
    echo "Deactivated plugin: $BASENAME"
fi