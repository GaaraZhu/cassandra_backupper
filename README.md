# CASSANDRA_BACKUPER

## BACKUP STRAGETY
- All keyspaces except system ones will be backuped
- Both snapshot and incremental backup will be used here to achieve a fine-grained backup.
- Amazon S3 will be used to store the backup files
- Housekeeping of old backup files are supposed to be done in S3

### BACKUP STEPS
1. Enable incremental backup
    - copy the incremental backup from local disk to backup disk every hour
2. Capture snapshot everyday
3. Push backup files to S3

### SNAPSHOT FOLDERS
source folder: /var/lib/cassandra/data/$KESPACE/$TABLE*/snapshot/$TIMESTAMP
backup folder: /var/lib/cassandra/custom_backups/$KESPACE/$TABLE*/backups

### RELATED COMMANDS
#### CREATING A SNAPSHOT
```
./nodetool -h $HOST -p 7199 snapshot $KEYSPACE
```

#### RESTORE A TABLE
```
./nodetool -h $HOST -p 7199 refresh $HOST $KEYSPACE $TABLE
```

#### FLUSH CHANGES TO SSTABLE
```
./nodetool -h $HOST -p 7199 flush $KEYSPACE $TABLE
```
