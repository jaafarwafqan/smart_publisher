# Test Status

**This is the single, current-as-of-today source of truth for test counts
and CI status.** If any other doc (KNOWN_ISSUES.md, either README) states a
different number, this file is correct and the other is stale — file an
issue or fix it on sight rather than trusting the other file's number.

**Last verified:** 2026-08-16 (continued session — Phase 3 webhook receiver,
a Phase 1 Flutter/backend gap audit, then a Phase 5 UI/UX token-discipline
audit), re-run locally in this session (not inferred from commit messages).
The GitHub Actions confirmation below is from earlier the same day and has
not been re-checked against this session's new commits yet — see the
Instagram/X, webhook-receiver, Phase-1-audit, and Phase-5-audit entries
further down. Counts before 2026-08-15 (e.g. 210 Flutter / 245 backend) are
historical and superseded.

## Release-hardening results

| Check | Result |
| --- | --- |
| Flutter `flutter analyze` | Passed - 0 issues |
| Flutter `flutter test` | Passed - 363 tests |
| Flutter `dart format --set-exit-if-changed lib test scripts/ci` | Passed - 0 files changed |
| Flutter release-source check | Passed |
| Flutter line coverage | Not re-measured this session; last measured 56.62% (7,739/13,669 lines) — CI floor is 50%, see `.github/workflows/ci.yml` |
| Android release manifest processing | Passed |
| Laravel `composer validate` | Passed |
| Laravel `php artisan test` | Passed - 510 tests, 507 passed, 3 skipped (2 MySQL-only + 1 opt-in Instagram sandbox), 1611 assertions |
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
during this session's work produced a `completed`/`success` CI run,
through backend `a05c442` and frontend `41c0ec0`. This closes the previous
open caveat that "N/N tests passing" wasn't CI-verified.

**Coverage-artifact upload correctness — checked and a real bug fixed**:
the backend's "Upload coverage artifact" step had silently uploaded
nothing on every run (neither `phpunit.xml` nor the test command ever told
PHPUnit where to write a report; `continue-on-error: true` masked the
resulting failure) — confirmed via the real Actions API artifact list, not
assumed. Fixed backend `0945548` (CI-only `--coverage-html`/
`--coverage-clover` flags; deliberately not added to `phpunit.xml` — that
approach was tried first and reproducibly crashed every plain local
`php artisan test` run with zero output on a machine without Xdebug/PCOV,
reverted). Verified: the next run produced a real 2.69MB HTML+Clover
artifact. First real measured backend coverage: **80.9% statements**
(4639/5734) — the CI floor was raised 50% → 75% accordingly (`a05c442`,
deliberately below the measured number, not at it).

**Branch-protection enforcement of these checks on `main` — done and
verified.** A GitHub Ruleset named "main" is `active` on both repos
(created by the user in the GitHub UI — this sandbox's own tooling policy
blocks agent-side GitHub Settings writes, same class of restriction that
blocked a direct Render env-var change earlier this session). Verified via
the real API (`gh api repos/.../rulesets/{id}`, not just the list endpoint)
after catching and having the user fix one real mistake — the first
attempt had non-existent status-check context names (`"Flutter repo"`,
`"MySQL"`) that would never have been satisfied by anything. Final state:
Flutter repo requires `quality-gate`; backend repo requires `quality-gate`
and `MySQL 8.4 publishing reliability`; both also block force pushes and
branch deletion; both bypass the repository-admin role so the existing
direct-push-to-`main` workflow is unaffected.

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

## 2026-08-16 (continued): Instagram Business + X (Twitter) platform work

Real code, not a facade — see `docs/api/integrations.md` for the full
provider table. Summary:

- **Instagram Business**: `InstagramProvider` makes real Content Publishing
  API calls (container create → poll → publish; single image/video/carousel;
  honest rejection of a text-only post, matching Instagram's real
  constraint). `FacebookOAuthProvider::listPages()`'s linked
  `instagram_business_account` entry now carries the parent Page's real
  access token (was `null`) since that's the token Instagram publishing
  actually authenticates with. `PublishEngineService`,
  `ClosedBetaPublishingGate`, and `PostMetricsSyncService` all dispatch by
  `SocialPage.kind`, not just the parent `SocialAccount.provider`, since an
  `instagram_business` page's account is still `provider: 'facebook'`.
  `'instagram'` joined `SocialOAuthManager::CLOSED_BETA_PROVIDERS`.
