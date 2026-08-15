# Staging Environment Checklist

**Updated 2026-08-15** (CTO audit Sprint 6 and deployment-topology
reconciliation). A real Render staging deployment exists, but it is not kept
current automatically. This checklist records the required topology and
verification for a staging deployment; it is not evidence that the currently
running service already has the latest commit.

## What already exists and can be reused as-is
- `docker/Caddyfile` now makes Caddy the only public TLS edge in the backend Compose stack. It automatically obtains and renews a trusted certificate, redirects HTTP to HTTPS, and keeps Nginx/PHP-FPM internal; do not publish port 8000 as an alternative API route.
- `docker/docker-compose.yml` + `docker/Dockerfile` + `docker/nginx.conf` (backend) — PHP-FPM + Nginx + MySQL, production-shaped for self-hosted use. Cache, sessions, and queues are database-backed; there is no Redis service or Horizon. Render uses `docker/render/Dockerfile` plus separate web, worker, and Scheduler services with the same environment contract.
- `.github/workflows/ci.yml` (both repos) — already runs on every push/PR to `main`. Staging deploys should trigger from this pipeline once a target host exists, not be a separate manual process.
- `app:backup-database` / `app:restore-database` — usable on staging exactly as on production (see `backup_strategy.md`).
- `app:ops-snapshot` (new this pass) — same scheduled health check works unmodified on staging.

## Staging-specific `.env` differences from production
- `APP_ENV=staging` (not `production` — some Laravel behaviors, like detailed error pages, key off this).
- A **separate** `APP_KEY` from production — never reuse production's key on staging, since staging data (including encrypted `SocialAccount` tokens) must never be decryptable by leaking a staging credential, and vice versa.
- Separate OAuth app credentials/redirect URIs per provider where the provider allows it (Facebook/Telegram/etc. developer consoles usually support multiple registered redirect URIs — add the staging one alongside production's, don't reuse).
- `SOCIAL_ALLOWED_REDIRECT_URIS` (added this pass) must include whatever redirect URI the staging build of the Flutter app actually uses.
- Start from `smart_publisher_backend/.env.staging.example`, but keep its completed values in the host's secret store or an untracked deployment file. The app refuses to start in `staging` or `production` when debug is enabled, the URL is not HTTPS, secure transport/cookies are disabled, CORS is not an explicit HTTPS allow-list, or mail uses a non-delivering driver.
- Keep `CACHE_STORE=database`, `SESSION_DRIVER=database`, and `QUEUE_CONNECTION=database`. The MySQL database needs the migrated `cache`, `cache_locks`, `sessions`, `jobs`, `job_batches`, and `failed_jobs` tables. Set `DB_QUEUE_RETRY_AFTER=120`, which is deliberately greater than the worker timeout of 60 seconds.
- Set `APP_HOSTNAME` to the public API DNS name and point both TCP 80 and 443 at the host before starting Compose. A LAN address such as `192.168.x.x` cannot receive a publicly trusted ACME certificate and is not a substitute for staging.

## Remaining operational decisions

Render is the current staging target. The next deployment must retain its
managed TLS and secret store, with separate web, worker, and Scheduler
services. The still-open decisions are operational rather than architectural:

1. **Promotion control** — CI has no automatic Render deploy step. A named
   operator must deploy only a reviewed commit and record the resulting
   revision before staging is treated as current.
2. **Alert routing** — `app:ops-snapshot`, Render logs, and database queue
   inspection are available, but an on-call destination and owner for their
   alerts still need to be configured externally.
3. **Worker capacity** — start with one database worker and choose any
   additional worker count only after queue-lag and MySQL-contention evidence.

## Checklist for the next deployment
- [ ] Confirm the existing Render web, worker, and Scheduler services are the intended targets and inject staging secrets through Render (never commit them).
- [ ] For a self-hosted equivalent only, point the staging domain at the host, issue TLS, and run `docker compose -f docker/docker-compose.yml up -d`.
- [ ] Run migrations (`php artisan migrate --force`) against the staging database — **never** against production data.
- [ ] Run a dedicated queue worker with `php artisan queue:work database --queue=publishing,default --tries=3 --backoff=10,30,60 --sleep=3 --timeout=60 --max-time=3600`; both queue names are required.
- [ ] Run Scheduler independently every minute (`/usr/local/bin/scheduler-render` on Render, or `* * * * * php artisan schedule:run` elsewhere). It must not be merged into or replaced by the queue worker.
- [ ] Monitor database queue depth and failures through the `jobs`, `failed_jobs`, and `dead_letter_jobs` tables, Render logs, `php artisan queue:failed`, and the scheduled `app:ops-snapshot` output. Horizon is not available because this topology deliberately has no Redis.
- [ ] Load-test MySQL queue lag and contention before increasing worker count; do not horizontally scale workers solely because the database queue accepts more consumers.
- [ ] Register the staging redirect URI with each real OAuth provider (Facebook/Telegram) alongside production's.
- [ ] Point a staging build of the Flutter app at the staging API base URL (`--dart-define` flags, same mechanism already used for local dev — see `app_providers.dart`).
- [ ] Confirm `app:ops-snapshot` and the daily `app:backup-database` schedule are both running on staging (`php artisan schedule:list`).
- [ ] Record the deployed Git revision and smoke-test result; source changes alone are never staging evidence.
- [ ] Verify `https://<staging-host>/up` and an unauthenticated API request expose HSTS, CSP, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, and `Permissions-Policy`, with no `X-Powered-By`.
- [ ] Send a password-reset email and an email-verification email to an isolated staging mailbox; open each link from a physical Android test device and complete the flow.
