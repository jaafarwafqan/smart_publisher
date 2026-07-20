# Incident Runbook

## Severity Levels
- SEV-1: Full outage or data loss risk.
- SEV-2: Critical functionality degraded.
- SEV-3: Partial degradation with workaround.

## First 15 Minutes
1. Create incident channel.
2. Assign roles:
   - Incident Commander
   - Communications Lead
   - Operations Lead
3. Freeze deployments.
4. Capture current metrics snapshot and error signatures.

## Triage Checklist
- Is authentication impacted?
- Are publish jobs failing or stuck?
- Is media upload/compression degraded?
- Are canary users only impacted or all users?

## Alert Thresholds (Operational Defaults)
- Crash Rate Alert: `ops.crash_rate >= 0.02`
- Publish Failure Rate Alert: `ops.publish_failure_rate >= 0.05`
- API Latency Alert: `http.request.duration` average >= `1200ms`
- Queue Length Alert: `ops.queue.length >= 200`
- Retry Storm Alert: `ops.retry_storm.count >= 50`

Reference implementation: `lib/src/core/observability/alert_policy.dart`

## Mitigation Playbook
1. Disable risky feature flags.
2. Reduce canary percent to 0.
3. Trigger rollback if error budget is breached.
4. Restart queue workers (backend side) if jobs are stalled.

## Communication Cadence
- Internal updates every 15 minutes.
- External/status page updates every 30 minutes for SEV-1.

## Exit Criteria
- Error rate back to baseline for 30 minutes.
- Queue backlog trend is decreasing.
- No active customer-impacting alerts.

## Post-Incident
- Complete RCA within 48 hours.
- Add automated guardrail for the root cause.
- Update runbook and release checks.
