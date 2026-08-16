# Webhooks API — real, implemented (2026-08-16)

**Prior state (retired 2026-07-27):** this document previously described a `POST /api/webhooks/{platform}` endpoint as if it were already real. It wasn't — no route, no signature verification, no handler existed. That retired notice is superseded by this one: the receiver is now real code with automated test coverage. See `docs/architecture/decisions/0006-inbound-webhook-receiver.md` for the design decision and its full reasoning.

**What "real" means here, precisely:** the routes exist, are wired to a real controller and a real queued job, and are covered by feature tests exercising signature verification, secret verification, and replay/duplicate-delivery handling. **What it does not yet mean:** a live delivery from Facebook or Telegram's real infrastructure has been observed. That requires external configuration (below) that has not been completed as of this date — see `docs/audit/KNOWN_ISSUES.md` for the current honest status before treating this as a live-verified integration.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/webhooks/facebook` | Meta's one-time subscription handshake (`hub.mode`/`hub.verify_token`/`hub.challenge`). |
| `POST` | `/api/v1/webhooks/facebook` | Page webhook event delivery (feed changes — reactions, comments, shares). |
| `POST` | `/api/v1/webhooks/telegram/{socialAccountId}` | Per-bot update delivery (channel posts, bot membership changes). |

All three are deliberately outside `auth:sanctum`/the tenant middleware group — the caller is the provider's own infrastructure, not a logged-in app user. Rate-limited via a dedicated `webhook` throttle (180/minute per IP).

## Trust boundary per provider

- **Facebook**: every `POST` must carry a valid `X-Hub-Signature-256` header — an HMAC-SHA256 of the raw request body keyed by the app's own App Secret (`social.providers.facebook.client_secret`, the same one already used for OAuth token exchange — no new shared secret). A request with a missing or invalid signature is rejected with `401` before anything is read from the body. The `GET` handshake separately requires `hub.verify_token` to match `FACEBOOK_WEBHOOK_VERIFY_TOKEN` (fails closed — `403` — if that env var was never set).
- **Telegram**: every `POST` must carry a valid `X-Telegram-Bot-Api-Secret-Token` header matching the specific bot's own secret, generated and registered with Telegram's `setWebhook` call at connect time (`SocialAccountController::connectTelegramBot()`). A request for an unknown account is `404`; a wrong/missing secret is `401`.

## Idempotent, replay-safe storage

Both providers redeliver an event after a slow or non-2xx response. Every verified delivery is stored in `platform_webhook_events` keyed by a unique `(provider, provider_event_id)` pair — a duplicate delivery is a cheap existence check (same SQLSTATE-23000 guard pattern already used elsewhere in this codebase), not a second full apply. Facebook has no native per-change event id, so `provider_event_id` is a stable hash of the page id + entry time + change content; Telegram's own `update_id` (unique per bot) is combined with the social account id.

## What happens on a verified event

Nothing runs on the request path itself — `ProcessPlatformWebhookEventJob` is dispatched on the existing `default` database queue (same "no Redis, ever" rule as the rest of this project) and does the actual work:

- **Facebook `feed` changes** trigger an immediate real re-sync via the existing `PostMetricsSyncService` (the same Graph Insights call `post-metrics:sync` already makes hourly) for the matched post/page — not a guess at incrementing a counter from an ambiguous delta payload.
- **Telegram `my_chat_member`** updates where the bot's new status is `left`/`kicked` immediately flip that `SocialPage.status` to `invalid` — a real improvement over waiting for the next `oauth-providers:health-check` tick.

`post-metrics:sync` and `oauth-providers:health-check` remain the reconciliation fallback, not the only source of truth, exactly as intended — the webhook is strictly an earlier-signal enhancement on top of them.

## External configuration still required before a live delivery is possible

1. **Facebook**: subscribe the app to Page webhooks in the Meta App Dashboard (Webhooks product), pointing at `{APP_URL}/api/v1/webhooks/facebook`, with `FACEBOOK_WEBHOOK_VERIFY_TOKEN` set on the backend and the identical value pasted into the dashboard's "Verify Token" field.
2. **Telegram**: `APP_URL` must be a real public HTTPS URL (Telegram's `setWebhook` refuses anything else) — already true on Render staging. Nothing else is required; registration happens automatically on the next bot connect/reconnect.

Neither has been completed as of this date. See `docs/audit/KNOWN_ISSUES.md` for the current status.
