# ADR-0010: Real dead-letter alerting and admin ops read, delivery stays opt-in

**Status:** Accepted (2026-08-16, Phase 4 of the production-readiness plan)

## Context

`app:ops-snapshot` (CTO audit Sprint 6) already computed 3 real signals from `PostPublicationAttempt` data — queue length, publish failure rate, retry-storm count — and logged a structured, grep-able alert via `ContextLogger` when a threshold was breached. This was real, not a facade, but the original plan's Phase 4 asked for two things it didn't yet do: (1) also watch `dead_letter_jobs` growth, and (2) deliver the alert somewhere a human would actually see it (a Telegram message to an admin channel), not only a log line. It also asked for a simple internal `/admin/ops` view.

## Decision

- Added a fourth real signal: **open (un-retried) dead-letter count** — `DeadLetterJob::whereNull('retried_at')->count()`, an absolute threshold like the other three, not a delta. A dead letter that's already been retried (`retried_at` set) no longer counts, whether or not that retry ultimately succeeded.
- Extracted the metric computation into `App\Support\Ops\OpsHealthSnapshot`, shared by `OpsSnapshotCommand` (the existing scheduled check) and the new `GET /admin/ops` (`AdminOpsController`, `super_admin`-gated, same pattern as every other `/admin/*` route) — one real computation, not two copies that could drift.
- Added `App\Support\Ops\OpsAlertNotifier`: a real Telegram `sendMessage` call (same Bot API `TelegramProvider` already uses for actual publishing) against a fixed admin chat, fired alongside every `ContextLogger` alert. **Deliberately fail-safe and opt-in**: both `OPS_ALERT_TELEGRAM_BOT_TOKEN` and `OPS_ALERT_TELEGRAM_CHAT_ID` must be set or nothing is sent — no error, no missing-config warning, just a silent no-op — and a real delivery failure (bad token, chat not found, network error) is caught, logged as its own `ops.alert.telegram_delivery_failed` warning, and never fails the command or suppresses the log-based alert that already fired. The operator supplies the actual bot token/chat id later; none is invented or assumed here.

## Consequences

- Nothing about the existing, already-real log-based alerting changed — it's still the source of truth, fires identically with or without Telegram configured, and every existing test for it still passes unmodified.
- `GET /admin/ops` gives a human operator the same 4 metrics on demand, plus a `breaches`/`healthy` summary computed from the same thresholds — useful for a quick check between scheduled runs, not a replacement for them.
- **Not done in this pass, and explicitly flagged rather than silently skipped**: a Flutter admin UI for `/admin/ops`. `platform_admin_screens.dart` — the natural place to add it — was under active concurrent modification by a separate session during this work (a real collision risk, not a hypothetical one: this session observed that file mid-edit with a transient compile error earlier the same day). Deferred rather than risking a conflicting simultaneous edit; the backend endpoint is real, tested, and ready for that screen whenever it's safe to add.
- Crash rate and API latency remain explicitly out of scope, unchanged from the original Sprint 6 decision — see `OpsSnapshotCommand`'s own docblock.
