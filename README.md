# Smart Publisher

Smart Publisher is a Flutter app (Windows/Web/mobile) with a Laravel backend
(`smart_publisher_backend`, a sibling repository) for organisation-scoped
content workflows. Its production **closed-beta** scope is deliberately only
Telegram and Facebook Pages. Instagram, WhatsApp, LinkedIn, X, and other
providers are visible as `Coming soon` and are rejected server-side in
production; the product must never fabricate a publish outcome for them.

**Status (2026-08-16): launch hardening is in progress.** A real staging
deployment exists (Render, with Aiven MySQL and Cloudflare R2), and current
`main` is confirmed live there (`smart_publisher_backend@ffc2625`,
`smart_publisher@8324f5f`) — the earlier staging-currency gap is closed. A
real Facebook Page publish and a real Telegram channel publish have both
been live-verified end-to-end against it. A same-day incident (a Render
Auto-Deploy/env-var mismatch that 500'd most of the API) and two other real
bugs it surfaced (a CSP gap blanking the web build, a Telegram cross-org
connect crash) were found and fixed the same session; see
[`docs/audit/KNOWN_ISSUES.md`](docs/audit/KNOWN_ISSUES.md) for the full
writeup and what is and isn't live. This repository is still not evidence
that Meta App Review, a signed distribution artifact, or a real-device
native-login test exist. The concrete gates are in
[`docs/operations/closed_beta_release_checklist.md`](docs/operations/closed_beta_release_checklist.md).

The supported release artifact is an **Android closed-beta AAB** only. Web and
desktop builds remain developer targets; this repository does not claim a web
deployment, backend deployment, canary rollout, or automated rollback.

For a hosted Flutter Web build, pass
`--dart-define=SP_WEB_COOKIE_AUTH_ENABLED=true` together with the secure API
endpoints. The backend must set `AUTH_WEB_COOKIE_ENABLED=true` and exact
credentialed CORS origins; this moves access and refresh tokens into Secure,
httpOnly cookies rather than browser-accessible storage.

## What this app actually does

- **Compose**: title/content with hashtag/mention highlighting, a formatting toolbar (bold/italic honestly rendered only where the target platform actually supports it — Telegram via real HTML `parse_mode`, everyone else gets clean stripped plain text, never literal asterisks), a real emoji picker (`emoji_picker_flutter`), per-platform caption overrides, and a per-platform live preview that shows exactly what each destination will really display.
- **Media Library**: real upload, real compression, tagging, dedupe hints (never a silent block) — backed by the real `media_attachments` table, not a UI illusion built from scanning old post attachments.
- **Accounts**: Telegram bot-token connection and Facebook Page OAuth are the
  only closed-beta connection paths. The UI and API do not expose unsupported
  providers as usable publishing destinations.
- **Schedule or publish now**: a dedicated backend endpoint for each action (not a generic update reused with missing fields) — publish-now dispatches real background jobs per selected page; schedule sets a real future timestamp the backend's minute-by-minute job picks up.
- **Calendar**: shows genuinely pending scheduled work (not a mix of scheduled-and-already-published posts).
- **Analytics**: real per-page metrics where the provider actually supplies them; explicit `null`/"not enough data yet" rather than a fabricated number when it doesn't.

## Architecture

Repository pattern (`*RepositoryImpl` per feature, all extending `BaseRepository`) + Riverpod as a DI container (screens call `ref.read(...)` directly — no CQRS/Mediator/Use-Case-mandatory layer; see "What's deliberately not here" below) + an offline outbox (`OutboxStore`, persisted via `StorageService`, drained by `SyncWorker`) for network-failure resilience on create/update/delete. Full detail: `docs/architecture/system_overview.md` and `docs/architecture/request_flow.md`.

```text
lib/src/
  core/           # DI (app_providers.dart), network, security, theme, router
  features/       # posts, composer, media, schedule, auth, analytics, notifications, dashboard, administration
  backend_contracts/v1/  # explicit DTOs + BackendContractMapperV1, one place all API shape assumptions live
  offline/        # OutboxStore + SyncWorker
```

### What's deliberately not here

Earlier commit messages referenced a CQRS/Mediator/Policy-Engine architecture. It was audited, found to be **empty scaffolding — 0-byte files, never actually wired to anything** — and deleted, along with a duplicate dead `features/authentication/` folder. The real, live flow is Repository → Riverpod → Laravel API, documented as it actually works in `docs/architecture/request_flow.md`. Don't resurrect the old pattern without reading `docs/audit/ROUND1_CTO_AUDIT.md` (BUG-007) first — it explains why it was removed rather than "connected."

`platforms/` (a `SocialPlatform` abstraction + per-provider plugins that faked successful connects/publishes with zero real HTTP calls) and `publish_engine/` (a local retry/circuit-breaker publish pipeline) were removed for the same reason during the role/permission remediation (2026-08-09): neither was wired to any provider the real app ever read — real connect/publish goes entirely through the backend OAuth flows and Job pipeline (`PublishPostJob`, `PublicationBatchCoordinator`).

## Documentation map

| Area | File |
|---|---|
| API reference (OpenAPI 3.0, real & current) | [docs/api/openapi_v1.yaml](docs/api/openapi_v1.yaml) |
| Postman collection | [docs/api/postman_collection.json](docs/api/postman_collection.json) |
| Database schema (ERD, real & current) | [docs/database/erd.md](docs/database/erd.md) |
| Roles, permissions, plans/subscriptions (honest: no plans/subscriptions exist) | [docs/architecture/permissions_and_roles.md](docs/architecture/permissions_and_roles.md) |
| Closed-beta provider scope, OAuth flows, and Meta gate | [docs/api/integrations.md](docs/api/integrations.md) |
| Privacy policy, terms, data deletion, and support | [docs/legal/](docs/legal/) |
| Architecture overview | [docs/architecture/system_overview.md](docs/architecture/system_overview.md) |
| Request flow | [docs/architecture/request_flow.md](docs/architecture/request_flow.md) |
| Architectural decisions (ADRs) | [docs/architecture/decisions/](docs/architecture/decisions/) |
| Current test status | [docs/testing/STATUS.md](docs/testing/STATUS.md) |
| Known issues & incomplete features (current, consolidated) | [docs/audit/KNOWN_ISSUES.md](docs/audit/KNOWN_ISSUES.md) |
| Historical audit reports | [docs/audit/ROUND1_CTO_AUDIT.md](docs/audit/ROUND1_CTO_AUDIT.md), [ROUND2](docs/audit/ROUND2_CTO_AUDIT.md), [PRODUCTION_READINESS_AUDIT.md](docs/audit/PRODUCTION_READINESS_AUDIT.md) |
| Closed-beta distribution, rollback boundary, canary constraints, incidents, backup | [docs/operations/](docs/operations/) |
| Closed-beta release evidence and staging smoke test | [docs/operations/closed_beta_release_checklist.md](docs/operations/closed_beta_release_checklist.md) |

## Running locally

Requires the Laravel backend running alongside (`smart_publisher_backend`, sibling directory — see its own README for setup). Default dev target is `http://127.0.0.1:8000/api/v1`.

```bash
flutter pub get
flutter run                      # Windows/Chrome/mobile, whatever's connected
flutter run -d chrome            # explicit web target
flutter build web --release      # developer build only; it is not a closed-beta deployment
```

Pointing at a different backend:

```bash
flutter run --dart-define=SP_API_BASE_URL=https://your-api-host/api/v1
```

### Tests

```bash
flutter analyze
flutter test
```

Current status: see [docs/testing/STATUS.md](docs/testing/STATUS.md).

### Laravel Smoke Test (Login/Refresh/Create/Upload Draft/Schedule/Analytics)

```bash
flutter test test/integration/laravel_backend_smoke_integration_test.dart \
  --dart-define=SP_RUN_LARAVEL_SMOKE=true \
  --dart-define=SP_API_BASE_URL=https://your-api-host \
  --dart-define=SP_AUTH_BASE_URL=https://your-auth-host \
  --dart-define=SP_OAUTH_BASE_URL=https://your-oauth-host \
  --dart-define=SP_SMOKE_EMAIL=your-user@email.com \
  --dart-define=SP_SMOKE_PASSWORD=your-password
```

## CI/CD

- [.github/workflows/ci.yml](.github/workflows/ci.yml) is a hard frontend
  gate: secret scan, release-source hardening, formatting, `flutter analyze`,
  tests, and an enforced line-coverage floor over `coverage/lcov.info` (see
  the workflow file's own comments for the current number and ratchet
  plan). Its presence in source is not proof of a passing run on the latest
  commit — check the Actions tab.
- [.github/workflows/release.yml](.github/workflows/release.yml) produces an
  Android **closed-beta** AAB only. It fails closed when signing, HTTPS
  endpoint, or Firebase App Distribution configuration is missing; it does
  not deploy the web client or Laravel backend.
- Canary controls and automated rollback are intentionally absent. See the
  operator boundaries in [`docs/operations/`](docs/operations/).
- Backend CI and Docker gates live in the sibling Laravel repository and must
  pass independently; their presence in source is not staging evidence.

## Remaining external and product gates

- **In-app notifications** are persisted and recipient-scoped; **push
  notifications** do not exist (no FCM/APNs anywhere).
- **Meta approval and real Facebook Page verification** are external release
  gates, not source-code substitutes.
- **Public legal/support URLs and an operator identity** must be supplied by
  the deployment owner before inviting external users.
- **Other providers** remain intentionally unavailable in production until a
  real integration, provider approval, and production evidence are added.
- **Webhook receiver**: a real, signature/secret-verified receiver exists for Facebook Page and Telegram bot webhooks (code-complete, tested, database-queued — no new infrastructure). It has **not** been live-verified against real provider traffic yet — that needs external Meta App Dashboard configuration not yet done. See [docs/api/webhooks.md](docs/api/webhooks.md).
- **Offline drafts and analytics**: `DraftStorage` and the analytics "last-viewed" cache are real, persistent local data sources now (`StorageService`-backed, same pattern as the offline outbox) — a post edited offline or the last numbers a user viewed both survive an app restart. See [ADR-0007](docs/architecture/decisions/0007-persistent-local-caches-for-drafts-and-analytics.md).
- **UI/UX**: motion, component consolidation, and adaptive layout already have real shared primitives (`app_async_switcher.dart`, `status_pill.dart`, `adaptive_card_grid.dart`) used across a dozen-plus screens; typography has a deliberate identity (Google Fonts Tajawal). Spacing token discipline had real drift (raw values beside already-tokenized ones) — fixed, with a new CI gate (`scripts/ci/check_spacing_tokens.dart`) so it can't silently reappear. See [ADR-0008](docs/architecture/decisions/0008-spacing-token-enforcement.md). Empty-state illustrations remain generic Material icons — a known, not-yet-actioned gap.
- **API docs**: fixed real drift in `docs/api/openapi_v1.yaml` (documented deleted `/accounts/*` routes; was missing Organizations/Admin/approval-workflow/native-connect/Webhooks). Found along the way: the backend's actually-served spec (`GET /openapi.json`) already had all of this correct — two independently hand-maintained OpenAPI documents exist for the same API, an open structural item, not yet resolved. See [ADR-0009](docs/architecture/decisions/0009-openapi-doc-drift.md).
- **Observability**: `app:ops-snapshot` now also watches open `dead_letter_jobs` count and can deliver a real Telegram message to an admin channel on any threshold breach (opt-in — unconfigured by default), plus `GET /admin/ops` for an on-demand read. No Flutter UI for it yet. See [ADR-0010](docs/architecture/decisions/0010-observability-alert-delivery.md).
- **A tested hosting-specific rollback procedure** is still an external
  requirement; the local rollback script intentionally fails rather than
  pretending to roll anything back.

Full current list, including what's been fixed and verified: [docs/audit/KNOWN_ISSUES.md](docs/audit/KNOWN_ISSUES.md).
