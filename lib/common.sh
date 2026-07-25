#!/usr/bin/env bash
# lib/common.sh — Shared utilities

LOG_FILE="${LOG_FILE:-/var/log/web01-ops.log}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

send_alert() {
  local subject="$1"
  local body="$2"
  local host

  host="$(hostname)"
  log "ALERT [$subject] $body"

  if [[ -n "${ALERT_TO:-}" ]]; then
    printf '%s\n' "$body" | mail -s "[web01-ops][$host] $subject" "$ALERT_TO"
  else
    log "ALERT_TO is empty; skipping email delivery"
  fi
}

# detailed handler: line + command + exit code
on_error() {
    local exit=$? line=$1 cmd=$2
    local body="Line: $line
Cmd:  $cmd
Exit: $exit
Host: $(hostname)"
    send_alert "SCRIPT FAILED" "$body"
}