#!/bin/bash

# Usage: ./backup_format_restore.sh <source_drive> <backup_dir> <filesystem>
# Example: ./backup_format_restore.sh /dev/sdb1 /tmp/backup exfat

# Input validation
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <source_drive> <backup_dir> <filesystem>"
    echo "Example: $0 /dev/sdb1 /tmp/backup exfat"
    exit 1
fi

SOURCE_DRIVE="$1"
BACKUP_DIR="$2"
FILESYSTEM="$3"

# Check if the source drive exists
if ! lsblk | grep -q "$(basename "$SOURCE_DRIVE")"; then
    echo "Error: Source drive $SOURCE_DRIVE not found!"
    exit 1
fi

# Check if the backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Backup directory $BACKUP_DIR does not exist. Creating it..."
    mkdir -p "$BACKUP_DIR" || { echo "Failed to create backup directory!"; exit 1; }
fi

# Unmount the source drive if it's mounted
if mount | grep -q "$SOURCE_DRIVE"; then
    echo "Unmounting $SOURCE_DRIVE..."
    sudo umount "$SOURCE_DRIVE" || { echo "Failed to unmount $SOURCE_DRIVE!"; exit 1; }
fi

# Backup data
echo "Backing up data from $SOURCE_DRIVE to $BACKUP_DIR..."
sudo mount "$SOURCE_DRIVE" /mnt || { echo "Failed to mount $SOURCE_DRIVE!"; exit 1; }
sudo rsync -avh --progress /mnt/ "$BACKUP_DIR/" || { echo "Data backup failed!"; exit 1; }
sudo umount /mnt

# Format the drive
echo "Formatting $SOURCE_DRIVE to $FILESYSTEM..."
if [[ "$FILESYSTEM" == "exfat" ]]; then
    sudo mkfs.exfat "$SOURCE_DRIVE" || { echo "Formatting to exFAT failed!"; exit 1; }
elif [[ "$FILESYSTEM" == "ext4" ]]; then
    sudo mkfs.ext4 "$SOURCE_DRIVE" || { echo "Formatting to ext4 failed!"; exit 1; }
else
    echo "Unsupported filesystem: $FILESYSTEM. Supported: exfat, ext4."
    exit 1
fi

# Restore data
echo "Restoring data to $SOURCE_DRIVE..."
sudo mount "$SOURCE_DRIVE" /mnt || { echo "Failed to mount $SOURCE_DRIVE after formatting!"; exit 1; }
sudo rsync -avh --progress "$BACKUP_DIR/" /mnt/ || { echo "Data restore failed!"; exit 1; }
sudo umount /mnt

echo "Process completed successfully. $SOURCE_DRIVE is now formatted to $FILESYSTEM and data has been restored."
