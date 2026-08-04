# Specific Incident Playbooks

**New 2026-07-29** (CTO audit Sprint 6). `incident_runbook.md` covers the
generic incident process (roles, severities, communication cadence). This
document is the concrete, codebase-specific diagnostic/remediation steps
for four scenarios — real artisan commands and table names from this
project, not generic platitudes.

## 1. Publish queue backlog / growing `queue_length`

Triggered by: `ops.alert.queue_length` in the logs (from `app:ops-snapshot`, every 5 minutes).

1. Confirm it's real, not a blip: `php artisan tinker --execute="echo App\Models\PostPublicationAttempt::withoutGlobalScope(App\Models\Scopes\OrganizationScope::class)->whereIn('status',['pending','processing'])->count();"`
2. Check if queue workers are actually running: `php artisan queue:monitor` (or check the process manager — Supervisor/systemd unit — actually has live worker processes; a crashed worker with no auto-restart is the most common cause).
3. Check for a stuck `processing` attempt past its stale-claim window (`claim_stale_after_seconds`, default 300s) — `RetryDuePublishAttemptsJob` and the atomic claim/reclaim logic in `AttemptStateMachine` should self-heal this within a few minutes; if the backlog isn't shrinking after 10+ minutes, workers are likely down, not just slow.
4. Once workers are confirmed running: `php artisan queue:work` manually (foreground) briefly to watch real-time throughput and catch any exception being silently swallowed.
5. If a bad deploy is the cause: use `rollback_strategy.md`.

## 2. Publish failure rate spike (`ops.alert.publish_failure_rate`)

1. Get the actual failure breakdown by classification (not just the rate): `PostPublicationAttempt::withoutGlobalScope(...)->whereIn('status',['failed','dead_letter'])->where('updated_at','>=',now()->subHour())->groupBy('error_classification')->selectRaw('error_classification, count(*) as c')->pluck('c','error_classification')`.
2. **`non_retryable` spike, one provider** (e.g. a burst of `401`s from Facebook) — almost certainly a provider-side token/policy change or a provider outage misclassified as auth failure. Check `docs/audit/evidence/` conventions or the provider's status page. If it's a real provider auth issue, `PublishEngineService`'s org-scoped circuit breaker should already be limiting the blast radius to the affected organizations — confirm via `Cache::get('publishing:provider:<name>:circuit-open')`/`Cache::get('publishing:provider:<name>:org:<id>:circuit-open')`.
3. **`unknown` classification spike** — means `PublishErrorClassifier` is seeing an error shape it doesn't recognize (a new provider error format, or a genuine app bug). Check recent `dead_letter_jobs` rows' `error_message` for the actual text — this is the fastest way to spot a new provider API change that needs a classifier update.
4. **Spike across all providers simultaneously** — look at the app's own health first (`/up` endpoint, recent deploys) before assuming every provider broke at once.

## 3. Database unreachable / down

1. Check `/up` (Laravel's built-in health endpoint) first — a 500 there with a DB-connection-refused message in `storage/logs/laravel-*.log` confirms it's the DB, not the app.
2. **MySQL specifically** (production target): check the MySQL process/service is actually running on its host, and that `DB_HOST`/`DB_PORT`/credentials in the live `.env` are correct — a surprising number of "DB down" incidents are actually a credential or network-path change, not the database engine crashing.
3. Once the DB is reachable again, the app does **not** need a restart — Laravel reconnects per-request. Queue workers, however, may need a restart if they held a dead connection.
4. If genuine data loss/corruption is suspected (not just unreachability): see `backup_strategy.md` for the restore procedure. Restore to an isolated environment first and validate before pointing production at it — never restore-in-place without a validated copy of the current (possibly-corrupt) state saved first, in case the "corruption" was actually a misdiagnosis.

## 4. Secret rotation (OAuth client secret, `APP_KEY`, admin password)

- **OAuth provider client_id/client_secret** (Facebook/Telegram/etc.): rotate via `PUT /system-settings/oauth-providers/{provider}` (`SystemSettingsController::update`) — this updates the DB-stored override (`OAuthProviderSetting`), which takes precedence over `.env`/`config/social.php` without a restart. Test immediately via the same endpoint's `POST .../test` action before considering the rotation complete.
- **`APP_KEY`**: **do not rotate this casually.** Every `SocialAccount.access_token`/`refresh_token` (encrypted cast) becomes permanently undecryptable the moment `APP_KEY` changes, unless you re-encrypt every row first (`php artisan key:generate` has no built-in re-encryption step for custom casts — this would need a dedicated migration script that decrypts with the old key and re-encrypts with the new one, which does not exist yet). If `APP_KEY` rotation is ever genuinely required (suspected compromise), plan for every connected social account needing to be reconnected by its owner, or budget time to write that re-encryption migration first.
- **Admin password**: `AdminUserSeeder` already refuses known-weak defaults in production (Sprint-era fix) — a routine admin password rotation is just changing the user's password through the normal auth flow, no special procedure needed.
