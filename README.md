# CASSANDRA_BACKUPPER
Scripts to backup your cassandra(no matter whether it's dockerized or not) nodes with snapshots and incremental backups to S3

## BACKUP STRAGETY
- Both snapshot and incremental backup are supported
- All keyspaces will be backuped
- Amazon S3 will be used to store the backup files

## HOUSEKEEP STRAGETY
- Local backup files older than 30 days will be housekept when running `snapshotter.sh`
- Local snapshot files will be housekpet when running `snapshotter.sh`
- Remote files housekeeping are supposed to be done in S3


## HOW TO USE IT
### snapshotter.sh
```Responsibility: capturing snapshots and uploading(compressed) to S3```
### backupper.sh
```Responsibility: uploading incremental backups(compressed) to S3```
### prerequisites
- AWS Command Line Interface (CLI) must be installed in the node
- Script(s)(snapshotter.sh/backupper.sh) must be in one cassandra node (to the mounted folder if cassandra is runing inside a docker container)
- S3 path must exist and must be updated in script file(s)

## MISCELLANEOUS

### LOG FILES
Logs are appended to `log_snapshots.txt` and `log_incremental_backups.txt` in the same folder where the script is.

### SOURCE FOLDERS
- SNAPSHOT: /var/lib/cassandra/data/$KESPACE/$TABLE*/snapshot/$TIMESTAMP
- INCREMENTAL BACKUP: /var/lib/cassandra/custom_backups/$KESPACE/$TABLE*/backups

### RELATED COMMANDS
#### Capture a snapshot
```
./nodetool -h $HOST -p 7199 snapshot $KEYSPACE
```

#### Restore a table
```
./nodetool -h $HOST -p 7199 refresh $KEYSPACE $TABLE
```

#### Flush changes to SSTable
```
./nodetool -h $HOST -p 7199 flush $KEYSPACE $TABLE
```
