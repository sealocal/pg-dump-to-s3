## pg-dump-to-s3

backup with pg_dump and copy it to an s3 bucket

### Dependencies

The backup script requires the AWS CLI.

### Configure environment variables

AWS keys

    AWS_ACCESS_KEY_ID=someaccesskey
    AWS_SECRET_ACCESS_KEY=supermegasecret

Name of the region and bucket (and, optional path) to which the backup files will be uploaded.

    AWS_DEFAULT_REGION=us-east-1
    S3_BUCKET_PATH=your-bucket[/prefix]

Specify a database URL for

    DATABASE_URL=postgres://user:pass@host/source_database

String for the name of the backup file; timestamps will be appended to the file name.

    DBNAME=source_database

Set a password for the encrypted backup.

    DB_BACKUP_ENC_KEY=password

# Example Docker Usage

```
docker build -t pg_dump_to_s3 .
docker run --rm -it \
-e AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id) \
-e AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key) \
-e AWS_DEFAULT_REGION=$(aws configure get region) \
-e S3_BUCKET_PATH=$S3_BUCKET_PATH \
-e DATABASE_URL=$DATABASE_URL \
-e DBNAME=source_database \
-e DB_BACKUP_ENC_KEY=$DB_BACKUP_ENC_KEY \
pg_dump_to_s3
```

# Example Local Usage

```bash
bash /app/vendor/backup.sh --dbname <string_for_name>
```

```log
--dbname, -db

    string prefix for filename of the Postgres dump
```
