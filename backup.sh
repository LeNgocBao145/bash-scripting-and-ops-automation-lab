#!/usr/bin/env bash
# backup.sh — Archive data with manifest, transfer, rotate, and alert
set -euo pipefail

source "$(dirname "$0")/lib/common.sh"
source /etc/backup.env

: "${DATA_DIR:?data dir required}"
: "${ALERT_TO:?alert recipient required}"
: "${DEST:?destination required}"
: "${RETAIN_DAYS:?retain days required}"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"
WORK_DIR="$(mktemp -d)"
ARCHIVE_PATH="${WORK_DIR}/${ARCHIVE_NAME}"
DATA_DIR_ABS="$(readlink -f "$DATA_DIR")"
DATA_PARENT="$(dirname "$DATA_DIR_ABS")"
DATA_BASENAME="$(basename "$DATA_DIR_ABS")"

cleanup() {
  local exit_code="$?"
  if [[ "$exit_code" -ne 0 ]]; then
    send_alert "BACKUP FAILED" "Backup failed with exit code ${exit_code}. Destination: ${DEST}"
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

write_manifest() {
  log "Writing manifest for ${DATA_DIR_ABS}..."
  (
    cd "$DATA_DIR_ABS"
    find . -type f -exec md5sum {} +
  ) > "${WORK_DIR}/manifest.txt"
}

create_archive() {
  log "Creating archive ${ARCHIVE_NAME}..."
  tar -czf "$ARCHIVE_PATH" \
    --exclude='*.log' \
    --exclude='*.tmp' \
    -C "$DATA_PARENT" "$DATA_BASENAME" \
    -C "$WORK_DIR" manifest.txt
}

transfer_archive() {
  log "Transferring ${ARCHIVE_NAME} to ${DEST}..."
  if [[ "$DEST" != *:* ]]; then
    mkdir -p "$DEST"
  fi
  rsync -az --delete "$ARCHIVE_PATH" "$DEST"
}

rotate_archives() {
  log "Rotating archives older than ${RETAIN_DAYS} days in ${DEST}..."
  if [[ "$DEST" == *:* ]]; then
    local remote_host="${DEST%%:*}"
    local remote_path="${DEST#*:}"
    ssh "$remote_host" "find \"$remote_path\" -type f -name 'backup_*.tar.gz' -mtime +${RETAIN_DAYS} -delete"
  else
    find "$DEST" -type f -name 'backup_*.tar.gz' -mtime +"$RETAIN_DAYS" -delete
  fi
}

write_manifest
create_archive
transfer_archive
rotate_archives

archive_size="$(du -h "$ARCHIVE_PATH" | awk '{print $1}')"
send_alert "Backup OK" "Archive: ${ARCHIVE_NAME} (${archive_size}) to ${DEST}"
log "Backup OK: ${ARCHIVE_NAME} (${archive_size}) -> ${DEST}"
