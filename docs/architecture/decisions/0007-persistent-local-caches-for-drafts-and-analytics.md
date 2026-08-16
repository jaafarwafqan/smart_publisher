# ADR-0007: Drafts and last-viewed analytics are real, persistent local caches — not in-memory-only stand-ins

**Status:** Accepted (2026-08-16, Phase 1 audit of the production-readiness plan)

## Context

The original Phase 1 plan called for "Local Data Sources where offline caching makes sense (drafts, last-viewed analytics)." An audit of the current frontend found that most of Phase 1 (Repository implementations, DTOs/mappers, multi-tenancy header, auth token handling, the organization switcher) was already real and live-verified — see `docs/testing/STATUS.md`'s 2026-08-16 entry for the audit trail. Two concrete, real gaps against that specific line item were found instead:

1. **`DraftStorage`** existed and was wired into `PostRepositoryImpl` (written to on every create/update/delete), but was a plain in-memory `Map` with no `StorageService` backing — unlike `OutboxStore`, which already had this exact hydrate/persist pattern. Worse, its own read methods (`getDraft`/`listDrafts`) were never called by anything: `PostRepositoryImpl.getPost()`/`getPosts()` read from a *second*, separate, equally non-persistent `_inMemoryStore` field instead. The practical effect: a post created or edited while offline was gone from every read path the moment the app process restarted — even though the outbox's own queued mutation (a genuinely different, already-durable concern) would still be sitting there ready to replay once a connection returned. The user just couldn't see or keep editing that draft locally in the meantime.
2. **`AnalyticsRepositoryImpl._cache`** (the write-through cache populated by every real `getPostMetrics`/`getPostsMetrics`/`getDashboard` fetch, and the fallback data source in offline mode) was also a plain in-memory `Map` — the last real numbers a user viewed for a post reset to "no data yet" on every app restart, not just when genuinely offline from the start.

## Decision

- Rewrote `DraftStorage` to mirror `OutboxStore`'s own hydrate-once/persist-on-write pattern against the same `StorageService`, added full `PostEntity` JSON (de)serialization, and wired `draftStorageProvider` to actually pass a `StorageService` instance (it previously constructed a bare `DraftStorage()`).
- Removed `PostRepositoryImpl`'s redundant `_inMemoryStore` field entirely — every read (`getPost`, `getPosts`, `getPostsPage`'s offline branch) and write (`createPost`, `updatePost`, `deletePost`, and both network methods' offline-fallback branches) now goes through `draftStorage`, the one real local data source, instead of two out-of-sync in-memory copies.
- Added `AnalyticsMetricEntity.fromJson` (the existing `toJson` had no inverse) and gave `AnalyticsRepositoryImpl` the identical hydrate/persist pattern against `StorageService`, wired through `analyticsRepositoryProvider`.

## Consequences

- A post drafted or edited while offline, and the last real analytics numbers a user viewed, both now survive an app restart — not just a hot reload.
- Both caches remain explicitly a *cache*, never a source of truth: the server (for drafts, via the already-durable `OutboxStore` replay) or a fresh fetch (for analytics) is still authoritative. Corrupted persisted JSON is discarded and the app starts clean rather than crashing, same failure mode `OutboxStore._hydrate()` already established.
- New tests: `test/unit/offline/draft_storage_persistence_test.dart` and `test/unit/offline/analytics_cache_persistence_test.dart`, mirroring `outbox_store_persistence_test.dart`'s own "survives being recreated with the same backing storage" pattern — including an explicit "without a storage backend, this does NOT survive recreation" test in both, documenting the exact gap being closed rather than only testing the fixed behavior.
