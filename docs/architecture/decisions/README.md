# Architectural Decision Records

Short records of decisions that would otherwise only live in commit messages, chat history, or a departed contributor's memory. New ADRs should follow the same shape: Status, Context, Decision, Consequences.

| # | Title | Status |
|---|---|---|
| [0001](0001-repository-riverpod-not-cqrs.md) | Repository + Riverpod-as-DI + Outbox, not CQRS/Mediator/Policy-Engine | Accepted |
| [0002](0002-dedicated-action-endpoints.md) | Dedicated action endpoints for schedule/publish, never the generic update | Accepted |
| [0003](0003-honest-per-platform-formatting.md) | Honest per-platform rich text — never a WYSIWYG that misrepresents capability | Accepted |
| [0004](0004-sqlite-banned-for-concurrent-queues.md) | SQLite is never acceptable for a deployment running more than one queue worker | Accepted |
| [0005](0005-no-multi-tenant-billing.md) | Single-tenant, role-based product — no plans/subscriptions/billing | Accepted |