- **X (Twitter)**: `XOAuthProvider` — real OAuth 2.0 + PKCE (the
  `code_verifier`/`code_challenge` pair is generated and cached entirely
  server-side), Tweet v2 publish (text-only this release), refresh,
  app-credential test, health check, metrics. Deliberately **not** added to
  `CLOSED_BETA_PROVIDERS` — write access needs a paid X API tier that has
  not been live-verified against a real account.
- **WhatsApp**: explicitly deferred by the user this session — the Cloud
  API sends to one fixed recipient number, not a broadcast surface, and
  doesn't fit this app's publish model without a template/recipient-list
  feature that doesn't exist yet. No change from its existing "real
  OAuth/discovery, `publishPost()` unimplemented" state.
- **Automated coverage**: backend 495 tests (492 passed, 3 skipped — 2
  MySQL-only + 1 new opt-in `InstagramSandboxE2ETest`), Pint clean, PHPStan
  0 errors. Flutter 340 tests, `flutter analyze` 0 issues, `dart format`
  clean.
- **Live verification: DONE — a real Instagram publish reached `published`
  on staging, after finding and fixing two real bugs in the process.**
  Deployed to Render staging, confirmed the real "قلوب تنتظر النور"
  Facebook Page has a linked Instagram Business Account
  (`qolob_tantather_alnoor`, discovered correctly after Sync Pages),
  created a real draft with one real R2-hosted image targeting it,
  `publish-now`.
  - **Bug 1** (attempt 1): landed in `dead_letter_jobs` with a real Meta
    error — `(#10) Application does not have permission for this action`
    on Instagram's container-create call. Root cause: the Facebook OAuth
    scope list (`_facebookOAuthScopes` in `account_repository_impl.dart`,
    mirrored in `FacebookNativeLoginService.permissions`) only ever
    requested `pages_show_list`/`pages_read_engagement`/
    `pages_manage_posts` — enough to *discover* the linked Instagram
    account but not to *publish* to it. Fixed by adding
    `instagram_basic`/`instagram_content_publish` to both scope lists
    (frontend `580d918`, backend `1e728b6`). Required reconnecting Facebook
    (Disconnect, then Connect again) to mint a token with the new scopes —
    also required the operator to add the Instagram product and fix
    App Domains / Valid OAuth Redirect URIs in the Meta App Dashboard,
    which are external configuration, not code.
  - **Bug 2** (attempt 2, after the scope fix): landed in `dead_letter_jobs`
    again with a different real Meta error — `"Media ID is not available"`
    (code 9007, subcode 2207027) on `media_publish`. Root cause:
    `InstagramProvider` only polled a container's `status_code` before
    publishing for *video* containers, on the wrong assumption that an
    image container is always processed instantly — it isn't guaranteed to
    be. Fixed (`b99229b`) by moving the poll into `publishContainer()`
    itself so it runs before every publish call, regardless of media type;
    added a regression test mirroring the existing video-polling test.
  - **Attempt 3: success.** Post reached `status: published`,
    `published_at` set, zero new `dead_letter_jobs` entries. Confirmed
    directly via the real staging API (not just the Flutter UI's success
    toast, which — as both bugs above prove — only confirms the job was
    *queued*, not that the attempt actually settled successfully).
  - **Follow-up UX fix** (same session): the Instagram entry in Flutter's
    accounts list is a local placeholder never touched by
    `_mergeRemoteAccounts()` (an `instagram_business` page's
    `SocialAccountResponseDtoV1` still carries `provider: 'facebook'` —
    Instagram has no OAuth of its own), so it stayed permanently
    `disconnected` even after this real, verified publish — a real,
    reported point of user confusion. Fixed with
    `_deriveInstagramStatusFromFacebookPages()`: the Instagram card now
    shows a distinct "Connected via Facebook" state (green, read-only, no
    Disconnect/Refresh/Test/pages-panel actions — those stay a single
    source of truth under the Facebook card) whenever the Facebook account
    actually has a linked Instagram Business page.
  - X still has no live test this session — its automated PKCE round-trip
    test (`SocialAccountOAuthTest`) is the extent of its verification for
    now.

