#!/bin/bash

# Configuration
SRC="/home/$USER/"  # Source directory to back up
DEST="/mnt/nas/linux_backup"  # Destination directory on NAS
LOGFILE="/var/log/backup.log"
COMP_LEVEL=3  # Compression level (higher = better, but slower)
THREADS=$(nproc)  # Use all available CPU cores for compression
RETENTION_DAYS=7  # Keep 7 daily backups
RETENTION_WEEKS=4  # Keep 4 weekly backups
RETENTION_MONTHS=6  # Keep 6 monthly backups

# Exclusions (cache, downloads, unnecessary files)
EXCLUDES="--exclude='.cache' --exclude='Downloads' --exclude='node_modules' --exclude='target' --exclude='go'"

# Timestamp for new backup
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
DAILY_ARCHIVE="$DEST/daily/$DATE.tar.zst"
WEEKLY_ARCHIVE="$DEST/weekly/$DATE.tar.zst"
MONTHLY_ARCHIVE="$DEST/monthly/$DATE.tar.zst"

# Ensure backup directories exist
mkdir -p "$DEST/daily" "$DEST/weekly" "$DEST/monthly"

# 🔹 Step 1: Start Backup & Log Time
echo "Backup started at $(date)" | tee -a "$LOGFILE"
START_TIME=$(date +%s)

# 🔹 Step 2: Directly Create a Compressed Archive on the NAS
echo "Compressing files with ZSTD (Level $COMP_LEVEL, $THREADS threads) directly to NAS..." | tee -a "$LOGFILE"

# Create a compressed archive directly in the daily folder
tar --use-compress-program="zstd -T$THREADS -$COMP_LEVEL" -cf "$DAILY_ARCHIVE" $EXCLUDES "$SRC"

# If it's Sunday, create a hard link in weekly
if [ "$(date +%u)" == "7" ]; then
    ln "$DAILY_ARCHIVE" "$WEEKLY_ARCHIVE"
    echo "Weekly backup created: $WEEKLY_ARCHIVE" | tee -a "$LOGFILE"
fi

# If it's the 1st of the month, create a hard link in monthly
if [ "$(date +%d)" == "01" ]; then
    ln "$DAILY_ARCHIVE" "$MONTHLY_ARCHIVE"
    echo "Monthly backup created: $MONTHLY_ARCHIVE" | tee -a "$LOGFILE"
fi

# Cleanup daily backups older than 7 days (but won't delete hard links)
find "$DEST/daily/" -maxdepth 1 -type f -ctime +$RETENTION_DAYS -exec rm -rf {} \;

# Cleanup weekly backups older than 4 weeks
find "$DEST/weekly/" -maxdepth 1 -type f -ctime +$((RETENTION_WEEKS * 7)) -exec rm -rf {} \;

# Cleanup monthly backups older than 6 months
find "$DEST/monthly/" -maxdepth 1 -type f -ctime +$((RETENTION_MONTHS * 30)) -exec rm -rf {} \;

echo "Backup process completed at $(date)" | tee -a "$LOGFILE"
