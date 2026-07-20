# Rollback Strategy

## Scope
Rollback applies to mobile release artifacts, web static bundle, and backend-release channel routing metadata.

## Preconditions
- Incident severity confirmed (SEV-1 or SEV-2).
- Incident commander assigned.
- Target rollback version identified (tag or build number).

## Fast Rollback Procedure
1. Stop progressive rollout (set canary to 0%).
2. Re-point traffic to previous stable release.
3. Disable risky flags:
   - `SP_FF_CANARY_PUBLISH_PIPELINE=false`
   - `SP_FF_PERFORMANCE_DASHBOARD=false` (optional)
4. Validate core user journey:
   - login
   - create post
   - media upload
   - publish job creation
5. Announce rollback completion in incident channel.

## Data Safety
- Do not run destructive migrations during rollback.
- Preserve queue jobs and replay after stabilization.
- Keep audit logs for all rollback commands.

## Verification Checklist
- Error rate back to baseline
- Crash-free sessions recovered
- Queue retry/dead-letter growth stabilized

## Post-Rollback
- Freeze new deployments until RCA is complete.
- Create remediation tasks and owner assignment.