## 2026-08-16 (continued): Phase 1 audit — Flutter/backend gap

Per the original production-readiness plan's Phase 1 ("Implement every
Repository Interface... against the real Laravel API"): audited the current
frontend against `docs/api/openapi_v1.yaml` and the live-verified evidence
already in this document. **Most of Phase 1 was already real and done**,
contrary to the plan's premise that the frontend was "stuck at early
architectural scaffolding" — that premise predates the 2026-08-09/2026-08-16
work documented above and in `README.md`. Confirmed already real: every
feature's Repository implementation calling the actual Laravel API (not a
`SocialPlatform` abstraction — that was deliberately deleted, see
`docs/architecture/decisions/0001-repository-riverpod-not-cqrs.md`), DTOs/
mappers in `lib/src/backend_contracts/v1/`, the `X-Organization-Id` header
attached automatically (`network_interceptor.dart`), an organization
switcher (`organization_switcher_screen.dart`), Sanctum bearer + refresh
rotation, and Facebook/Telegram publish/approve/reject all wired and
live-verified per the entries above.

**Two real, concrete gaps were found and fixed** — see
`docs/architecture/decisions/0007-persistent-local-caches-for-drafts-and-analytics.md`
for the full design:

- `DraftStorage` was wired into `PostRepositoryImpl` but was in-memory-only
  and its own read methods were never called by anything — reads went
  through a second, separate, equally non-persistent field instead. A post
  created/edited while offline was gone from every read path the moment the
  app process restarted. Fixed: `DraftStorage` now persists via
  `StorageService` (same pattern as `OutboxStore`), and
  `PostRepositoryImpl`'s redundant in-memory field was removed entirely —
  every read and write goes through the one real local data source now.
- `AnalyticsRepositoryImpl`'s "last-viewed analytics" cache was also
  in-memory-only — the last real numbers a user viewed reset on every app
  restart. Fixed: persisted via the same `StorageService` pattern.
- 11 new tests (`draft_storage_persistence_test.dart`,
  `analytics_cache_persistence_test.dart`), each including an explicit
  "without a storage backend, this does NOT survive recreation" case
  documenting the exact gap closed. Flutter 359 tests, `flutter analyze` 0
  issues, `dart format` clean.

## 2026-08-16 (continued): Phase 5 UI/UX audit — token discipline

Per the original UI/UX plan's 5 sub-items (Motion, Component consolidation,
Token discipline, Adaptive layout, Visual identity): audited each against
the current code before writing anything, per this session's own working
rule of showing a before/after and getting direction approved first. Found
**4 of 5 already substantially real**, contrary to the plan's premise of an
unstarted UI/UX pass:

- Motion: `app_async_switcher.dart`/`animated_count_text.dart` shared
  widgets, used across 12 files.
- Component consolidation: `status_pill.dart` shared widget, used across 11
  files.
- Adaptive layout: `adaptive_card_grid.dart`/`adaptive_content_width.dart`
  shared widgets, used across 7 files.
- Visual identity: already has a deliberate typographic choice (Google
  Fonts Tajawal, not default Roboto) and a real, non-Material-purple brand
  palette (`app_colors.dart`). One real remaining gap found and **not yet
  actioned**: `AppEmptyState` renders a generic Material icon
  (`Icons.inbox_outlined`) rather than a custom illustration — deferred,
  not selected as this session's priority.

**Token discipline had one real, concrete gap, found and fixed**: the token
system itself (`app_spacing.dart` et al.) already existed and colors were
already 100% token-based (zero raw `Color(0x...)` literals under
`lib/src/features`), but spacing specifically had real drift — 22 raw
`EdgeInsets`/`SizedBox` literals exactly matching the `AppSpacing` scale,
scattered across 3 files that already imported the token in other spots (a
first grep-based estimate of "163 across 40 files" was a measurement
artifact of an overly broad pattern and is corrected here — see
`docs/architecture/decisions/0008-spacing-token-enforcement.md` for the
real count and the fix). Fixed the 22 occurrences, and added a real CI
enforcement gate (`scripts/ci/check_spacing_tokens.dart`, pure Dart SDK, no
new lint package) so a new one can't reappear silently.

`flutter analyze` 0 issues, `dart format` clean, full test suite green
after the fix.

