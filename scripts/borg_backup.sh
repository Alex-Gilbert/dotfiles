#!/bin/bash
# Comprehensive Borg backup script for Arch Linux

# Configuration
BACKUP_NAME="arch-$(hostname)"
REPOSITORY="/mnt/nas/linux_backup/borg-backup"
export BORG_PASSPHRASE="$(cat /home/alex/.borg-passphrase)"
LOG_FILE="/var/log/borg-backup.log"

echo "Starting backup at $(date)" | tee -a "$LOG_FILE"

# Create backup
borg create \
    --verbose \
    --stats \
    --compression lz4 \
    --exclude-caches \
    --exclude '/home/*/.cache/*' \
    --exclude '/home/*/.local/share/Trash/*' \
    --exclude '/home/*/go' \
    --exclude '/home/*/cargo' \
    --exclude '/home/**/node_modules' \
    --exclude '/var/cache/*' \
    --exclude '/var/tmp/*' \
    --exclude '/proc/*' \
    --exclude '/sys/*' \
    --exclude '/dev/*' \
    --exclude '/run/*' \
    --exclude '/mnt/*' \
    --exclude '/media/*' \
    $REPOSITORY::$BACKUP_NAME-{now:%Y-%m-%d_%H:%M} \
    /etc \
    /home \
    /root \
    /var/lib/pacman \
    /var/lib/systemd \
    /boot 2>&1 | tee -a "$LOG_FILE"

# Save list of installed packages
mkdir -p /var/lib/backup-data
pacman -Qeq > /var/lib/backup-data/pacman-packages.txt

borg create \
    --verbose \
    --stats \
    --compression lz4 \
    $REPOSITORY::$BACKUP_NAME-pkg-list-{now:%Y-%m-%d_%H:%M} \
    /var/lib/backup-data/pacman-packages.txt 2>&1 | tee -a "$LOG_FILE"

# Prune old backups
borg prune \
    --verbose \
    --list \
    --keep-daily=7 \
    --keep-weekly=4 \
    --keep-monthly=6 \
    $REPOSITORY 2>&1 | tee -a "$LOG_FILE"

echo "Backup finished at $(date)" | tee -a "$LOG_FILE"
