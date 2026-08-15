# Test Status

**This is the single, current-as-of-today source of truth for test counts
and CI status.** If any other doc (KNOWN_ISSUES.md, either README) states a
different number, this file is correct and the other is stale — file an
issue or fix it on sight rather than trusting the other file's number.

**Last verified:** 2026-08-15, re-run locally in this session (not inferred
from commit messages). Counts before this date (e.g. 210 Flutter / 245
backend) are historical and superseded.

## Release-hardening results

| Check | Result |
| --- | --- |
| Flutter `flutter analyze` | Passed - 0 issues |
| Flutter `flutter test` | Passed - 319 tests |
| Flutter `dart format --set-exit-if-changed lib test scripts/ci` | Passed - 0 files changed |
| Flutter release-source check | Passed |
| Flutter line coverage | 56.62% (7,739/13,669 lines) — CI floor is 50%, see `.github/workflows/ci.yml` |
| Android release manifest processing | Passed |
| Laravel `composer validate` | Passed |
| Laravel `php artisan test` | Passed - 459 tests, 457 passed, 2 MySQL-only skips, 1454 assertions |
| Laravel PHPStan/Larastan | Passed - 0 errors |
| Laravel Pint | Passed |
| Laravel coverage gate | CI floor is 50% (`--min=50`), see `.github/workflows/ci.yml` in the backend repo — not independently measured in this session (no Xdebug/PCOV available locally) |
| SQLite clean migration | Passed - all migrations applied to an in-memory database |
| Database-backed service topology | Passed - migrated `jobs`, `job_batches`, `failed_jobs`, `cache`, `cache_locks`, and `sessions`; the real database driver persisted all application queues (`publishing`, `default`) |
| Database queue + publishing reliability slice | Passed - 49 tests, 233 assertions with database cache, session, and queue environment overrides |
| Docker source hardening test | Passed - 10 tests; validates database worker limits and an independent minutely Scheduler |

## GitHub Actions status

**Not independently confirmed in this session.** The counts above are from
local re-runs (`flutter test`, `php artisan test`), not a GitHub Actions
Combined Status or Workflow Run. Per external report #3 (2026-08-15), do not
treat "N/N tests passing" as CI-verified until an actual Actions run against
the latest commit on both repos is checked, branch protection requiring
those checks is enabled on `main`, and coverage artifacts are confirmed
uploaded.

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
