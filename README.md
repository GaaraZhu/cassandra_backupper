# CASSANDRA_BACKUPPER

## BACKUP STRAGETY
- Both snapshot and incremental backup are supported
- All keyspaces will be backuped
- Amazon S3 will be used to store the backup files
- Housekeeping of old backup files are supposed to be done in S3


## HOW TO USE IT
### snapshotter.sh (capturing snapshots and uploading them to S3)
### backupper.sh (uploading incremental backups to S3)
#### prerequisites
- AWS Command Line Interface (CLI) is supposed to be installed in the node.
- Script(s)(snapshotter.sh/backupper.sh) is(are) supposed to be in one cassandra node (to the mounted folder if cassandra is runing inside a docker container)
- S3 path must be updated in script file(s)


## SNAPSHOT FOLDERS
- SOURCE FOLDER: /var/lib/cassandra/data/$KESPACE/$TABLE*/snapshot/$TIMESTAMP
- BACKUP FOLDER: /var/lib/cassandra/custom_backups/$KESPACE/$TABLE*/backups


## RELATED COMMANDS
### Capture a snapshot
```
./nodetool -h $HOST -p 7199 snapshot $KEYSPACE
```

### Restore a table
```
./nodetool -h $HOST -p 7199 refresh $KEYSPACE $TABLE
```

### Flush changes to SSTable
```
./nodetool -h $HOST -p 7199 flush $KEYSPACE $TABLE
```
