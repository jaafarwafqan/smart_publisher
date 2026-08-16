# Known Issues & Incomplete Features — Smart Publisher

**Last updated:** 2026-08-16
**Purpose:** A single, current-as-of-today source of truth for "what's real, what's fake, and what's missing." This project has been through multiple audit rounds (see `ROUND1_CTO_AUDIT.md`, `ROUND2_CTO_AUDIT.md`, `PRODUCTION_READINESS_AUDIT.md`) — this document consolidates their outcomes plus everything found and fixed since, so a new reader doesn't have to reconstruct history from four long reports. Where a historical report and this document disagree, **this document is current**; the historical reports are point-in-time snapshots kept for audit trail, not living status.

For test counts and CI status specifically, `docs/testing/STATUS.md` is the
single source of truth, not this file — it's re-verified more often than
this document's prose is edited.

Severity key: 🔴 P0 (blocks production/trust) · 🟠 P1 (real gap, should fix soon) · 🟡 P2 (edge case / rough edge) · ⚪ Deliberate scope decision (not a bug)

---

## Current launch-hardening override (2026-08-16)

Supersedes the 2026-08-15 override below where they disagree:

- **Staging currency gap (2026-08-15 entry below) is closed.** `main` on
  both repos — including the primary-owner fix, ARB/tooltips/openapi/CSP
  items from external report #3, and everything from this entry — is
  confirmed live on Render staging (`smart_publisher_backend@ffc2625`,
  `smart_publisher@8324f5f`), not just committed locally.
- **Real staging incident found and fixed the same day, not just a code
  audit finding**: Render's Auto-Deploy (confirmed on) had already shipped
  the Redis-removal refactor to the Web service while a conflicting
  service-level `CACHE_STORE=redis`/`SESSION_DRIVER=redis`/
  `QUEUE_CONNECTION=redis` (overriding the correct linked-Environment-Group
  `database` values) was still set directly on it — every cache/session-
  touching request 500'd with `Class "Redis" not found`. Fixed by removing
  the conflicting service-level vars; verified via repeated clean checks.
  Full incident writeup: `docs/testing/STATUS.md`.
- **A real blank-white-page bug on the staging web build, found and fixed**:
  the CSP (both the `<meta>` tag and the separately-configured HTTP header)
  never allow-listed `www.gstatic.com`/`fonts.gstatic.com`, so Flutter
  Web's own CanvasKit renderer and Roboto font were blocked outright and
  the app never finished booting. Fixed in both CSP sources; confirmed via
  a fresh Incognito load with a clean console.
- **A real Telegram-connect bug, found via a genuine connect attempt and
  fixed**: a bot already linked to a different organization crashed the
  connect endpoint with an uncaught 500 instead of a clear error, because
  the platform-wide `(provider, provider_account_id)` uniqueness check was
  implicitly scoped to the caller's own organization. Fixed with a clear
  422; the stale conflicting row was removed via the normal authorized
  delete endpoint (not a DB bypass).
- **A real Telegram publish was end-to-end live-verified on staging** (not
  just Facebook, as of the prior override): real login, real R2 media
  round-trip (uploaded via Web, read back byte-for-byte via a signed URL),
  real bot connect, real `publish-now` to `@UOK_Faculty_Nursing`, reached
  `published` on the first attempt with no new `dead_letter_jobs` entry,
  cleaned up after visual confirmation.
