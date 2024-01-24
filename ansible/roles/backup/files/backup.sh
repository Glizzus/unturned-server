#!/bin/sh

game_name=$1
dir_to_backup=$2
base_bucket_url=$3

backup_archive="${game_name}_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
temp_backup_dir="/tmp/${backup_archive}"

do_tar() {
    # We use basename to avoid the full path being included in the tar
    tar -czf "$temp_backup_dir" "$(basename "$dir_to_backup")"
}
(cd "$(dirname "$dir_to_backup")" && do_tar)

hash=$(sha256sum "$temp_backup_dir" | awk '{print $1}')
echo "Hash of $backup_archive: $hash"

hash_bucket_url="${base_bucket_url}-hashes"
existing_hash=$(s3cmd --no-progress get "${hash_bucket_url}/${hash}" -)

if [ -n "$existing_hash" ]; then
    echo "Hash $hash already exists in bucket $hash_bucket_url"
    exit 0
fi

# Upload hash to bucket
echo "$backup_archive" > "/tmp/${hash}"
s3cmd put "/tmp/${hash}" "${hash_bucket_url}/"

# The trailing slash means the file is uploaded with the file name
s3cmd put "$temp_backup_dir" "$base_bucket_url/"

cleanup() {
    rm "$temp_backup_dir"
}

trap cleanup EXIT