## 2026-08-16 (continued): Phase 3 inbound webhook receiver

Real code, not a facade — see `docs/api/webhooks.md` and
`docs/architecture/decisions/0006-inbound-webhook-receiver.md` for the full
design. Summary:

- A real receiver now exists for Facebook Page webhooks
  (`X-Hub-Signature-256` HMAC verification against the existing OAuth App
  Secret) and Telegram bot webhooks (a per-bot secret token, registered
  automatically with Telegram's `setWebhook` at connect time, verified via
  `X-Telegram-Bot-Api-Secret-Token`). Both routes are deliberately
  unauthenticated (the caller is the provider, not a logged-in user) and
  rate-limited via a new dedicated `webhook` throttle.
- Idempotent, replay-safe event storage in a new `platform_webhook_events`
  table (same shape as the existing `billing_webhook_events`), and all
  processing deferred to `ProcessPlatformWebhookEventJob` on the existing
  `default` database queue — no new queue/cache infrastructure, same "no
  Redis, ever" rule as the rest of this project.
- A verified Facebook `feed` change triggers a real, immediate metrics
  re-sync via the existing `PostMetricsSyncService` (not a guess at an
  ambiguous delta payload); a verified Telegram `my_chat_member` update
  showing the bot was removed/kicked immediately flips that page's status
  to `invalid`, ahead of the next periodic health-check tick.
- 14 new feature tests (`PlatformWebhookReceiverTest`) cover: real signature
  verification (valid/missing/wrong-secret), the Facebook subscription
  handshake (including fail-closed with no verify token configured),
  secret-token verification for Telegram (missing/wrong/unknown-account),
  idempotent replay handling for both providers (a byte-identical
  redelivery produces exactly one stored row and exactly one dispatched
  processing job, not two), and the job's own processing logic (page status
  flip, real metrics re-sync via a faked Graph API call).
- Backend 510 tests (507 passed, 3 skipped — unchanged from before this
  work), Pint clean, PHPStan 0 errors.
- **Not yet live-verified.** No delivery from Facebook or Telegram's real
  infrastructure has been observed — that needs external configuration
  (subscribing the app to Page webhooks in the Meta App Dashboard with a
  matching `FACEBOOK_WEBHOOK_VERIFY_TOKEN`) that has not been done yet. The
  Telegram side only needs a public HTTPS `APP_URL`, already true on Render
  staging, and registers itself automatically on the next bot
  connect/reconnect.

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
- Docker build/compose is not runnable on this machine — the `docker` CLI is
  absent (checked 2026-08-16, including the Laragon install this machine
  has for MySQL/Redis binaries; no Docker there either). **Resolved by
  moving the check to CI instead**, where GitHub-hosted runners have Docker
  preinstalled: a new `docker-build` job (backend `147708d`) builds both
  `docker/Dockerfile` and `docker/render/Dockerfile` for real, then boots
  the Render image against a real ephemeral MySQL 8.4 service container and
  polls a real `/up` HTTP response. First attempt failed (a nested
  `docker run ... key:generate --show` call used to derive a throwaway
  APP_KEY died silently in under half a second, never even starting a
  container); replaced with a fixed CI-only dummy key and split into
  separate steps for attributable failures. Second attempt: green,
  `/up` responded within 4 seconds of the container starting. Currently
  informational-only (not yet in the branch-protection required-checks
  list) pending a few more stable runs.
- **Local gitleaks actually run 2026-08-16** (binary downloaded directly
  from GitHub releases, since the CLI isn't preinstalled): backend repo,
  full history, 39 commits — **zero leaks**. Flutter repo, full history, 43
  commits — one finding, but it's the same already-investigated 2026-08-04
  false positive documented in `docs/audit/REMEDIATION_TRACKER.md` (a
  Chromium-internal public telemetry key written into that doc's own prose
  as an example, from the pre-redaction commit; current `main` already has
  it redacted). No new or unaddressed leak.
- This refers to the local `flutter test`/`php artisan test` runner
  environment specifically, not staging — real Facebook (2026-08-12) and
  real Telegram (2026-08-16, see the incident section above) publishes
  *have* both been live-verified against the real staging environment.
  Meta review, Firebase distribution, and a production TLS/domain smoke
  test remain genuinely not done — see
  `docs/operations/closed_beta_release_checklist.md`.
