#!/bin/bash

# Configuration
SRC="/home/$USER/"  # Source directory (your home folder)
DEST="/mnt/nas/linux_backup"  # Destination on NAS
LOGFILE="/var/log/rclone_backup.log"
THREADS=16  # Adjust based on network speed
RETENTION_DAYS=7
RETENTION_WEEKS=4
RETENTION_MONTHS=6

# Exclusions (large cache files, build artifacts)
EXCLUDES="--exclude='.cache/' --exclude='node_modules/' --exclude='target/'"

# Timestamp for new backup
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
DAILY_PATH="$DEST/daily/$DATE"
WEEKLY_PATH="$DEST/weekly/$DATE"
MONTHLY_PATH="$DEST/monthly/$DATE"

# Ensure backup directories exist
mkdir -p "$DEST/daily" "$DEST/weekly" "$DEST/monthly"

# 🔹 Step 1: Start Backup & Log Time
echo "Backup started at $(date)" | tee -a "$LOGFILE"
START_TIME=$(date +%s)

# 🔹 Step 2: Perform Daily Backup
rclone sync $SRC "$DAILY_PATH" --progress --transfers=$THREADS --checkers=$THREADS --fast-list --buffer-size 512M --use-mmap $EXCLUDES | tee -a "$LOGFILE"

# 🔹 Step 3: Measure Speed & Backup Size
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_SIZE=$(du -sh "$DAILY_PATH" | cut -f1)
SPEED=$(echo "scale=2; $(du -s "$DAILY_PATH" | awk '{print $1}') / $TOTAL_TIME / 1024" | bc)  # MB/s

echo "Backup completed: $TOTAL_SIZE in $TOTAL_TIME seconds (~$SPEED MB/s)" | tee -a "$LOGFILE"

# 🔹 Step 4: Create Weekly & Monthly Snapshots
if [ "$(date +%u)" == "7" ]; then  # Sunday → Weekly backup
    cp -al "$DAILY_PATH" "$WEEKLY_PATH"
    echo "Weekly backup created: $WEEKLY_PATH" | tee -a "$LOGFILE"
fi

if [ "$(date +%d)" == "01" ]; then  # 1st of month → Monthly backup
    cp -al "$DAILY_PATH" "$MONTHLY_PATH"
    echo "Monthly backup created: $MONTHLY_PATH" | tee -a "$LOGFILE"
fi

# 🔹 Step 5: Cleanup Old Backups
echo "Cleaning up old backups..." | tee -a "$LOGFILE"
find "$DEST/daily/" -maxdepth 1 -type d -ctime +$RETENTION_DAYS -exec rm -rf {} \;
find "$DEST/weekly/" -maxdepth 1 -type d -ctime +$((RETENTION_WEEKS * 7)) -exec rm -rf {} \;
find "$DEST/monthly/" -maxdepth 1 -type d -ctime +$((RETENTION_MONTHS * 30)) -exec rm -rf {} \;

echo "Backup process completed --exclude='Downloads/' --exclude='Downloads/' at $(date)" | tee -a "$LOGFILE"
