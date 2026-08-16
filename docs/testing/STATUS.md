# Test Status

**This is the single, current-as-of-today source of truth for test counts
and CI status.** If any other doc (KNOWN_ISSUES.md, either README) states a
different number, this file is correct and the other is stale — file an
issue or fix it on sight rather than trusting the other file's number.

**Last verified:** 2026-08-16, re-run locally in this session (not inferred
from commit messages), plus independently confirmed via real GitHub Actions
runs (see below — this was previously an open caveat, now closed). Counts
before 2026-08-15 (e.g. 210 Flutter / 245 backend) are historical and
superseded.

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
| Laravel `php artisan test` | Passed - 469 tests, 467 passed, 2 MySQL-only skips, 1498 assertions |
| Laravel PHPStan/Larastan | Passed - 0 errors |
| Laravel Pint | Passed |
| Laravel coverage gate | CI floor is 50% (`--min=50`), see `.github/workflows/ci.yml` in the backend repo — not independently measured locally in this session (no Xdebug/PCOV available locally; CI itself does measure and enforce it) |
| SQLite clean migration | Passed - all migrations applied to an in-memory database |
| Database-backed service topology | Passed - migrated `jobs`, `job_batches`, `failed_jobs`, `cache`, `cache_locks`, and `sessions`; the real database driver persisted all application queues (`publishing`, `default`) — and (2026-08-16) confirmed live on Render staging, not just in tests: see the incident note below |
| Database queue + publishing reliability slice | Passed - 49 tests, 233 assertions with database cache, session, and queue environment overrides |
| Docker source hardening test | Passed - 10 tests; validates database worker limits and an independent minutely Scheduler |

## GitHub Actions status

**Independently confirmed** via `gh run list`/`gh api` against the real
Actions API for both repos across multiple pushes this session (not
inferred from source or commit messages) — every push landing on `main`
during this session's work (backend `91ca0da`, `ffc2625`; frontend
`9404265`, `a1c76f1`, `8324f5f`) produced a `completed`/`success` CI run.
This closes the previous open caveat that "N/N tests passing" wasn't
CI-verified. Still not independently confirmed: branch-protection
enforcement of these checks on `main`, and coverage-artifact upload
correctness beyond the gate passing.

## 2026-08-16 incident: real staging outage found, fixed, and verified live

Not a source-code finding — a live-topology configuration incident on the
already-deployed Render staging environment, found and fixed in the same
session:

- **Root cause**: Auto-Deploy (confirmed on for all three backend Render
  services, `autoDeployTrigger: commit`) had already shipped `main`'s
  Redis-removal refactor (`79ecc92`) to Render, but `CACHE_STORE`/
  `SESSION_DRIVER`/`QUEUE_CONNECTION` were still set to `redis` directly on
  the Web service (overriding the correct `database` values already present
  in a linked Environment Group) — the deployed image no longer bundled a
  Redis client at all, so every request path touching cache or session threw
  `Class "Redis" not found` and surfaced as a generic 500. Reproduced via
  public HTTP probes (`/legal/*`, `/auth/login`, `/`) and confirmed from a
  real Render Logs excerpt the user provided (`PhpRedisConnector.php:80`).
- **Fix**: removed the conflicting service-level env vars so the linked
  Environment Group's `database` values took effect; verified via repeated
  clean `/up`/`/legal/privacy-policy`/`/auth/login` checks post-fix.
- **A second, unrelated bug found the same day**: the staging web build's
  CSP (both the `<meta>` tag and the separate HTTP header pasted into
  Render's Settings → Headers) never allow-listed `www.gstatic.com`/
  `fonts.gstatic.com`, so Flutter Web's own CanvasKit renderer and Roboto
  font were blocked outright — a real blank white page on every load,
  reproduced live in the browser console. Fixed in both CSP sources
  (`web/index.html` meta tag, `render.yaml`'s documented header value, plus
  the live Render dashboard header the user updated by hand); confirmed via
  a fresh Incognito load with a clean console.
- **A third bug found via a real Telegram connect attempt**: `SocialAccount`
  enforces `(provider, provider_account_id)` uniqueness platform-wide, but
  the "already linked?" check and `updateOrCreate()` match clause are
  implicitly scoped to the caller's own organization — a bot already linked
  to a *different* organization was invisible to that scoped lookup, so the
  INSERT collided with the real constraint and surfaced as an uncaught 500.
  Fixed (`ffc2625`) with a clear 422 instead, mirroring the existing
  SQLSTATE-23000 guard pattern in `PostController`/`MediaLibraryController`.
  The specific conflicting row (a stale demo-org connection from the
  original 2026-08-11 staging setup) was deleted via the normal
  authorized user-facing delete endpoint, not a direct DB bypass.
- **End-to-end live verification after all three fixes**: real admin login,
  draft creation, a real media upload round-tripped through Cloudflare R2
  (uploaded via Web, read back byte-for-byte via a signed URL), a real
  Telegram bot connect, and a real `publish-now` to the real
  `@UOK_Faculty_Nursing` channel — reached `published` on the first attempt,
  no new `dead_letter_jobs` entry, cleaned up (post deleted, channel message
  deleted by the user) after the user visually confirmed it appeared.

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
