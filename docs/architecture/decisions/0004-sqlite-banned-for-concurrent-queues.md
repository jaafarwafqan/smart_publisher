# ADR-0004: SQLite is never acceptable for a deployment running more than one queue worker

**Status:** Accepted (2026-07-25, from the Production Readiness Audit)

## Context

Local development and much of this project's live-testing history ran against an ephemeral SQLite database (`.env`'s committed setting is `DB_CONNECTION=mysql`, but MySQL was not installed on the dev sandbox machine). During concurrent-publishing load testing, `config/database.php`'s SQLite connection had `busy_timeout`/`journal_mode`/`synchronous` all hardcoded to `null` — meaning even 2 concurrent writers hit an immediate hard "database is locked" `PDOException` instead of waiting. This was fixed by wiring those settings to env vars with safe defaults (`busy_timeout=5000`, `journal_mode=WAL`, `synchronous=NORMAL`).

**Even after that fix, the same locking error persisted** under real concurrent queue workers, despite `PRAGMA busy_timeout=5000` being confirmably active. This points to a known PDO-SQLite-on-Windows limitation where the busy_timeout pragma does not reliably gate multi-process contention the way the SQLite documentation describes for single-process multi-threaded use.

## Decision

**SQLite must never be used in any environment running more than one concurrent queue worker process.** Production is already configured for MySQL (`.env`'s `DB_CONNECTION=mysql` was never changed) — this ADR exists to make explicit and permanent a constraint that was discovered empirically, not to change any current configuration. The Docker Compose setup (`docker/docker-compose.yml`) provisions MySQL for exactly this reason, with an inline comment restating the constraint next to the `queue-worker` service.

## Consequences

- Anyone tempted to "simplify" a deployment (staging, demo, a quick fix) by pointing `DB_CONNECTION` at SQLite must not do so if more than one queue worker will run against it.
- Test suites are unaffected — PHPUnit's `phpunit.xml` uses SQLite `:memory:`, which is single-process by construction (no real concurrency to trigger the bug).
- Load-testing numbers captured against SQLite in the Production Readiness Audit (7-8× p95 latency degradation at concurrency=10, ~4.3s/job queue throughput) are explicitly flagged there as environment-limited and due for re-verification against real MySQL + php-fpm before being treated as production capacity numbers.
