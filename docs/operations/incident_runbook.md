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
- Crash Rate Alert: `ops.crash_rate >= 0.02` — **not live.** `MonitoringAlertPolicy` in `lib/src/core/observability/alert_policy.dart` can evaluate this, but nothing ever writes to the `ops.crash_rate` gauge and nothing calls `.evaluate()` — needs a real crash-reporting SDK (Sentry/Crashlytics) wired first, an external-vendor decision, not yet made.
- Publish Failure Rate Alert: `ops.publish_failure_rate >= 0.05` — **live**, backend-side: `app:ops-snapshot` (scheduled every 5 minutes, `routes/console.php`) computes this for real from `PostPublicationAttempt` rows and logs `ops.alert.publish_failure_rate` via `ContextLogger::error()` when breached. Threshold configurable via `config/ops.php`/`OPS_ALERT_PUBLISH_FAILURE_RATE`.
- API Latency Alert: `http.request.duration` average >= `1200ms` — the metric itself IS real (recorded by Flutter's network interceptor), but nothing evaluates or delivers an alert on it yet. Deferred alongside crash rate — same missing-sink problem.
- Queue Length Alert: `ops.queue.length >= 200` — **live**, via `app:ops-snapshot` (counts `pending`/`processing` publication attempts), logs `ops.alert.queue_length`.
- Retry Storm Alert: `ops.retry_storm.count >= 50` — **live**, via `app:ops-snapshot` (counts `retry_scheduled` attempts), logs `ops.alert.retry_storm`.

The "delivery" for the 3 live alerts today is a structured log line (`ContextLogger`) — real and grep-able, but there is still no push notification/paging integration (Slack/PagerDuty/etc.). That's the next step once an on-call tool is chosen; until then, watching the logs for `ops.alert.*` IS the alerting mechanism.

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
