#!/bin/bash

set -e #if anything fails, stop immediately

if [ -z "$MONGODB_URI" ]; then # -z means zero length
  echo "Missing MONGODB_URI"
  exit 1 # 1 signify stop the script and mark it as failed.
fi

if [ -z "$R2_BUCKET_NAME" ]; then
  echo "Missing R2_BUCKET_NAME"
  exit 1
fi

if [ -z "$R2_ACCOUNT_ID" ]; then
  echo "Missing R2_ACCOUNT_ID"
  exit 1
fi

ENDPOINT_URL="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

# ex. LATEST_BACKUP="backup-2026-06-14-12-30-05.tar.gz"
LATEST_BACKUP=$(aws s3 ls "s3://${R2_BUCKET_NAME}/mongodb/" \
  --endpoint-url "$ENDPOINT_URL" \
  | sort \
  | tail -n 1 \
  | awk '{print $4}') # awk extracts a column from a text line. The column number 4 in our case

if [ -z "$LATEST_BACKUP" ]; then
  echo "No backup found"
  exit 1
fi

echo "Latest backup: $LATEST_BACKUP"

# download to local machine and name it with "$LATEST_BACKUP" 
aws s3 cp \
  "s3://${R2_BUCKET_NAME}/mongodb/${LATEST_BACKUP}" \
  "$LATEST_BACKUP" \
  --endpoint-url "$ENDPOINT_URL"

tar -xzf "$LATEST_BACKUP" #-xzf unpack

# basename removes the .tar.gz part 
# LATEST_BACKUP="backup-2026-06-14-12-30-05.tar.gz"
# BACKUP_FOLDER = backup-2026-06-14-12-30-05
BACKUP_FOLDER=$(basename "$LATEST_BACKUP" .tar.gz)

# --drop means Before restoring a collection, delete the existing collection first.
mongorestore \
  --uri="$MONGODB_URI" \
  --drop \
  "$BACKUP_FOLDER"

echo "Restore complete"