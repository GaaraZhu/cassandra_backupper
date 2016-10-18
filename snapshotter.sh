#!/bin/bash
set -eu

main () {
  echo "$(date '+%d/%m/%Y %H:%M:%S') Start backuping snapshots" >> log_snapshots.txt
  DATE=`date +%Y-%m-%d-%H-%M`
  SNAPSHOT_SOURCE_FOLDER="/var/lib/cassandra/data"
  SNAPSHOT_ROOT_FOLER="/var/lib/cassandra/custom_snaphosts"
  SNAPSHOT_FOLDER=${SNAPSHOT_ROOT_FOLER}/$DATE
  mkdir -p $SNAPSHOT_FOLDER

  KEYSPACE_QUERY=$(cqlsh -e "SELECT KEYSPACE_NAME FROM SYSTEM_SCHEMA.KEYSPACES" -u cassandra -p cassandra)
  read -ra KEYSPACES <<< $KEYSPACE_QUERY

  for KEYSPACE in "${KEYSPACES[@]}"
  do
    if [[ $KEYSPACE != *"keyspace_name"* ]] && [[ $KEYSPACE != *"--"* ]] && [[ $KEYSPACE != *"("* ]] && [[ $KEYSPACE != *")"* ]]
    then
        # Capture snapshot of current KEYSPACE
        echo "$(date '+%d/%m/%Y %H:%M:%S') Start capturing snapshots for KEYSPACE: $KEYSPACE" >> log_snapshots.txt
        nodetool -h localhost -p 7199 snapshot $KEYSPACE

        # Copying and removing snapshots KEYSPACE by KEYSPACE
        for dir in $SNAPSHOT_SOURCE_FOLDER/$KEYSPACE/*
        do
          TARGET_FOLDER=$SNAPSHOT_FOLDER/$KEYSPACE/${dir##*/}/
          SOURCE_FOLDER=$dir/snapshots
          if [ -d "$SOURCE_FOLDER" ]; then
            echo "$(date '+%d/%m/%Y %H:%M:%S') Start backup cassandra snapshots from: $SOURCE_FOLDER to: $TARGET_FOLDER" >> log_snapshots.txt
            mkdir -p $TARGET_FOLDER
            cp -r $SOURCE_FOLDER $TARGET_FOLDER
            rm -r $SOURCE_FOLDER
          fi

          echo "$(date '+%d/%m/%Y %H:%M:%S') Start housekeeping old snapshots: $SNAPSHOT_FOLDER/$KEYSPACE/${dir##*/}/snapshots" >> log_snapshots.txt
        done
    fi
  done
  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping snapshots, zipping and pushing to s3" >> log_snapshots.txt
  tar -czf $SNAPSHOT_FOLDER.tgz $SNAPSHOT_FOLDER >> /dev/null 2>&1

  # Uploading to S3
  echo `date` -- "Uploading backups to S3 -- start" >> log_snapshots.txt
  /usr/local/bin/aws s3 cp $SNAPSHOT_FOLDER.tgz s3://xxx/snapshots/
  echo `date` -- "Finish uploading" >> log_snapshots.txt

  rm -r $SNAPSHOT_ROOT_FOLER

  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping snapshots" >> log_snapshots.txt
}

# Run main after all functions are defined
main "$@"
