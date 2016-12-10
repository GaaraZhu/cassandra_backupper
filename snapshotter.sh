#!/bin/bash
set -eu

main () {
  echo "$(date '+%d/%m/%Y %H:%M:%S') Start backuping snapshots" >> log_snapshots.txt
  DATE=`date +%Y-%m-%d-%H-%M`
  SNAPSHOT_SOURCE_FOLDER="/var/lib/cassandra/data"
  SNAPSHOT_ROOT_FOLDER="/var/lib/cassandra/custom_snaphosts"
  SNAPSHOT_FOLDER=${SNAPSHOT_ROOT_FOLDER}/$DATE
  mkdir -p $SNAPSHOT_FOLDER

  KEYSPACE_QUERY=$(cqlsh -e "SELECT KEYSPACE_NAME FROM SYSTEM_SCHEMA.KEYSPACES" -u cassandra -p cassandra)
  read -ra KEYSPACES <<< $KEYSPACE_QUERY

  for KEYSPACE in "${KEYSPACES[@]}"
  do
    if [[ $KEYSPACE != *"keyspace_name"* ]] && [[ $KEYSPACE != *"--"* ]] && [[ $KEYSPACE != *"("* ]] && [[ $KEYSPACE != *")"* ]]
    then
        # Capture snapshot of current KEYSPACE
        echo "$(date '+%d/%m/%Y %H:%M:%S') Start snapshotting for KEYSPACE: $KEYSPACE" >> log_snapshots.txt
        echo "$(date '+%d/%m/%Y %H:%M:%S') Capturing snapshots" >> log_snapshots.txt
        nodetool -h localhost -p 7199 snapshot $KEYSPACE

        # Copy and remove snapshots keyspace by keyspace
        for dir in $SNAPSHOT_SOURCE_FOLDER/$KEYSPACE/*
        do
          TARGET_FOLDER=$SNAPSHOT_FOLDER/$KEYSPACE/${dir##*/}/
          SOURCE_FOLDER=$dir/snapshots
          if [ -d "$SOURCE_FOLDER" ]; then
            echo "$(date '+%d/%m/%Y %H:%M:%S') Copying cassandra snapshots from: $SOURCE_FOLDER to: $TARGET_FOLDER" >> log_snapshots.txt
            mkdir -p $TARGET_FOLDER
            cp -r $SOURCE_FOLDER $TARGET_FOLDER

            echo "$(date '+%d/%m/%Y %H:%M:%S') Removing existing snapshots from source folder: $SOURCE_FOLDER" >> log_snapshots.txt
            rm -r $SOURCE_FOLDER
          fi

          BACKUP_FOLDER=$dir/backups
          if [ -d "$BACKUP_FOLDER" ]; then
            echo "$(date '+%d/%m/%Y %H:%M:%S') Removing backup files older than 30 days from backups folder: $BACKUP_FOLDER" >> log_snapshots.txt
            housekeepBackup $BACKUP_FOLDER
          fi
        done
    fi
  done
  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping snapshots, zipping and pushing to s3" >> log_snapshots.txt
  tar -czf $SNAPSHOT_FOLDER.tgz $SNAPSHOT_FOLDER >> /dev/null 2>&1

  # Upload to S3
  echo `date` -- "Uploading backups to S3 -- start" >> log_snapshots.txt
  /usr/local/bin/aws s3 --region="xxxxxxxx" cp $SNAPSHOT_FOLDER.tgz s3://xxx/snapshots/
  echo `date` -- "Finished uploading" >> log_snapshots.txt

  rm -r $SNAPSHOT_ROOT_FOLDER

  echo "$(date '+%d/%m/%Y %H:%M:%S') Finished backuping snapshots" >> log_snapshots.txt
}

housekeepBackup() {
    local BACKUP_FOLDER="$1"
    find $BACKUP_FOLDER -mtime +30 -type f -delete
}

# Run main after all functions are defined
main "$@"
