# ADR-0009: `docs/api/openapi_v1.yaml` drift — fixed the known items, flagged a structural cause

**Status:** Accepted (2026-08-16, Phase 2 documentation-consistency pass)

## Context

A Phase 1 audit (see STATUS.md's own entry) had already found that `docs/api/openapi_v1.yaml` documented `/accounts`, `/accounts/connect`, `/accounts/{account}` as a "legacy/broken but still registered" route group — but those routes are not merely broken, they were **deliberately removed** from `routes/api.php` entirely (Sprint 2, API Hardening) — this repo's own hard constraint says never resurrect `AccountController`. The same audit found the file was missing ~20 real routes that exist in `routes/api.php`: Organizations, platform Admin, the approval workflow (`approve`/`reject`/`cancel`), `native-connect`, and the new Webhooks receiver (ADR-0006).

Fixing this surfaced a second, more significant finding: `smart_publisher_backend/resources/openapi/openapi.json` — the file actually served by `GET /api/v1/openapi.json` (`OpenApiSpecController`) — already had every one of these routes correct. The drift was never "this API isn't documented anywhere"; it was specifically that `docs/api/openapi_v1.yaml` is a **second, independently hand-maintained copy** that fell behind the first one. Continuing the sweep also surfaced that the served spec documents an entire Auth/Sprint-4 surface (`/auth/register`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/email/verify/...`, the four `/auth/two-factor/*` routes, `/account/data-export`, and the bare `/login`/`/refresh` aliases) that `docs/api/openapi_v1.yaml` was already missing **before** this session and still is — that surface predates this pass and was deliberately not replicated here; see Consequences.

## Decision

- Removed the dead `/accounts/*` section and its tag from `docs/api/openapi_v1.yaml`.
- Fixed the one place that same dead pattern had leaked further: `POST /users/{user}/social-accounts` was documented as a still-working "directly link a social account, bypasses OAuth" endpoint — that generic manual-link endpoint was also removed (Sprint C, role/permission remediation); replaced with the real `native-connect` endpoint that exists in its place.
- Added concise (not full-schema-detail, matching this session's own approved scope) entries for Organizations, platform Admin, Posts `cancel`/`approve`/`reject`, and the new Webhooks receiver, plus `publishing/dead-letters/{deadLetterJob}/retry` (found missing along the way).
- Did **not** attempt to also hand-replicate the entire Auth/Sprint-4 surface into this file in the same pass — that gap is unrelated to what this pass was scoped to fix, and doing it by further manual duplication would just add more surface for the next drift instead of addressing the actual cause.

## Consequences

- `docs/api/openapi_v1.yaml`'s own `info.description` now says explicitly, in the document itself, exactly which routes it still doesn't cover and points at the backend's served `/openapi.json` as the more current source for those — an honest, narrower claim rather than a blanket "reflects the real, current route table" that would itself now be inaccurate.
- **Open recommendation, not yet decided**: this project maintains two independent OpenAPI documents for the same API — this file (frontend repo, docs-only) and `resources/openapi/openapi.json` (backend repo, actually served). Every future route change now has two places that can drift, and this ADR's own fix is evidence it already has, more than once. Two ways to close this for good, either is reasonable — recorded here as an open decision, not a foregone one:
  1. Stop hand-maintaining this file independently; make it a thin pointer to `GET /api/v1/openapi.json` as the single canonical source.
  2. Keep both, but add a CI check (in whichever repo's pipeline runs against both checkouts) asserting the two path lists don't diverge — same "script, not vibes" pattern as `check_release_hardening.dart`/`check_spacing_tokens.dart`.
  See `docs/audit/KNOWN_ISSUES.md`'s corresponding open item.
