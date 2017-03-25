#!/bin/bash

set -e

BACKUP_DB_PORT=${BACKUP_DB_PORT:="27017"}

if [ "$1" = "backup" ]; then 
  exec /sbin/mongo-backup.sh -h $BACKUP_DB_HOST -P $BACKUP_DB_PORT -u $BACKUP_DB_USER -p $BACKUP_DB_PASS -d $BACKUP_DB_NAME -o /backup
  
elif [ "$1" = "restore" ]; then
  if [ -z "$2" ]; then
    exec /sbin/mongo-restore.sh -h $BACKUP_DB_HOST -P $BACKUP_DB_PORT -u $BACKUP_DB_USER -p $BACKUP_DB_PASS
  else
    exec /sbin/mongo-restore.sh -h $BACKUP_DB_HOST -P $BACKUP_DB_PORT -u $BACKUP_DB_USER -p $BACKUP_DB_PASS -i $2
  fi
fi

exec "$@"