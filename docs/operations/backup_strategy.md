# Backup Strategy

**Rewritten 2026-07-29** — the previous version of this document described a
backup architecture (incremental backups every 15 minutes, secondary-region
replication, WORM immutable storage, 90-day key rotation, 35/180-day
retention tiers) that has never existed in this project. This rewrite
describes what's actually implemented and was verified live via a real
backup → data-loss → restore drill on 2026-07-29 (see "Restore Drill" below)
— not what a mature SaaS's backup strategy would ideally look like.

## What actually exists
- `php artisan app:backup-database` (`app/Console/Commands/BackupDatabaseCommand.php`):
  - SQLite: `VACUUM INTO` (safe under WAL mode, unlike a raw file copy).
  - MySQL: `mysqldump --single-transaction --routines` (credentials passed via `MYSQL_PWD` env var, never a CLI argument).
  - Output: a single timestamped file under `storage/app/<path>` (`--path`, defaults to `backups`).
- `php artisan app:restore-database {file} {--force}` — SQLite: disconnect + file-swap; MySQL: pipes the dump back through the `mysql` client. Both refuse a `:memory:` connection outright (a file-swap is meaningless there).
- Scheduled: `Schedule::command('app:backup-database')->daily()` in `routes/console.php` — **once a day, full backup only.** There is no incremental/point-in-time capability at all.

## What does NOT exist (real gaps, not silently implied as covered)
- **No offsite/replicated storage.** Every backup lands on the same local disk as the running application. If that disk/server is lost entirely, the backups are lost with it. There is no S3/object-storage upload step, no secondary region.
- **No retention/cleanup policy.** Backups accumulate in `storage/app/backups` forever — nothing prunes old files. On a long-running production server this needs either a manual cleanup cadence or a scheduled prune command (not yet built).
- **No point-in-time recovery.** Because backups are daily-only, the real RPO is "up to ~24 hours of data loss," not the 15-minute RPO the old version of this document claimed.
- **`APP_KEY` is not backed up alongside the database.** `SocialAccount.access_token`/`refresh_token` are `encrypted` casts — a backup file is only decryptable with the exact `APP_KEY` that was active when it was taken. `BackupDatabaseCommand`/`RestoreDatabaseCommand` both print this reminder at runtime, but there's no automated pairing of "this backup file" with "this APP_KEY" — that pairing is currently the operator's manual responsibility.

## Restore Targets (honest, current)
- **RPO: ~24 hours** (daily full backup, no incremental capture between runs).
- **RTO: manual, but fast once triggered** — the restore command itself completes in seconds to low-minutes for this project's current data volume; there is no automated failover, so the real RTO also includes however long it takes a human to notice the outage and run the command.

## Restore Drill — last run 2026-07-29, PASSED
Performed against an isolated, throwaway SQLite database (never the real dev DB, to avoid any risk to existing local data):
1. Fresh-migrated an isolated DB, created a marker user.
2. Ran `app:backup-database` — produced a real backup file.
3. Simulated an "accident" — created an additional user after the backup.
4. Ran `app:restore-database <file> --force`.
5. Verified: the marker user survived, the post-backup "accidental" user was gone, user count matched the pre-accident state exactly.

This proves the backup/restore mechanism itself is correct end-to-end. It does **not** prove recoverability from a total server/disk loss (see "No offsite/replicated storage" above) — that would require an actual off-box copy of a backup file, which isn't automated yet.

## Recommended next steps (not yet implemented — flagged, not silently deferred)
1. Upload each backup to off-box storage (S3-compatible bucket or similar) as part of the scheduled command, so a backup survives losing the server it was taken on.
2. Add a retention/prune step (e.g. keep last N daily backups, delete older).
3. Consider more frequent backups (hourly) once data volume/write rate justifies tightening the ~24h RPO.
4. Document the `APP_KEY` pairing procedure explicitly in a runbook step, not just a command-line reminder.
