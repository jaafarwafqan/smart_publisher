# ADR-0002: Dedicated action endpoints for schedule/publish, never the generic update

**Status:** Accepted (2026-07-27)

## Context

`publishNow()` was implemented correctly from early on: a dedicated `POST /posts/{id}/publish-now` endpoint and a matching `PostRepository.publishNow()` method, entirely separate from the generic `updatePost()`/`PUT /posts/{id}` path. When scheduling was later added, it was implemented differently — `SchedulePost` reused `PostRepository.updatePost()`, whose request DTO (`PostUpdateRequestDtoV1`) only ever serialized `title`/`content`/`target_page_ids`/`meta`. Clicking "Schedule" in the composer silently updated the title/content and **never actually changed the post's status or scheduled_at server-side** — a real, live-reproduced bug (verified 2026-07-27 by publishing to a real Telegram channel and inspecting the actual HTTP traffic).

## Decision

Every state-transition action on a Post (`schedule`, `publish-now`, `draft`/revert-to-draft) gets its **own dedicated backend endpoint and its own dedicated repository method** — never routed through the generic `update()`/`updatePost()` path, even though it might seem like less duplication to reuse it. `SchedulePost` was fixed to follow the same pattern `publishNow` already used: a small `ScheduleRequestDtoV1` (just `scheduled_at`), a dedicated `ScheduleRepository.schedulePost()`, hitting `POST /posts/{id}/schedule` directly.

## Consequences

- The generic update DTO can stay narrowly scoped (title/content/target_page_ids/meta) without needing to anticipate every future state-transition field.
- A new action (e.g. "archive a post") should get its own endpoint + repository method from the start, not be bolted onto `update()`.
- This pattern has no built-in offline/outbox fallback (unlike `create`/`update`/`delete`, which queue to `OutboxStore` on network failure) — these are inherently server-driven actions. If offline scheduling is ever wanted, that needs its own deliberate design (see the open question in `docs/audit/KNOWN_ISSUES.md`), not an assumption that the existing outbox mechanism already covers it.
