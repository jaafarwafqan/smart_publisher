# ADR-0006: Inbound platform webhook receiver — signature/secret-verified, database-queued, best-effort subscription

**Status:** Accepted (2026-08-16, Phase 3 of the production-readiness plan)

## Context

`docs/api/webhooks.md` previously documented a `POST /api/webhooks/{platform}` endpoint that never actually existed — no route, no signature verification, no handler; aspirational documentation written during early scaffolding and left uncorrected until 2026-07-27, when it was retired to an honest "never built" notice. `docs/audit/KNOWN_ISSUES.md` has carried "No general provider-webhook receiver is implemented" as an open 🟠 P1 gap ever since. Both `post-metrics:sync` (hourly) and `oauth-providers:health-check` (periodic) already exist as polling reconciliation, but nothing reacts to a real-time push from Facebook or Telegram.

## Decision

Built a real receiver, backend-only (`app/Http/Controllers/Api/V1/PlatformWebhookController.php`), with the following shape:

- **Routes are unauthenticated** (`GET/POST /api/v1/webhooks/facebook`, `POST /api/v1/webhooks/telegram/{socialAccount}`), outside every `auth:sanctum`/`tenant` group — the caller is the provider's own infrastructure, not a logged-in user. Each provider gets its own real trust boundary instead: Facebook's `X-Hub-Signature-256` (HMAC-SHA256 of the raw body, keyed by the existing OAuth App Secret — no new shared secret introduced), and a per-bot `X-Telegram-Bot-Api-Secret-Token` generated at connect time and registered with Telegram's own `setWebhook` call.
- **Idempotent, replay-safe storage**: a new `platform_webhook_events` table mirrors the existing `billing_webhook_events` idempotency shape — a unique `(provider, provider_event_id)` pair makes a duplicate delivery (both providers redeliver on a slow/non-2xx response) a cheap existence check via the same SQLSTATE-23000 guard pattern already used in `SocialAccountController`/`PostController`, not a second full apply.
- **No new queue infrastructure**: signature/secret verification and the idempotent insert happen synchronously (fast, DB-only, no external calls) so the endpoint returns quickly; all actual processing (a page-status flip, a metrics re-sync) is deferred to `ProcessPlatformWebhookEventJob` on the existing `default` database queue — same "no Redis, ever" constraint as everything else in this project.
- **Honest, bounded processing**, not a guess at an undocumented payload shape:
  - Facebook `feed` changes carry no aggregate metrics of their own (a delta notification, not a running total) — the job triggers a real, immediate re-sync via the existing `PostMetricsSyncService`/Graph Insights call instead of trying to increment a counter from an ambiguous payload.
  - Telegram's Bot API exposes no per-post analytics via webhook at all — the real, honest value is `my_chat_member`: catching the bot being removed/kicked from a channel immediately (flips that `SocialPage.status` to `invalid`) instead of waiting for the next `oauth-providers:health-check` tick.
- **Best-effort subscription, not a hard dependency**: `SocialAccountController::connectTelegramBot()` now calls Telegram's `setWebhook` after a successful bot connect, but only when `APP_URL` is a real public HTTPS URL, and any failure is logged and swallowed — it must never fail the underlying bot-token connect. `post-metrics:sync` and `oauth-providers:health-check` remain the source-of-truth reconciliation path; the webhook is strictly an earlier-signal enhancement on top, per the original plan's own instruction.

## Consequences

- This closes the code-level gap. It does **not** close the *external* release gate: a real live delivery requires a publicly reachable HTTPS `APP_URL` (already true on Render staging) plus, for Facebook, subscribing the app to Page webhooks in the Meta App Dashboard with `FACEBOOK_WEBHOOK_VERIFY_TOKEN` set and matching what's pasted into that dashboard. Neither has been done yet — see `docs/audit/KNOWN_ISSUES.md` for the current honest status. Until then this is real, tested code with zero live traffic, same category as `XOAuthProvider` before its own live verification.
- `platform_webhook_events` deliberately does **not** use `BelongsToOrganization`: a webhook arrives with no authenticated tenant context, so `organization_id` is a plain nullable column (best-effort denormalized from whatever social account/page the event matched), not a tenant-scoping column enforced by `OrganizationScope`. Every actual mutation inside the job still runs wrapped in `TenantContext::run()` once an organization is resolved — same sanctioned cross-tenant-lookup pattern as `ProcessScheduledPostsJob`.
- Disconnecting a Telegram bot does not currently call Telegram's `deleteWebhook` — a minor, deliberately deferred follow-up (the stored `webhook_secret` alone is enough to make an orphaned subscription harmless: without a matching `SocialAccount` row, `receiveTelegram()` 404s before any processing).
