# Backup Strategy

## Objective
Guarantee recoverability of business-critical publishing data and operational metadata.

## Data Classes
1. Critical
- Users and auth metadata
- Posts and media metadata
- Publish jobs and queue states
2. Important
- Analytics aggregates
- Notifications history
3. Rebuildable
- Cached thumbnails, transient telemetry

## Backup Policy
- Full backup: daily
- Incremental backup: every 15 minutes
- Queue snapshot: every 5 minutes
- Retention: 35 days hot, 180 days cold archive

## Storage
- Primary encrypted object storage
- Secondary region replication
- Immutable backup window enabled (WORM)

## Restore Targets
- RPO: <= 15 minutes
- RTO: <= 60 minutes

## Restore Drill
Run monthly:
1. Restore latest snapshot to staging
2. Replay incremental logs
3. Validate:
   - post counts
   - publish job integrity
   - auth token metadata consistency
4. Sign off by operations lead

## Security Controls
- Encryption at rest and in transit
- Key rotation every 90 days
- Access via least privilege role

## Failure Mode Plan
- If primary backup fails: switch to replicated region backup.
- If both fail: trigger emergency export from live read replicas and incident SEV-1.
