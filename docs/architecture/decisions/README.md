# Architectural Decision Records

Short records of decisions that would otherwise only live in commit messages, chat history, or a departed contributor's memory. New ADRs should follow the same shape: Status, Context, Decision, Consequences.

| # | Title | Status |
|---|---|---|
| [0001](0001-repository-riverpod-not-cqrs.md) | Repository + Riverpod-as-DI + Outbox, not CQRS/Mediator/Policy-Engine | Accepted |
| [0002](0002-dedicated-action-endpoints.md) | Dedicated action endpoints for schedule/publish, never the generic update | Accepted |
| [0003](0003-honest-per-platform-formatting.md) | Honest per-platform rich text — never a WYSIWYG that misrepresents capability | Accepted |
| [0004](0004-sqlite-banned-for-concurrent-queues.md) | SQLite is never acceptable for a deployment running more than one queue worker | Accepted |
| [0005](0005-no-multi-tenant-billing.md) | Single-tenant, role-based product — no plans/subscriptions/billing | Accepted |
| [0006](0006-inbound-webhook-receiver.md) | Inbound platform webhook receiver — signature/secret-verified, database-queued, best-effort subscription | Accepted |
| [0007](0007-persistent-local-caches-for-drafts-and-analytics.md) | Drafts and last-viewed analytics are real, persistent local caches — not in-memory-only stand-ins | Accepted |
| [0008](0008-spacing-token-enforcement.md) | Enforce the existing spacing token scale with a CI script, not a new lint package | Accepted |
| [0009](0009-openapi-doc-drift.md) | `docs/api/openapi_v1.yaml` drift — fixed the known items, flagged a structural cause | Accepted |
