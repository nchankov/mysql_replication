#!/bin/bash

# Current directory
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Check if the .env file exists in the current directory. If not don't execute the script
if [ ! -f $DIR/.env ]; then
   echo "";
   echo "SAMPLE: Configuration .env file is missing";
   echo "";
   exit
fi

# Load environment variables from the .env file
set -a
source $DIR/.env
set +a

# Check if curl is installed
has_command=$(command -v mysql >/dev/null && echo true || echo false)
if [[ $has_command == false ]]; then
    echo "mysql is not installed"
    exit 1
fi

# Check if the access to the local mysql server is available
LOCAL_MYSQL_ACCESS=$(mysql -u"$MYSQL_USER" -P$MYSQL_PORT -N -s -e "SELECT 1;" 2>/dev/null)
if [ "$LOCAL_MYSQL_ACCESS" != "1" ]; then
  echo "❌ Local MySQL server is not accessible using $MYSQL_USER@localhost. Try to fix that before running this script."
  exit 1
fi

FULL_VERSION=$(mysql -u"$MYSQL_USER" -P$MYSQL_PORT -N -s -e "SELECT VERSION();")
MAIN_VERSION=$(echo "$FULL_VERSION" | cut -d. -f1)

if [ "$MAIN_VERSION" != "$MYSQL_VERSION" ]; then
    echo "❌ Local MySQL server is uncompatible with the script. Expected $MYSQL_VERSION but found $MAIN_VERSION."
    exit 1
fi

# Check if the server is a master or a slave
REPLICA_STATUS=$(mysql -u"$MYSQL_USER" -P$MYSQL_PORT -e "SHOW REPLICA STATUS\G")

IS_REPLICA=$(mysql -u$MYSQL_USER -P$MYSQL_PORT -e "SHOW REPLICA STATUS\G" | grep -c "Source_Host")

read -r IO_RUNNING <<< $(mysql -u$MYSQL_USER -P$MYSQL_PORT -e "SHOW REPLICA STATUS\G" | awk '/Replica_IO_Running:/ {print $2}' | head -n 1)
read -r SQL_RUNNING <<< $(mysql -u$MYSQL_USER -P$MYSQL_PORT -e "SHOW REPLICA STATUS\G" | awk '/Replica_SQL_Running:/ {print $2}' | head -n 1)
read -r SECONDS_BEHIND <<< $(mysql -u$MYSQL_USER -P$MYSQL_PORT -e "SHOW REPLICA STATUS\G" | awk '/Seconds_Behind_Source:/ {print $2}' | head -n 1)

# The server is not a replica so nothing to monitor
if [ "$IS_REPLICA" -eq 0 ]; then
   exit
fi

#remove the tmp file if it's old enough
if [ -f /tmp/sra-mysql_replication ]; then
    if test `find "/tmp/sra-mysql_replication" -mmin +$MAX_TIME_TO_REPEAT`
    then
        rm /tmp/sra-mysql_replication
    fi
fi

# Remote IP (in case of server without real IP)
if [ -z $NAME ]; then
   NAME=`curl -s checkip.amazonaws.com`
fi

MESSAGE=""
if [[ $IO_RUNNING != "Yes" ]]; then
   MESSAGE+="Replica IO is not running ON $NAME\n"
fi

if [[ $SQL_RUNNING != "Yes" ]]; then
   MESSAGE+="Replica SQL is not running ON $NAME\n"
fi

if (( $SECONDS_BEHIND >= $MYSQL_MAX_SECONDS_BEHIND )); then
   MESSAGE+="Replica Seconds behind are too much: $SECONDS_BEHIND ON $NAME\n"
fi

# If the message is empty, remove the file
if [[ -z $MESSAGE ]]; then
   if [ -f /tmp/sra-mysql_replication ]; then
      rm /tmp/sra-mysql_replication
   fi
   exit
fi

# check if there is a file in the tmp directory
if [ -f /tmp/sra-mysql_replication ]; then
   # the message is not empty, so write it to the file
   exit
fi

# the message is not empty, so write it to the file
echo -e "$MESSAGE" > /tmp/sra-mysql_replication

SUBJECT="Alert the server $NAME Replication problem"
# Send the message
$DIR/../../send.sh "$SUBJECT" "$MESSAGE"
