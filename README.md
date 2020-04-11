## pg-dump-to-s3

backup with pg_dump and copy it to an s3 bucket

### Dependencies

The backup script requires the AWS CLI.

### Configure environment variables

```
DBNAME=source_database
AWS_ACCESS_KEY_ID=someaccesskey
AWS_SECRET_ACCESS_KEY=supermegasecret
AWS_DEFAULT_REGION=eu-central-1
S3_BUCKET_PATH=your-bucket
DATABASE_URL=postgres://user:pass@host/source_database
DB_BACKUP_ENC_KEY=password
```

### Usage

```bash
bash /app/vendor/backup.sh --dbname <string_for_name>
```

```log
--dbname, -db

    string prefix for filename of the Postgres dump
```
