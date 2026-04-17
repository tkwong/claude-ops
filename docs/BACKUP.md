# S3 backup

Hourly tar+gzip of state files → S3, with a 30-day lifecycle on the bucket.
Drop-in replacement for whatever ad-hoc cron job you'd otherwise write.

## Why S3 (not git, not git-lfs)

Append-only JSON state files (paper trade logs, runtime state, position
snapshots) grow forever. Git history would balloon; git-lfs free tier (1GB
storage / 1GB bandwidth per month) exhausts in days for an active bot.

S3 is cheap, has built-in lifecycle expiry, and survives the EC2 instance
disappearing. Restore = `aws s3 cp` + `tar xzf`.

## Setup (5 minutes)

1. Create a bucket:
   ```bash
   aws s3 mb s3://my-claude-ops-backups
   ```

2. Add a 30-day lifecycle rule:
   ```json
   {
     "Rules": [{
       "ID": "expire-30d",
       "Status": "Enabled",
       "Filter": {"Prefix": ""},
       "Expiration": {"Days": 30}
     }]
   }
   ```
   ```bash
   aws s3api put-bucket-lifecycle-configuration \
     --bucket my-claude-ops-backups \
     --lifecycle-configuration file://lifecycle.json
   ```

3. (EC2 only — recommended) Attach an IAM instance role with
   `s3:PutObject` on `my-claude-ops-backups/*`. Then no credentials needed.

4. Write a backup config:
   ```bash
   # ~/myagent.backup.conf
   BUCKET="s3://my-claude-ops-backups"
   SOURCE_DIR="$HOME/myagent"
   PATTERNS=("*.json" "state.json" "data/*.csv")
   PREFIX="myagent"
   ```

5. Add cron:
   ```bash
   (crontab -l; echo "0 * * * * BACKUP_CONF=$HOME/myagent.backup.conf $HOME/claude-ops/lib/backup-to-s3.sh") | crontab -
   ```

6. Verify after first run:
   ```bash
   tail /tmp/backup.log
   aws s3 ls s3://my-claude-ops-backups/myagent/
   ```

## Restore

```bash
# Find latest
aws s3 ls s3://my-claude-ops-backups/myagent/ --recursive | tail -1

# Pull and unpack
aws s3 cp s3://my-claude-ops-backups/myagent/2026-04-17-15/backup.tar.gz /tmp/
cd /tmp && tar tzf backup.tar.gz       # inspect
cd "$HOME/myagent" && tar xzf /tmp/backup.tar.gz
```

## Layout in the bucket

```
s3://my-claude-ops-backups/
└── myagent/
    ├── 2026-04-17-14/backup.tar.gz
    ├── 2026-04-17-15/backup.tar.gz
    └── ...
```

One agent prefix per project lets you back up multiple agents into one bucket.
