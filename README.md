# CASSANDRA_BACKUPER

## BACKUP STRAGETY
- Both snapshot and incremental backup are supported
- All keyspaces will be backuped
- Amazon S3 will be used to store the backup files
- Housekeeping of old backup files are supposed to be done in S3


## HOW TO USE IT
### snapshotter.sh (capturing snapshots and uploading them to S3)

- Copy snapshotter.sh to one cassandra node (to the mounted folder if cassandra is runing inside a docker container)
- Update S3 path in snapshotter.sh
- Run snapshotter.sh

### backuper.sh (uploading incremental backups to S3)
- Copy snapshotter.sh to one cassandra node (to the mounted folder if cassandra is runing inside a docker container)
- Enable incremental backup in yaml file
- Update S3 path in backuper.sh
- Run backuper.sh


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
