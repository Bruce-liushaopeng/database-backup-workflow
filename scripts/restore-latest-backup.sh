#!/bin/bash

set -e

if [ -z "$MONGODB_URI" ]; then
  echo "Missing MONGODB_URI"
  exit 1
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

LATEST_BACKUP=$(aws s3 ls "s3://${R2_BUCKET_NAME}/mongodb/" \
  --endpoint-url "$ENDPOINT_URL" \
  | sort \
  | tail -n 1 \
  | awk '{print $4}')

if [ -z "$LATEST_BACKUP" ]; then
  echo "No backup found"
  exit 1
fi

echo "Latest backup: $LATEST_BACKUP"

aws s3 cp \
  "s3://${R2_BUCKET_NAME}/mongodb/${LATEST_BACKUP}" \
  "$LATEST_BACKUP" \
  --endpoint-url "$ENDPOINT_URL"

tar -xzf "$LATEST_BACKUP"

BACKUP_FOLDER=$(basename "$LATEST_BACKUP" .tar.gz)

mongorestore \
  --uri="$MONGODB_URI" \
  --drop \
  "$BACKUP_FOLDER"

echo "Restore complete"