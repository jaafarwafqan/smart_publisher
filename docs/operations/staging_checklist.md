# Staging Environment Checklist

**New 2026-07-29** (CTO audit Sprint 6). This does not stand up a real
staging host — that needs the user's decision on where it actually runs
(see "Open decisions" below). What this documents: everything that's
already buildable today with what exists in the repo, so standing up
staging is a checklist against real assets, not a from-scratch project.

## What already exists and can be reused as-is
- `docker/docker-compose.yml` + `docker/Dockerfile` + `docker/nginx.conf` (backend) — PHP-FPM + Nginx + MySQL + Redis, production-shaped. The same compose file works for staging; only the `.env` values change (see below).
- `.github/workflows/ci.yml` (both repos) — already runs on every push/PR to `main`. Staging deploys should trigger from this pipeline once a target host exists, not be a separate manual process.
- `app:backup-database` / `app:restore-database` — usable on staging exactly as on production (see `backup_strategy.md`).
- `app:ops-snapshot` (new this pass) — same scheduled health check works unmodified on staging.

## Staging-specific `.env` differences from production
- `APP_ENV=staging` (not `production` — some Laravel behaviors, like detailed error pages, key off this).
- A **separate** `APP_KEY` from production — never reuse production's key on staging, since staging data (including encrypted `SocialAccount` tokens) must never be decryptable by leaking a staging credential, and vice versa.
- Separate OAuth app credentials/redirect URIs per provider where the provider allows it (Facebook/Telegram/etc. developer consoles usually support multiple registered redirect URIs — add the staging one alongside production's, don't reuse).
- `SOCIAL_ALLOWED_REDIRECT_URIS` (added this pass) must include whatever redirect URI the staging build of the Flutter app actually uses.

## Open decisions (need the user, not an engineering guess)
1. **Hosting provider/target** — a VPS running the existing Docker Compose file directly, or a managed platform (e.g. Fly.io, Render, a cloud provider's container service)? This changes how CI's deploy step (not yet written) would actually push a new build out.
2. **Domain + TLS** — a staging subdomain (e.g. `staging-api.<domain>`) and where its certificate comes from (Let's Encrypt via the host, or a load balancer in front of it).
3. **Secrets injection** — how staging's `.env` values (DB password, `APP_KEY`, OAuth secrets) get onto the host without ever being committed to git. Common options: the hosting platform's own secrets manager, or a `.env.staging` pulled from a secrets store at deploy time — needs picking one, not inventing a bespoke mechanism.

## Checklist once the above are decided
- [ ] Provision the host / managed service.
- [ ] Point the staging domain at it, issue a TLS cert.
- [ ] Inject staging `.env` secrets via the chosen mechanism (never commit them).
- [ ] Run `docker compose -f docker/docker-compose.yml up -d` (or the managed-platform equivalent).
- [ ] Run migrations (`php artisan migrate --force`) against the staging database — **never** against production data.
- [ ] Register the staging redirect URI with each real OAuth provider (Facebook/Telegram) alongside production's.
- [ ] Point a staging build of the Flutter app at the staging API base URL (`--dart-define` flags, same mechanism already used for local dev — see `app_providers.dart`).
- [ ] Confirm `app:ops-snapshot` and the daily `app:backup-database` schedule are both running on staging (`php artisan schedule:list`).
- [ ] Add a CI deploy step once the target is chosen, so staging updates automatically from `main` instead of manual redeploys.
