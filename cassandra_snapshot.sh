#!/bin/bash
set -eu

main () {
  echo "$(date '+%d/%m/%Y %H:%M:%S') Start backuping snapshots" >> backcup_log.txt
  DATE=`date +%Y-%m-%d-%H-%M`
  local BACKUP_SOURCE_FOLDER="/var/lib/cassandra/data"
  # local BACKUP_ROOT_FOLER="/mnt/cassandra/data"
  local BACKUP_ROOT_FOLER="/var/lib/cassandra/custom_backups"
  local BACKUP_FOLDER=${BACKUP_ROOT_FOLER}/$DATE
  mkdir -p ${BACKUP_FOLDER}

  KEYSPACES=$(ls $BACKUP_SOURCE_FOLDER | grep -v "system")
  for KEYSPACE in $KEYSPACES
  do
    # capture snapshot of current KEYSPACE
    echo "$(date '+%d/%m/%Y %H:%M:%S') Start capturing snapshots for KEYSPACE: $KEYSPACE" >> backcup_log.txt
    nodetool -h localhost -p 7199 snapshot $KEYSPACE

    # copy and removing snapshots KEYSPACE by KEYSPACE
    for dir in ${BACKUP_SOURCE_FOLDER}/$KEYSPACE/*
    do
      echo "$(date '+%d/%m/%Y %H:%M:%S') Start backup cassandra snapshots from: ${dir}/snapshots/* to:${BACKUP_FOLDER}/$KEYSPACE/${dir##*/}/snapshots/" >> backcup_log.txt
      cp -r ${dir}/snapshots/* ${BACKUP_FOLDER}/$KEYSPACE/${dir##*/}/snapshots/
      rm -r ${dir}/snapshots/*
      echo "$(date '+%d/%m/%Y %H:%M:%S') Start housekeeping old snapshots: ${BACKUP_FOLDER}/$KEYSPACE/${dir##*/}/snapshots" >> backcup_log.txt
    done
  done
  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping snapshots, zipping and pushing to s3" >> backcup_log.txt
  tar -czf $BACKUP_FOLDER.tgz $BACKUP_FOLDER >> /dev/null 2>&1

  # Uploading to S3
  echo `date` -- "Uploading backups to S3 -- start" >> backcup_log.txt
  /usr/local/bin/aws s3 cp $BACKUP_FOLDER s3://xxxxxxxx/ --recursive
  echo `date` -- "Finish uploading" >> backcup_log.txt

  #rm -r $BACKUP_ROOT_FOLER

  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping snapshots" >> backcup_log.txt
}

# run main after all functions are defined
main "$@"
