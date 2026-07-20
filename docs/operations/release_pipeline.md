# Release Pipeline

## Objective
Provide a repeatable release process for stable and canary channels.

## Trigger
Use GitHub Actions workflow: `.github/workflows/release.yml`.

## Inputs
- `release_channel`: `stable` or `canary`.
- `canary_percent`: integer from 0 to 100.
- `rollback_to`: optional release tag for rollback execution.

## Build Steps
1. `flutter pub get`
2. `flutter build appbundle --release`
3. `flutter build web --release`
4. Upload build artifacts to pipeline storage.

## Deploy Steps
1. Attach metadata (`release_channel`, `canary_percent`, git SHA).
2. Deploy artifacts to distribution target.
3. Verify health metrics for 30 minutes before promotion.

## Promotion Gates
- Crash-free sessions >= 99.5%
- API error rate <= 1%
- Publish success rate >= 98%
- P95 publish latency does not regress by more than 10%

## Rollback Trigger Conditions
- Crash-free sessions drops below 99%
- P95 API latency > 2x baseline for 10 minutes
- Queue failure rate > 5% for 10 minutes

## Environment Variables
- `SP_RELEASE_CHANNEL`
- `SP_CANARY_PERCENT`
- `SP_API_BASE_URL`
- `SP_AUTH_BASE_URL`

## CI/CD Secrets Required
- `FIREBASE_APP_ID_ANDROID`
- `FIREBASE_TOKEN`
- `FIREBASE_TESTER_GROUPS` (optional, default: `qa`)
- `WEB_DEPLOY_TARGET` (optional)

## Pipeline Notes
- The release workflow executes a pre-release quality gate (`analyze + test`) before build.
- A `release-manifest.json` is generated and archived with release artifacts.
- Deployment logic is centralized in `scripts/release/deploy_release.sh`.
