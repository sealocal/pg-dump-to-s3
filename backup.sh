#!/bin/bash

Green='\033[0;32m'
EC='\033[0m'

# Exit this script immediately if a command exits with a non-zero status
set -e

while [[ $# -gt 1 ]]
do
key="$1"

# Parse command-line arguments for this script
case $key in
    -db|--dbname)
    DBNAME="$2"
    shift
    ;;
esac
shift
done

DBNAME=${DBNAME:='database'}
readonly timestamp=$(date --iso-8601=seconds)
readonly filename="${DBNAME}_${timestamp}"

if [[ -z "$DBNAME" ]]; then
  echo "Missing DBNAME variable"
  exit 1
fi
if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "Missing AWS_ACCESS_KEY_ID variable"
  exit 1
fi
if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Missing AWS_SECRET_ACCESS_KEY variable"
  exit 1
fi
if [[ -z "$AWS_DEFAULT_REGION" ]]; then
  echo "Missing AWS_DEFAULT_REGION variable"
  exit 1
fi
if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable"
  exit 1
fi
if [[ -z "$DATABASE_URL" ]]; then
  echo "Missing DATABASE_URL variable"
  exit 1
fi
if [[ -z "$DB_BACKUP_ENC_KEY" ]]; then
  echo "Missing DB_BACKUP_ENC_KEY variable"
  exit 1
fi

printf "${Green}Dump backup of DATABASE_URL ...${EC}\n"

if [ -f /.dockerenv ]; then
  readonly download_path='/tmp'
else
  readonly download_path='./'
fi

# Borrow pg_dump flags from pg:dump per heroku support article
# https://help.heroku.com/7U1BTYHB/how-can-i-take-a-logical-backup-of-large-heroku-postgres-databases

# Backup with plain format
printf "dump plain format ...\n"
time pg_dump \
  --no-acl --no-owner --quote-all-identifiers \
  --format=plain --compress=4 \
  $DATABASE_URL > $download_path/"${filename}"_plain_format.sql.gz

printf "Encrypt the plain format backup ...\n"
openssl enc -aes-256-cbc -pbkdf2 -e -pass "env:DB_BACKUP_ENC_KEY" \
  -in $download_path/"${filename}"_plain_format.sql.gz \
  -out /tmp/"${filename}"_plain_format.gz.enc

printf "dump custom format ...\n"
time pg_dump \
  --no-acl --no-owner --quote-all-identifiers \
  --format=custom \
  $DATABASE_URL > $download_path/"${filename}"_custom_format.dump

printf "Encrypt the custom format backup"
openssl enc -aes-256-cbc -pbkdf2 -e -pass "env:DB_BACKUP_ENC_KEY" \
  -in $download_path/"${filename}"_custom_format.dump \
  -out /tmp/"${filename}"_custom_format.enc

printf "dump directory format ...\n"
time pg_dump \
  --no-acl --no-owner --quote-all-identifiers \
  --format=directory \
  --file=$download_path/"${filename}"_directory_format $DATABASE_URL

printf "compress directory format ...\n"
tar -zcvf $download_path/"${filename}"_directory_format.tar.gz $download_path/"${filename}"_directory_format/

printf "Encrypt the directory format backup ...\n"
openssl enc -aes-256-cbc -pbkdf2 -e -pass "env:DB_BACKUP_ENC_KEY" \
  -in $download_path/"${filename}"_directory_format.tar.gz \
  -out /tmp/"${filename}"_directory_format.gz.enc

printf "dump tar format ...\n"
time pg_dump \
  --no-acl --no-owner --quote-all-identifiers \
  --format=tar \
  --file=$download_path/"${filename}"_tar_format.tar $DATABASE_URL

printf "compress tar format ...\n"
gzip $download_path/"${filename}"_tar_format.tar

printf "Encrypt the tar format backup ...\n"
openssl enc -aes-256-cbc -pbkdf2 -e -pass "env:DB_BACKUP_ENC_KEY" \
  -in $download_path/"${filename}"_tar_format.tar.gz \
  -out /tmp/"${filename}"_tar_format.gz.enc

printf "${Green}Copy Postgres dumps to AWS S3 at S3_BUCKET_PATH...${EC}\n"
printf "upload plain format ...\n"
time aws s3 cp \
  /tmp/"${filename}"_plain_format.gz.enc \
  s3://$S3_BUCKET_PATH/$DBNAME/"${filename}"_plain_format.gz.enc

printf "upload custom format ...\n"
time aws s3 cp \
  /tmp/"${filename}"_custom_format.enc \
  s3://$S3_BUCKET_PATH/$DBNAME/"${filename}"_custom_format.enc

printf "upload directroy format ...\n"
time aws s3 cp \
  /tmp/"${filename}"_directory_format.gz.enc \
  s3://$S3_BUCKET_PATH/$DBNAME/"${filename}"_directory_format.gz.enc

printf "upload tar format ...\n"
time aws s3 cp \
  /tmp/"${filename}"_tar_format.gz.enc \
  s3://$S3_BUCKET_PATH/$DBNAME/"${filename}"_tar_format.gz.enc

# Remove the database dumps from the app server
rm -v /tmp/"${filename}"_plain_format.gz.enc $download_path/"${filename}"_plain_format.sql.gz
rm -v /tmp/"${filename}"_custom_format.enc $download_path/"${filename}"_custom_format.dump
rm -rv /tmp/"${filename}"_directory_format.gz.enc $download_path/"${filename}"_directory_format.tar.gz $download_path/"${filename}"_directory_format
rm -v /tmp/"${filename}"_tar_format.gz.enc $download_path/"${filename}"_tar_format.tar.gz

printf '\nDone!\n'
