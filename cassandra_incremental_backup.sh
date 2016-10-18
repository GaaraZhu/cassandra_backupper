#!/bin/bash
set -eu

main () {
  echo "$(date '+%d/%m/%Y %H:%M:%S') Start backuping incremental changes" >> bakcup_log_incremental.txt
  local local_disk_folder="/var/lib/cassandra/data"
  local backup_disk_folder="/mnt/cassandra/data"
  KEYSPACES=$(ls $BACKUP_SOURCE_FOLDER | grep -v "system")
  for keyspace in $KEYSPACES
  do
    # flush all data in memtable to sstable
    echo "$(date '+%d/%m/%Y %H:%M:%S') Start flushing incremental changes from memtable to sstable for keysapce: ${keyspace}" >> bakcup_log_incremental.txt
    nodetool -h localhost -p 7199 flush ${keyspace}

    #copy the incremental backup keyspace by keyspace
    for dir in ${local_disk_folder}/${keyspace}/*
    do
       echo "$(date '+%d/%m/%Y %H:%M:%S') Start copying incremental changes from: ${dir}/backup/ to: ${backup_disk_folder}/${keyspace}/${dir##*/}/backup/" >> bakcup_log_incremental.txt
      cp -r ${dir}/backup/* ${backup_disk_folder}/${keyspace}/${dir##*/}/backup/
    done
  done
  echo "$(date '+%d/%m/%Y %H:%M:%S') Finish backuping incremental changes" >> bakcup_log_incremental.txt
}

# run main after all functions are defined
main "$@"