- **Two secrets were pasted directly into a chat session this day**: a
  scoped Render API key and a Telegram bot token. Neither was echoed back
  or persisted beyond a scratchpad file deleted the same session, but both
  should be treated as exposed — rotate/revoke when convenient.
  **Explicitly deferred by the operator (2026-08-16)** — a deliberate
  decision to postpone, not a forgotten item; the API key has not been
  revoked, and the several long-standing Aiven/AWS/mail/Facebook secrets
  pasted earlier the same session (see the 2026-08-15 entry's own caveats)
  also remain un-rotated.
- **Render Auto-Deploy is a confirmed, deliberate decision (2026-08-16),
  not an oversight**: all three backend services and the frontend static
  site auto-deploy on every push to `main`. The operator explicitly chose
  to keep this on rather than switch to controlled manual deploys.
- **A real Facebook publish was end-to-end live-verified on staging the
  same day as Telegram's (2026-08-16)**: real draft, real R2 media upload,
  targeted at the pre-existing "قلوب تنتظر النور" Page, `publish-now`
  reached `published` within 3 seconds, zero new `dead_letter_jobs`
  entries. Closes the "Facebook-equivalent smoke test" gap. One caveat:
  unlike Telegram, there is no API path to delete a Facebook Page post
  server-side (the Page access token is deliberately never exposed) — the
  test post, and an earlier undeleted one from 2026-08-12 on the same
  Page, both need manual deletion by the Page's own operator.

## Prior launch-hardening override (2026-08-15)

Supersedes the 2026-07-30 override below where they disagree:

- A real staging deployment exists on Render (backend, frontend, separate
  queue worker and scheduler, Aiven MySQL, Cloudflare R2 object storage) —
  first stood up 2026-08-11/12. "No web/backend deployment" in the
  2026-07-30 section below is superseded; a real one exists, though it is
  **not continuously kept current** — see the staging-currency gap below.
- A real Facebook Page publish has succeeded and was live-verified against
  the real Meta API (2026-08-12, the page-token fix). One loose end: the
  live test post on the "قلوب تنتظر النور" page was never deleted —
  Render's free plan has no SSH, a debug delete endpoint or manual deletion
  is still needed.
- Public legal pages (Privacy Policy, Terms, Data Deletion) are real and
  live at `/legal/*` on the staging backend, with the real operator
  identity, support contact, and retention period filled in — no longer a
  placeholder or an open item.
- **Staging currency gap:** the platform-admin fixes, primary-owner
  invariant, ARB localization pass, and CSP meta tags from external report
  #3 (also 2026-08-15) are committed locally on `main` but **not yet
  deployed to the Render staging environment described above.** Anyone
  testing against the live staging URL right now is not exercising that
  work. Deploy both repos' latest `main` and re-run the staging smoke test
  before treating those fixes as live.
- **Database-backed service topology is source-complete but not staging
  evidence.** The latest backend source deliberately uses MySQL for cache,
  sessions, and queues and removes Redis/Horizon. It still needs the normal
  staging deployment, minutely Scheduler verification, and measured queue-lag
  observation before it can be treated as live.
- Native Facebook Login (`flutter_facebook_auth`) backend endpoint is
  deployed and live-smoke-tested against the real Meta API. The Flutter
  side is code-complete and unit/widget-tested (see `docs/testing/STATUS.md`
  for current counts) but has **not** been run on a real Android/iOS device
  — no device or macOS toolchain is available in this sandbox.
- CI coverage gates (`--min=0` and an unenforced Flutter `lcov.info` upload)
  were replaced with real floors on 2026-08-15 — see
  `.github/workflows/ci.yml` in both repos. These are deliberately
  conservative starting floors, not final targets; see the ratchet plan in
  each workflow file's comments.
- A GitHub Actions Combined Status / Workflow Run for the latest commit on
  either repo has **not** been independently checked as part of this
  session's work — do not treat local `flutter test` / `php artisan test`
  re-runs as equivalent to a verified CI pass. See `docs/testing/STATUS.md`.

## Prior launch-hardening override (2026-07-30)

The historical entries below are retained as audit evidence.  Where they
contradict this section, this section is authoritative:

- In-app notifications are no longer a facade: they have persistent tenant-
  and recipient-scoped storage, read endpoints, lifecycle events, and tests.
  This does **not** add FCM/APNs push delivery.
- English and Arabic localizations are generated from ARB files; the old
  "no localization/RTL" entry is superseded.
- Production provider scope is Telegram and Facebook Pages only.  WhatsApp,
  Instagram, X, LinkedIn, and all other providers are visibly unavailable and
  server-rejected in production; a generic mock is not a live integration.
- Android now has a release identity, TLS-only release traffic, a closed-beta
  app icon, deep-link declaration, and a signing gate with no debug fallback.
- Backend CI/Docker, MySQL reliability coverage, and PHPStan are implemented
  launch gates.  Their source configuration is not proof of a successful CI
  run or real staging deployment; refer to the final evidence.
- The only supported release channel is Android `closed-beta`.  There is no
  implemented canary, web/backend deployment, or automated rollback control.

The remaining release blockers are external evidence, not code placeholders:
real MySQL/InnoDB staging verification, a signed Firebase-distributed AAB,
real Facebook Page staging publish and Meta approval, public legal/support
URLs, a deployment owner, and a tested hosting-specific rollback procedure.
See `docs/operations/closed_beta_release_checklist.md`.

---

## ✅ Fixed, verified, or deliberately superseded (do not re-report these)

These were real, confirmed bugs at some point in this project's history. They are listed here **only** so nobody re-discovers and re-reports them as new — each was fixed and verified live.

| Area | What was wrong | Status |
|---|---|---|
| Privilege escalation | Any `users.update` holder could self-assign `admin` via `UserController::update` | Fixed — `roles` field removed from that endpoint, requires `roles.assign` |
| OAuth scope wildcard | Backend issues `'*'` scope; Flutter's `ScopeAuthorizer` didn't understand wildcards, silently blocking every write after login | Fixed |
| Posts list always empty | Flutter read `items`, backend sends `data`/`meta` | Fixed |
| Analytics dashboard 404 | Flutter called `/analytics/dashboard`, route didn't exist | Fixed — route + honest-zero-state `dashboard()` added |
| Logout didn't call backend | Tokens stayed valid server-side forever after "logout" | Fixed — calls `/auth/logout`, server deletes both access + refresh tokens for the device |
| Empty CQRS/DDD/Mediator/Policy-Engine scaffolding | `app/Domain`, `app/Application/{Handlers,UseCases}`, `app/Infrastructure/{Repositories,Persistence}` (Laravel) and `lib/src/application/{mediators,pipelines,transactions}` (Flutter) were 0-byte files despite commit messages claiming implementation | Deleted; docs (`system_overview.md`, `request_flow.md`) rewritten to describe the real Repository+Riverpod+Outbox flow |
| OAuth tokens stored plaintext | `social_accounts.access_token`/`refresh_token` had no `encrypted` cast | Fixed |
| Permission cache never invalidated | `events_enabled: false` + 24h TTL meant a revoked permission could stay active for a day | Fixed — `events_enabled: true` |
| `SocialAccountPolicy` written but unused | Controller repeated manual ownership checks 5×, ignoring the registered Policy | Fixed — wired via `$this->authorize(...)` |
| Theme toggle did nothing | `theme_provider.dart` hardcoded to `ThemeMode.system` | Fixed — real `Notifier<ThemeMode>` reading/writing storage |
| Analytics 500 in real use (not caught by tests) | `DashboardCacheService` assumed the cache store supports tagging; the app's real driver (`database`) doesn't | Fixed |
| Auth failures returned 500 instead of 401/403 | Default guest redirect tried a non-existent `login` named route in this API-only app | Fixed via `redirectGuestsTo(fn () => null)` |
| Flutter blank-crashed on every launch | `String.fromEnvironment` used non-const through a helper function (illegal — must be a literal call site) | Fixed |
| **Outbox had zero persistence** (was the single most severe finding across all audits) | `OutboxStore` was an in-memory `Map` — any offline post create/edit/delete was silently and permanently lost if the app closed/reloaded before sync | Fixed — persists via `StorageService`, survives restart |
| Scheduler duplicate-dispatch storm | `ProcessScheduledPostsJob` never left `status='scheduled'` at dispatch time, so every 60s tick re-dispatched the same backlog (proven: 2000→4000 jobs on one extra tick) | Fixed — transitions to `'publishing'` immediately before the dispatch loop |
| No backup/restore tooling existed at all | Zero Console Commands in the project | Fixed — `app:backup-database` / `app:restore-database` (SQLite via `VACUUM INTO`, MySQL via `mysqldump`/`mysql`), scheduled daily |
| Large-file upload: 500 on a valid edge-case image | Uncaught `ImageDecoderException` from Intervention Image on a degenerate 1×1 PNG | Fixed — graceful `null` thumbnail on decode failure |
| Large-file upload: thumbnail filenames doubled | `preg_replace` optional group matched twice → `..._thumb.jpg_thumb.jpg` on every upload | Fixed |
| file_picker crashed the entire web app | `.path` is unavailable on Flutter Web; needed `.bytes` | Fixed across the full chain (entity, repository, compression, offline outbox replay) |
| Connect/Disconnect on Dashboard was 500ing | Flutter called `AccountController` (only `index()` implemented); the real, complete controller was `SocialAccountController` at a different route | Fixed — migrated to the real controller |
| Dashboard numbers were 100% hardcoded literals | `145/23/1880/4/12`, "99.2% Stable", fake "Recent Activity" baked into `app_routes.dart` | Fixed — real data, `Dashboard` extracted to its own feature module |
| X/Twitter account connect always 422'd | Provider string mismatch (`twitter` locally vs `x` expected by backend) | Superseded by the closed-beta allow-list — X is `Coming soon` and production rejects connection/publishing |
| WhatsApp connect always 422'd | Provider entirely unregistered server-side | Superseded by the closed-beta allow-list — WhatsApp is `Coming soon` and production rejects connection/publishing |
| **Media Library** disconnected from its own real backend | Screen fabricated a "library" by scanning post attachments instead of calling the real, working `MediaLibraryController::index()`; `/media/compress` had no route at all | Fixed this session |
| **Composer**: no rich text, no per-platform honesty | Built: hashtag/mention highlighting, formatting toolbar, real `emoji_picker_flutter`, honest per-platform preview (Telegram renders real bold/italic via HTML `parse_mode`; every other platform gets markers stripped to clean plain text — never sent as literal asterisks) | Built this session |
| **Scheduling silently failed over the network** | `SchedulePost` reused the generic `updatePost` endpoint, whose request DTO doesn't carry `status`/`scheduled_at` at all — clicking "Schedule" updated title/content only | Fixed — dedicated `POST /posts/{id}/schedule` call, mirroring the already-correct `publishNow` pattern |
| Calendar screen fetched all posts and filtered client-side | Real, cached, already-tested `GET /calendar` endpoint existed with zero Flutter callers | Fixed — wired up |
| **Every post create/update silently reported "failed" despite succeeding** (found via live end-to-end testing 2026-07-27) | PHP serializes an empty `platform_content` map as JSON `[]`; Flutter's `as Map<String,dynamic>` cast threw on every post without per-platform overrides | Fixed both sides — backend normalizes empty maps to `{}`, Flutter parser no longer hard-casts. Historical Telegram delivery evidence only; re-run the current staging gate before inviting testers. |
| Posts always showed "0 platforms" even when delivered | `PostResource` never returned which pages a post targeted | Fixed — eager-loads `socialPages.socialAccount`, returns real providers |
| Published posts showed a false "Scheduled" badge | Backend stamps `scheduled_at` even for immediate publish (an internal queue detail); UI didn't distinguish | Fixed — label now branches on `status`; Calendar query scoped to `status='scheduled'` only |
| Login screen was an unbranded placeholder | Literally marked "simple demo screen" in a code comment | Redesigned into its own proper, branded screen this session |
| **Staging 500'd on login/legal pages/openapi.json (2026-08-16)** | Auto-Deploy shipped the Redis-removal refactor while a conflicting service-level `CACHE_STORE=redis`/`SESSION_DRIVER=redis`/`QUEUE_CONNECTION=redis` still overrode the correct linked-group `database` values on the Web service — `Class "Redis" not found` on every cache/session-touching request | Fixed — removed the conflicting service-level vars |
| **Staging web build was a blank white page (2026-08-16)** | CSP (`<meta>` tag and the separately-configured HTTP header) never allow-listed `www.gstatic.com`/`fonts.gstatic.com`, blocking Flutter Web's own CanvasKit renderer and Roboto font outright | Fixed in both CSP sources; confirmed via a clean Incognito console |
| **Telegram connect 500'd for a bot already linked elsewhere (2026-08-16)** | `(provider, provider_account_id)` uniqueness is platform-wide, but the "already linked?" lookup was implicitly scoped to the caller's own organization — the INSERT collided with the real DB constraint | Fixed (`ffc2625`) — clear 422 instead, same SQLSTATE-23000 guard pattern as `PostController`/`MediaLibraryController` |

---

## 🟠 Open — real gaps and external gates

1. **Push notifications do not exist.** In-app notifications are persistent,
   recipient-scoped, and tested, but there is no FCM/APNs delivery path. This
   is not a reason to describe the in-app notification API as a facade.
2. **No general provider-webhook receiver is implemented.** Do not rely on
   `docs/api/webhooks.md` as a deployed callback endpoint. The supported
   Telegram/Facebook connection and publish flows are documented in
   `docs/api/integrations.md`.
3. **No plans, subscriptions, or billing system exists.** It is outside the
   closed-beta publishing scope, rather than an available SaaS capability.
4. **OAuth state cleanup needs an explicit retention job.** Historical state
   rows must not be treated as permanent audit storage.
5. **Publication-attempt retention needs a product decision.** Deleting a
   post can remove related attempt history; choose a retention model before
   any broader rollout.
6. **Production observability is an external deployment requirement.** Source
   configuration is not evidence of an active monitoring/alerting service.
7. **Closed-beta evidence is incomplete until an operator records it.** As of
   the 2026-08-15 override above: a real staging deployment exists, a real
   Facebook Page publish has been live-verified, and public legal/support
   URLs are live — those three are done, not remaining blockers. Still
   remaining: a signed Firebase-distributed AAB, Meta App Review/approval,
   a real-device run of native Facebook Login, and a tested
   hosting-specific rollback procedure. See the release checklist.

## 🟡 Environment-dependent findings — need real-topology verification

Historical performance numbers were captured against **SQLite + `php artisan
serve`** and are not production capacity evidence.  Backend CI/Docker now
defines a MySQL/InnoDB reliability gate, but neither that configuration nor a
local test replaces a real HTTPS staging run with the actual queue-worker
topology.

- The historical SQLite concurrency and throughput observations must not be
  extrapolated to MySQL, PHP-FPM, or horizontally scaled workers.
- SQLite must not be used with multiple concurrent queue workers.  The
  production-shaped target is MySQL/InnoDB; verify that target in staging
  before external invitations.

## ⚪ Deliberate closed-beta scope decisions (not bugs)

- Organisation membership and the editor's own-post rule are authorization
  requirements, not optional global-permission behavior.
- Instagram, WhatsApp, X, LinkedIn, and every other provider are intentionally
  `Coming soon`; a non-production generic OAuth mock is not an integration.
- Canary controls, web/backend deployment controls, and automated rollback
  are intentionally unavailable.  Closed-beta tester groups and an operator's
  tested hosting procedure are the only valid release/rollback boundary.
- Stale-`publishing` crash recovery needs a separately designed watchdog; it
  must not be implied by the normal batch-completion flow.

---

## Historical audit notes

The prior audit reports and older entries in this document remain evidence of
what was found at the time.  They must not be read as the current release
state.  In particular, older references to notification facades, absent
backend CI/Docker, generic OAuth support for Instagram/WhatsApp, canary
rollouts, or a successful rollback are superseded by the launch-hardening
override above.  The current source-of-truth documents are:

- `docs/api/integrations.md` for the Telegram/Facebook Pages allow-list and
  Meta gate;
- `docs/operations/closed_beta_release_checklist.md` for evidence required
  before invitations; and
- `docs/operations/release_pipeline.md`, `rollback_strategy.md`, and
  `canary_releases.md` for the intentionally limited operational controls.
