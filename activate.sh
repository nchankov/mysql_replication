#!/bin/bash

#current script directory
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BASENAME=$(basename "$DIR")

# Check if the .env file exists in the current directory. If not don't execute the script
if [[ ! -f $DIR/.env ]]; then
   echo "";
   echo "$BASENAME: Configuration .env file is missing";
   echo "";
   exit
fi

# Load environment variables from the .env file
set -a
source $DIR/.env
set +a

# Install cron.d for resources scanner
touch /etc/cron.d/sra_mysql_replication_monitor

# Run the script every minute (use cron syntax to change the frequency)
echo "* * * * * root $DIR/monitor.sh" > /etc/cron.d/sra_mysql_replication_monitor

# Indicate that all has been set up
echo "Activated plugin: $BASENAME"