#!/bin/bash

MONGODUMP=$(which mongodump)
DUMPDIR="$(dirname "$(realpath "$0")")"
DBHOST="localhost"
DBPORT="27017"
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
     -d database  - Zabbix database name (default: $DBNAME)
     -u user      - Mongo backup user (default: $DBUSER)
     -p password  - Mongo backup user password (specify "-" for a prompt)
     -o outputdir - output directory for the Mongo dump file
                    (default: $DUMPDIR) 

EXAMPLE
    $(basename $0) -h 1.2.3.4 -d db -u backup -p test
    $(basename $0) -d db -u backup -p - -o /tmp
EOF
    exit 1
fi  

#
# PARSE COMMAND LINE ARGUMENTS
#
while getopts ":h:P:d:u:p:o:" opt; do
  case $opt in
    h)  DBHOST="$OPTARG" ;;
    P)  DBPORT="$OPTARG" ;;
    d)  DBNAME="$OPTARG" ;;
    u)  DBUSER="$OPTARG" ;;
    p)  DBPASS="$OPTARG" ;;
    o)  DUMPDIR="$OPTARG" ;;
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
DUMPFILEBASE="${DBNAME}_$(date +%Y%m%d-%H%M).gz"
DUMPFILE="${DUMPDIR}/${DUMPFILEBASE}"

MONGO_CONN="--host ${DBHOST} --port ${DBPORT} --username ${DBUSER} --password ${DBPASS} --authenticationDatabase admin --db ${DBNAME} --gzip --archive=${DUMPFILE}"
MONGO_DUMP="${MONGODUMP} $MONGO_CONN"

#
# CONFIG DUMP
#
cat <<EOF
Configuration:
 - host:     $DBHOST
 - database: $DBNAME
EOF

#
# BACKUP
#
mkdir -p "${DUMPDIR}"
echo "Dump database to ${DUMPFILE}..."
$MONGO_DUMP

echo
echo "Rotate backup copy..."
find "${DUMPDIR}/" -maxdepth 1 -mtime +10 -type f -exec rm -rv {} \;
if [ $? -ne 0 ]; then
    echo -e "\nERROR: Could not rotate backup file, see previous messages" >&2
    exit 1
fi

echo -e "\nBackup Completed:\n${DUMPFILE}"
exit