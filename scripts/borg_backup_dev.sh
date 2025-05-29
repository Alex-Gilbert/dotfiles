#!/bin/bash
# Simple Borg backup script for dev folder
# Configuration
BACKUP_NAME="dev-backup"
REPOSITORY="/mnt/nas/linux_backup/borg-backup"
export BORG_PASSPHRASE="$(cat /home/alex/.borg-passphrase)"
LOG_FILE="/var/log/borg-backup.log"

echo "Starting dev folder backup at $(date)" | tee -a "$LOG_FILE"

# Create backup
borg create \
    --verbose \
    --stats \
    --progress \
    --compression lz4 \
    --exclude-caches \
    --exclude '**/node_modules' \
    --exclude '**/target' \
    --exclude '**/.git' \
    --exclude '**/build' \
    --exclude '**/dist' \
    $REPOSITORY::$BACKUP_NAME-{now:%Y-%m-%d_%H:%M} \
    /home/alex/dev 2>&1 | tee -a "$LOG_FILE"

# Prune old backups
borg prune \
    --verbose \
    --list \
    --keep-daily=7 \
    --keep-weekly=4 \
    --keep-monthly=6 \
    $REPOSITORY --prefix "$BACKUP_NAME-" 2>&1 | tee -a "$LOG_FILE"

echo "Backup finished at $(date)" | tee -a "$LOG_FILE"
