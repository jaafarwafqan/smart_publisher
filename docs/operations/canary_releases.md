# Canary Releases

## Objective
Reduce release risk by exposing new build/features to a controlled user subset.

## Runtime Controls
- `SP_RELEASE_CHANNEL=canary`
- `SP_CANARY_PERCENT=<0..100>`
- Feature flag: `canary_publish_pipeline`

## How It Works
1. App includes channel metadata headers:
   - `X-Release-Channel`
   - `X-Canary-Percent`
2. Canary-only feature flags use deterministic user bucketing.
3. If canary metrics degrade, reduce percent or disable canary feature flag immediately.

## Rollout Plan
1. 5% for 30 minutes
2. 15% for 60 minutes
3. 30% for 2 hours
4. 50% for 4 hours
5. 100% and promote to stable

## Abort Conditions
- Error budget burn rate breach
- Queue failure spikes
- Auth refresh failures increase > 2x baseline

## Observability Requirements
Track by release channel:
- HTTP error rate
- publish job success/failure ratio
- queue retry rate
- app startup and publish latency percentiles
