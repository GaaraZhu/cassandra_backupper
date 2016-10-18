#!/bin/bash
set -eu

main () {
  echo "$(date '+%d/%m/%Y %H:%M:%S') Start backuping incremental changes" >> log_incremental_backups.txt
  DATE=`date +%Y-%m-%d-%H-%M`
  local BACKUP_SOURCE_FOLDER="/var/lib/cassandra/data"
  local BACKUP_ROOT_FOLER="/var/lib/cassandra/custom_backups"
  local BACKUP_FOLDER=${BACKUP_ROOT_FOLER}/$DATE
  mkdir -p $BACKUP_FOLDER
  
  KEYSPACE_QUERY=$(cqlsh -e "SELECT KEYSPACE_NAME FROM SYSTEM_SCHEMA.KEYSPACES" -u cassandra -p cassandra)
  read -ra KEYSPACES <<< $KEYSPACE_QUERY

  for KEYSPACE in "${KEYSPACES[@]}"
  do
    if [[ $KEYSPACE != *"keyspace_name"* ]] && [[ $KEYSPACE != *"--"* ]] && [[ $KEYSPACE != *"("* ]] && [[ $KEYSPACE != *")"* ]]
    then
      # Flush all data in memtable to sstable
      echo "$(date '+%d/%m/%Y %H:%M:%S') Start flushing incremental changes from memtable to sstable for keysapce: $keyspace" >> log_incremental_backups.txt
      nodetool -h localhost -p 7199 flush $keyspace

      # Copy the incremental backup keyspace by keyspace
      for dir in $BACKUP_SOURCE_FOLDER/$keyspace/*
      do
        TARGET_FOLDER=$BACKUP_FOLDER/$keyspace/${dir##*/}/
        SOURCE_FOLDER=$dir/backups
        if [ -d "$SOURCE_FOLDER" ]; then
          echo "$(date '+%d/%m/%Y %H:%M:%S') Start copying incremental changes from: $TARGET_FOLDER to: $TARGET_FOLDER" >> log_incremental_backups.txt
          mkdir -p $TARGET_FOLDER
          cp -r -p $SOURCE_FOLDER $TARGET_FOLDER
          #rm -r $SOURCE_FOLDER
        fi
      done
    fi
  done

  tar -czf $BACKUP_FOLDER.tgz $BACKUP_FOLDER >> /dev/null 2>&1

  # Uploading to S3
  echo `date` -- "Uploading backups to S3 -- start" >> log_incremental_backups.txt
  /usr/local/bin/aws s3 cp $BACKUP_FOLDER.tgz s3://xxx/incremental_backups/
  echo `date` -- "Finish uploading" >> log_incremental_backups.txt

  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping incremental changes" >> log_incremental_backups.txt
}

# Run main after all functions are defined
main "$@"
