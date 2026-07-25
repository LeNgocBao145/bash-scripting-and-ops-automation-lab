# How to run and setup Homework — Bash Scripting & Ops Automation

Operational Bash scripts for Linux server monitoring and backup automation.

## Project Structure

```text
web01-ops/
├── health-check.sh      # Check disk, RAM, services, and HTTP endpoint
├── backup.sh            # Create archive + manifest, transfer, and rotate old backups
├── restore-test.sh      # Extract latest archive and verify manifest checksums
├── lib/common.sh        # Shared log(), send_alert(), and on_error() helpers
├── cron/web01-ops.cron  # Example crontab entries
├── examples/            # Environment file templates
└── REPORT.md            # Lab evidence/screenshots
```

## Requirements

- Linux with Bash
- `curl`, `rsync`, `tar`, `find`, `md5sum`, `mail`, `systemctl`
- Write permission for log locations
- If using remote backup destination: SSH key-based access to remote host

## Setup

1. Clone and make scripts executable:

```bash
git clone <repo> /opt/web01-ops
chmod +x /opt/web01-ops/*.sh
```

2. Create environment files in `/etc` (required by scripts):

```bash
sudo cp /opt/web01-ops/examples/monitoring.env.example /etc/monitoring.env
sudo cp /opt/web01-ops/examples/backup.env.example     /etc/backup.env
sudo chmod 600 /etc/monitoring.env /etc/backup.env
# Edit both files with real values
```

3. Ensure log directories exist (matching your env/cron config):

```bash
sudo mkdir -p /var/log/web01-ops
sudo touch /var/log/web01-ops.log /var/log/web01-ops/health-check.log /var/log/web01-ops/backup.log
```

4. Install cron jobs:

```bash
crontab /opt/web01-ops/cron/web01-ops.cron
```

## Manual Run

```bash
/opt/web01-ops/health-check.sh
/opt/web01-ops/backup.sh
/opt/web01-ops/restore-test.sh
```

## Environment Variables

### `/etc/monitoring.env`

| Variable | Description |
|---|---|
| `DISK_THRESHOLD` | Alert when root disk usage (`/`) is greater than or equal to this percent |
| `RAM_MIN_FREE` | Alert when free RAM percent is below this value |
| `SERVICES` | Space-separated systemd service names to check |
| `HEALTH_URL` | HTTP URL for liveness check |
| `ALERT_TO` | Email recipient for alerts (leave empty to disable email) |
| `LOG_FILE` | Log file path used by `lib/common.sh` |
| `ENABLE_TRAP_TEST` | Set to `1` to intentionally trigger trap test in `health-check.sh` |

### `/etc/backup.env`

| Variable | Description |
|---|---|
| `DATA_DIR` | Source directory to archive |
| `DEST` | Backup destination: local path or `user@host:/path` |
| `RETAIN_DAYS` | Delete `backup_*.tar.gz` older than this many days |
| `ALERT_TO` | Email recipient for backup alerts |
| `LOG_FILE` | Log file path used by `lib/common.sh` |

## Notes

- `backup.sh` excludes `*.log` and `*.tmp` from the archive.
- `restore-test.sh` verifies the latest backup archive by checking `manifest.txt` with `md5sum -c`.
- Failed backup runs trigger `BACKUP FAILED` alert via trap in `backup.sh`.
