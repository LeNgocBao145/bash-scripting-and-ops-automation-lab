# web01-ops

Operational scripts for a Linux web server: health monitoring, backup, and restore testing.

## Structure

```
web01-ops/
├── health-check.sh      # Monitor HTTP, disk, CPU, memory
├── backup.sh            # Backup data + manifest, transfer, rotate old archives
├── restore-test.sh      # Extract latest archive and verify manifest checksums
├── lib/common.sh        # Shared log() and send_alert()
├── cron/web01-ops.cron  # Crontab entries
├── examples/            # .env templates
└── REPORT.md            # Acceptance evidence
```

## Setup

**1. Clone / copy to server**
```bash
git clone <repo> /opt/web01-ops
chmod +x /opt/web01-ops/*.sh
```

**2. Configure environments**
```bash
cp examples/monitoring.env.example /opt/web01-ops/monitoring.env
cp examples/backup.env.example     /opt/web01-ops/backup.env
# Edit both files with your values
```

**3. Install cron**
```bash
crontab /opt/web01-ops/cron/web01-ops.cron
```

## Manual Run

```bash
# Health check
bash /opt/web01-ops/health-check.sh

# Backup
bash /opt/web01-ops/backup.sh

# Restore test
bash /opt/web01-ops/restore-test.sh
```

## Environment Variables

See `examples/monitoring.env.example` and `examples/backup.env.example` for all variables.

| Variable | Used in | Description |
|----------|---------|-------------|
| `HTTP_URL` | health-check | URL to probe |
| `DISK_THRESHOLD` | health-check | Alert if disk % ≥ value |
| `CPU_THRESHOLD` | health-check | Alert if CPU % ≥ value |
| `MEM_THRESHOLD` | health-check | Alert if memory % ≥ value |
| `ALERT_TO` | common.sh / backup | Recipient for email alerts |
| `SLACK_WEBHOOK` | common.sh | Slack incoming webhook URL |
| `DATA_DIR` | backup / restore | Directory to archive |
| `DEST` | backup / restore | Backup destination (local path or user@host:/path) |
| `RETAIN_DAYS` | backup | Delete archives older than this number of days |
