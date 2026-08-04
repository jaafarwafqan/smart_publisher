# ADR-0001: Repository + Riverpod-as-DI + Outbox, not CQRS/Mediator/Policy-Engine

**Status:** Accepted (retroactively documented 2026-07-27; the decision itself was made 2026-07-24)

## Context

Early commit messages on both the Flutter app and the Laravel backend claimed a CQRS/Mediator/Policy-Engine architecture ("implement CQRS structure", "add architecture docs, validators, policies, and mappers"). A CTO-level audit (`docs/audit/ROUND1_CTO_AUDIT.md`) found this was never actually true: `app/Domain/*`, `app/Application/{Handlers,UseCases}`, `app/Infrastructure/{Repositories,Persistence}` (Laravel) and `lib/src/application/{mediators,pipelines,transactions}` (Flutter) were 0-byte files or empty directories, never wired to anything real. All actual business logic lived directly in Controllers (Laravel) and screens calling repositories directly (Flutter) — the "advanced" layers were pure documentation fiction.

## Decision

Delete the empty scaffolding rather than retroactively implement it to match the old docs, and document the architecture that actually exists and works:

- **Flutter**: `Screen -> ref.read(xRepositoryProvider) -> RepositoryImpl -> BackendContractMapperV1 (DTO<->Entity) -> NetworkClient -> Laravel API`. On `NetworkFailure`, writes fall back to local storage + an `OutboxStore` entry, drained later by `SyncWorker`. Riverpod is used purely as a dependency-injection container — no CQRS command/query split, no mandatory use-case layer between screen and repository (screens call repositories directly).
- **Laravel**: standard Controller -> Eloquent Model -> Resource, no Domain/Application/Infrastructure DDD layering. Business rules that need reuse live in narrowly-scoped Services (e.g. `PublishEngineService`, `SocialPageSyncService`, `DashboardCacheService`), not a generic handler/use-case abstraction.

`application/{policies,validators,mappers}` (Flutter) were treated differently from the deleted scaffolding — they are non-empty, working code, just not wired into the live request flow. Whether to adopt or delete them is left as an open, deliberate decision (see `docs/audit/KNOWN_ISSUES.md`), not bundled into this ADR.

## Consequences

- New contributors should read `docs/architecture/request_flow.md` for the real flow, not infer one from commit history.
- Any future "let's add proper CQRS" proposal should be a fresh, deliberate ADR with real product justification — not a rediscovery of the deleted scaffolding.
- The tradeoff accepted: less structural ceremony per feature, at the cost of screens/controllers doing more directly. This has proven workable through Media Library, Composer, and Calendar/Scheduling all being built and fixed this way without needing the deleted layers.
