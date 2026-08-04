# Closed-Beta Release Pipeline

The release workflow is intentionally Android-only.  It produces a signed AAB
and distributes it through Firebase App Distribution to the configured closed
beta tester group.  It does not claim to deploy a web site, a backend, a
canary, or a rollback target that has not been configured.

## Trigger and gates

Run `.github/workflows/release.yml` manually with the only permitted channel:
`closed-beta`.  The workflow fails before artifact creation unless all of the
following succeed:

1. Gitleaks, source hardening, formatting, `flutter analyze`, Android release
   configuration regression tests, and the Flutter suite.
2. Materialization of an ephemeral Android release keystore and Gradle's
   `verifyReleaseSigning` gate.
3. `flutter build appbundle --release`.
4. Firebase App Distribution with non-empty `FIREBASE_APP_ID_ANDROID`,
   `FIREBASE_TOKEN`, and `FIREBASE_TESTER_GROUPS` secrets.

There is no debug-keystore fallback and no "skip deployment if secrets are
missing" branch.  A missing secret fails the workflow.

## Required GitHub secrets

- `ANDROID_RELEASE_KEYSTORE_BASE64`
- `ANDROID_RELEASE_STORE_PASSWORD`
- `ANDROID_RELEASE_KEY_ALIAS`
- `ANDROID_RELEASE_KEY_PASSWORD`
- `FIREBASE_APP_ID_ANDROID`
- `FIREBASE_TOKEN`
- `FIREBASE_TESTER_GROUPS`

The keystore secret is decoded only into the ephemeral GitHub runner and is
never uploaded as an artifact.  Do not add it, any `.env`, access token, or
signing password to source control.

Required GitHub configuration variables (not secrets, but still deployment
controlled) are `SP_API_BASE_URL`, `SP_AUTH_BASE_URL`, and
`SP_OAUTH_BASE_URL`. The workflow rejects an empty or non-HTTPS value and
passes all three as Dart defines; a release app also refuses to start if it
falls back to a localhost HTTP endpoint.

## Evidence after distribution

Archive the generated `release-manifest.json`, GitHub run URL, AAB version and
SHA-256, Firebase release link, named tester group, and the results of the
staging smoke test in `closed_beta_release_checklist.md`.  Do not archive
credentials or raw tokens.

## Backend deployment boundary

This Flutter workflow does not deploy Laravel.  The deployment owner must
separately provision the HTTPS staging/production backend, MySQL/InnoDB,
queue worker, scheduler, environment secrets, migrations, monitoring, and
rollback capability before external invitations.
