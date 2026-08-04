# Test Status

**Last verified:** 2026-07-30. These are executed results, not inferred
counts.

## Release-hardening results

| Check | Result |
|---|---|
| Flutter `flutter analyze` | Passed - 0 issues |
| Flutter `flutter test` | Passed - 210 tests |
| Flutter `dart format --set-exit-if-changed lib test scripts/ci` | Passed - 0 files changed |
| Flutter release-source check | Passed |
| Android release manifest processing | Passed |
| Laravel `composer validate` | Passed |
| Laravel `php artisan test` | Passed - 245 passed, 2 MySQL-only skips, 855 assertions |
| Laravel PHPStan/Larastan | Passed - 0 errors |
| Laravel Pint | Passed |
| SQLite clean migration | Passed - all migrations applied to an in-memory database |
| Docker source hardening test | Passed - 8 tests, 68 assertions |

## What is covered by the launch-hardening work

- Organization membership permissions in Flutter route guards and Laravel
  policies/controllers: editors are restricted to their own posts/media;
  managers manage the current organization's social accounts/pages; cross-org
  access is denied.
- Persistent, tenant- and recipient-scoped notifications, including
  read-state and publication/approval lifecycle events.
- Exact-attempt publication batches: a post is finalized and a publication
  notification is emitted only after all selected targets settle.
- Android release identity, main-manifest Internet permission, TLS-only
  release traffic, deep-link callback, app icon, and a release-signing gate.
- Production closed-beta target scope: Facebook `page` and Telegram
  `channel` only. Other providers and embedded Instagram Business targets
  are visibly unavailable in Flutter and rejected before attempts/jobs are
  created server-side.
- MySQL/InnoDB claim concurrency, schema indices/FKs, tenant isolation,
  retry/DLQ and circuit-breaker coverage. The race is executed in the MySQL
  CI job, not simulated through SQLite.

## Deliberately unrun locally

- The MySQL race test is skipped under local SQLite; GitHub Actions provides
  MySQL 8.4 for it.
- A signed AAB was not produced: `verifyReleaseSigning` correctly fails
  without `ANDROID_RELEASE_STORE_FILE`, `ANDROID_RELEASE_STORE_PASSWORD`,
  `ANDROID_RELEASE_KEY_ALIAS`, and `ANDROID_RELEASE_KEY_PASSWORD`.
- Docker build/compose and local gitleaks were not run because their CLIs are
  absent in this environment. Both are required CI gates; Docker source
  hardening is covered by the passing Laravel test above.
- No real Facebook Page publish, Meta review, Firebase distribution, or
  production TLS/domain smoke test was possible without external accounts and
  secrets. See `docs/operations/closed_beta_release_checklist.md`.
