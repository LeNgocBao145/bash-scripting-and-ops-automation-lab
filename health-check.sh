#!/usr/bin/env bash
# health-check.sh — Monitor web service, disk, CPU, memory
set -euo pipefail

source "$(dirname "$0")/lib/common.sh"
source /etc/monitoring.env

ALERTS=()

add_alert() {
  ALERTS+=("$1")
}

trap 'on_error $LINENO "$BASH_COMMAND"' ERR

run_error_trap_test() {
  if [[ "${ENABLE_TRAP_TEST:-0}" == "1" ]]; then
    tar -czf out.tgz /no/such/dir
    log "Running ERR trap test with a real failing command..."
    log "UNREACHABLE: this line must not run"
  fi
}

check_disk() {
  local usage
  log "Checking disk usage..."
  if ! usage=$(df / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'); then
    add_alert "Root filesystem usage could not be read"
    return
  fi
  log "Disk usage: ${usage}% (threshold: ${DISK_THRESHOLD}%)"
  if (( usage >= DISK_THRESHOLD )); then
    add_alert "Root filesystem usage ${usage}% >= ${DISK_THRESHOLD}%"
  fi
}

check_mem() {
  local free_percent
  log "Checking memory..."
  if ! free_percent=$(free | awk '/^Mem:/ {if ($2 > 0) printf "%.0f", ($7 * 100) / $2; else print 0}'); then
    add_alert "Free RAM could not be read"
    return
  fi
  log "Free RAM: ${free_percent}% (min: ${RAM_MIN_FREE}%)"
  if (( free_percent < RAM_MIN_FREE )); then
    add_alert "Free RAM ${free_percent}% < ${RAM_MIN_FREE}%"
  fi
}

check_services() {
  local service
  log "Checking services: ${SERVICES}..."
  for service in $SERVICES; do
    if ! systemctl is-active --quiet "$service"; then
      add_alert "Service $service is not active"
    else
      log "Service ${service}: active"
    fi
  done
}

check_http() {
  log "Checking HTTP: ${HEALTH_URL}..."
  if ! curl -sf --max-time 5 "$HEALTH_URL" >/dev/null; then
    add_alert "URL $HEALTH_URL is not responding"
  else
    log "HTTP OK: ${HEALTH_URL}"
  fi
}

run_error_trap_test
check_disk
check_mem
check_services
check_http

if (( ${#ALERTS[@]} > 0 )); then
  send_alert "Health check findings" "Hostname: $(hostname)

$(printf '%s
' "${ALERTS[@]}")"
else
  log "Health check PASSED: all checks OK"
fi

exit 0
