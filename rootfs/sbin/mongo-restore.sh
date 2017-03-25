#!/bin/bash

MONGORESTORE=$(which mongorestore)
DUMPFILE="$(dirname "$(realpath "$0")")\mongo.gz"
DBHOST="127.0.0.1"
DBPORT="27017"
DBNAME="db"
DBUSER="backup"
DBPASS=""

#
# SHOW HELP
#
if [ -z "$1" ]; then
    cat <<EOF
USAGE
    $(basename $0) [options]
    
OPTIONS
     -h host      - hostname/IP of Mongo server (default: $DBHOST)
     -P port      - port of Mongo server (default: $DBPORT)
     -u user      - Mongo backup user (default: $DBUSER)
     -p password  - Mongo backup user password (specify "-" for a prompt)
     -i inputfile - input gzip Mongo archive file
                    (default: $DUMPFILE) 

EXAMPLE
    $(basename $0) -h 1.2.3.4 -d db -u backup -p test
    $(basename $0) -d db -u backup -p - -i /backup/mongo.gz
EOF
    exit 1
fi  

#
# PARSE COMMAND LINE ARGUMENTS
#
while getopts ":h:d:u:p:i:" opt; do
  case $opt in
    h)  DBHOST="$OPTARG" ;;
    P)  DBPORT="$OPTARG" ;;
    u)  DBUSER="$OPTARG" ;;
    p)  DBPASS="$OPTARG" ;;
    i)  DUMPFILE="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :)  echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
  esac
done

if [ "$DBPASS" = "" ]; then
    echo "No password given" >&2
    exit 1
fi

if [ "$DBPASS" = "-" ]; then
    read -s -p "Enter Mongo password for user '$DBUSER' (input will be hidden): " DBPASS
    echo ""
fi

#
# CONSTANTS
#
MONGO_CONN="--host ${DBHOST} --port ${DBPORT} --username ${DBUSER} --password ${DBPASS} --authenticationDatabase admin --gzip --archive=${DUMPFILE}"
MONGO_RESTORE="${MONGORESTORE} $MONGO_CONN"

if [[ -f ${DUMPFILE} ]]; then
    
    echo "=> Restore mongo database..."    
    $MONGO_RESTORE
    echo "=> Done!"
    exit
else
    echo "=> ${DUMPFILE} not found!"
    exit 1
fi
