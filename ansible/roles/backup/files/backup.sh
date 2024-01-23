#!/bin/sh

set -e

GAME=$1
BACKUP_DIR=$2
BUCKET_URL=$3

BACKUP_NAME="${GAME}_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
TEMP_BACKUP_DIR="/tmp/${BACKUP_NAME}"

do_tar() {
    # We use basename to avoid the full path being included in the tar
    tar -czf "$TEMP_BACKUP_DIR" "$(basename "$BACKUP_DIR")"
}

# Create backup
# We need to cd into the directory to avoid the full path being included in the tar,
# while also avoiding the pesky ./ prefix that would be included if we didn't cd
(cd "$(dirname "$BACKUP_DIR")" && do_tar)

# Upload to S3
# The trailing slash means the file is uploaded with the file name
s3cmd put "$TEMP_BACKUP_DIR" "$BUCKET_URL/"

cleanup() {
    rm "$TEMP_BACKUP_DIR"
}

trap cleanup EXIT
