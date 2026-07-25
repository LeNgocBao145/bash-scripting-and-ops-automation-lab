#!/usr/bin/env bash
# restore-test.sh — Verify latest archive by extracting and checking manifest
set -euo pipefail

source "$(dirname "$0")/lib/common.sh"
source /etc/backup.env

: "${DATA_DIR:?data dir required}"
: "${DEST:?destination required}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

find_latest_archive() {
  if [[ "$DEST" == *:* ]]; then
    local remote_host="${DEST%%:*}"
    local remote_path="${DEST#*:}"
    local remote_archive
    remote_archive="$(ssh "$remote_host" "find \"$remote_path\" -maxdepth 1 -type f -name 'backup_*.tar.gz' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-" || true)"
    if [[ -z "$remote_archive" ]]; then
      return 0
    fi
    rsync -az --delete "${remote_host}:${remote_archive}" "$WORK_DIR/"
    printf '%s\n' "$WORK_DIR/$(basename "$remote_archive")"
  else
    find "$DEST" -maxdepth 1 -type f -name 'backup_*.tar.gz' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-
  fi
}

LATEST_ARCHIVE="$(find_latest_archive)"
if [[ -z "$LATEST_ARCHIVE" ]]; then
  log "No backup archive found at destination: $DEST"
  exit 1
fi

log "Found archive: $(basename "$LATEST_ARCHIVE")"

RESTORE_DIR="$WORK_DIR/restore"
mkdir -p "$RESTORE_DIR"
log "Extracting archive..."
tar -xzf "$LATEST_ARCHIVE" -C "$RESTORE_DIR"

MANIFEST_PATH="$RESTORE_DIR/manifest.txt"
DATA_BASENAME="$(basename "$(readlink -f "$DATA_DIR")")"
RESTORED_DATA_DIR="$RESTORE_DIR/$DATA_BASENAME"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  log "Manifest not found in archive: $LATEST_ARCHIVE"
  exit 1
fi

if [[ ! -d "$RESTORED_DATA_DIR" ]]; then
  log "Data directory not found in archive: $DATA_BASENAME"
  exit 1
fi

log "Verifying checksums..."
if ! verify_output="$(cd "$RESTORED_DATA_DIR" && md5sum -c "$MANIFEST_PATH" 2>&1)"; then
  log "Manifest verification failed for $LATEST_ARCHIVE"
  printf '%s\n' "$verify_output"
  exit 1
fi

matched_files="$(printf '%s\n' "$verify_output" | grep -c ': OK$')"
log "Restore test PASSED: ${matched_files} files matched from $(basename "$LATEST_ARCHIVE")"
