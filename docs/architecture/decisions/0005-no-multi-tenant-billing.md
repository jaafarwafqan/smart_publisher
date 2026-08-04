# ADR-0005: Single-tenant, role-based product — no plans/subscriptions/billing

**Status:** Accepted (implicit from day one; made explicit 2026-07-27 after being asked to document a plans/subscriptions system that doesn't exist)

## Context

A documentation request asked for "roles, permissions, plans, and subscriptions" to be documented as if all four were established parts of the product. A full audit of every migration and model confirmed: roles and permissions are real (Spatie `laravel-permission`, three roles: admin/manager/editor), but **no plans, subscriptions, billing, or invoices table or concept exists anywhere in the codebase.**

## Decision

Document reality, not the request's assumption: this is a single-tenant, role-based internal publishing tool. Every user has the same product surface available; access is governed entirely by role/permission, never by what they or their organization has paid for. `branches` is a real organizational-scoping concept (e.g. "which office/department"), explicitly **not** a billing tenant — conflating the two would misrepresent both.

## Consequences

- `docs/architecture/permissions_and_roles.md` states this explicitly and up front, rather than silently omitting the plans/subscriptions section (which could read as an oversight) or fabricating one (which would actively mislead).
- If the product ever needs multi-tenant billing, that is new architecture to design — a new ADR, new migrations, a payment provider integration, tier-gating logic throughout the API — not a "wire up what's already there" task. Nothing here should be reused as a starting point beyond the existing `branches`/role model, and even that would need real reconsideration (branches are not currently isolated from each other at the data level either — see the open Branch-scoping question in `docs/audit/KNOWN_ISSUES.md`).
