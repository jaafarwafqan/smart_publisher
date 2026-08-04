# Roles, Permissions, Plans & Subscriptions

**Last verified:** 2026-07-27, against `RolesAndPermissionsSeeder.php`, `config/permission.php`, and every `permission:` route middleware in `routes/api.php`.

## Plans & subscriptions: none exist

Read this section first if you came here looking for a billing/tier system — **there isn't one.** Smart Publisher is a single-tenant, role-based internal publishing tool, not a multi-tenant SaaS product. There is no `plans`, `subscriptions`, `billing`, or `invoices` table anywhere in the schema (verified via a full grep of every migration and model), no payment provider integration, and no concept of a user or organization being on a "free" vs. "paid" tier. Every user in the system has the same product surface available to them; access is governed entirely by role/permission, not by what they've paid for.

If the product later needs multi-tenant billing, that is new architecture to design from scratch — not a documentation gap to fill in. Do not infer a plans/subscriptions model from the presence of `branches` (see below); a branch is an organizational/scoping unit, not a billing tenant.

## Authorization model: Spatie `laravel-permission`

Guard: `sanctum`. Teams feature: **disabled** (`config/permission.php: 'teams' => false`). No custom role/permission tables — the migration (`2026_07_20_000005_create_permission_tables.php`) is Spatie's stock, unmodified package migration.

`User` is the only model using `HasRoles`/`HasPermissions` in the codebase today.

### Roles

| Role | Intent |
|---|---|
| `admin` | Full access — every permission in the system, synced automatically in the seeder |
| `manager` | Day-to-day operational access: users (view/update, not create/delete), full social-account + post + media workflow, publishing monitoring, no system-settings access |
| `editor` | Content-focused: create/update/schedule posts, upload media, view accounts/pages — no account management, no user/role administration |

### Full permission list (35 permissions, from `RolesAndPermissionsSeeder`)

```
users.view, users.create, users.update, users.delete
roles.view, roles.assign
permissions.view
branches.view, branches.create, branches.update, branches.delete
tokens.view, tokens.revoke
social-accounts.view, social-accounts.create, social-accounts.update, social-accounts.delete
social-accounts.refresh-token, social-accounts.test-connection, social-accounts.change-status
social-accounts.oauth.authorize, social-accounts.oauth.callback
social-accounts.pages.view, social-accounts.pages.sync, social-accounts.pages.manage
posts.view, posts.create, posts.update, posts.delete, posts.schedule, posts.publish
media.view, media.upload, media.delete
notifications.view
settings.view
system-settings.view, system-settings.manage
publishing.monitor, publishing.manage
```

### Role → permission matrix

| Permission | admin | manager | editor |
|---|:---:|:---:|:---:|
| users.view | ✅ | ✅ | ✅ |
| users.create/update/delete | ✅ | update only | ❌ |
| roles.view / permissions.view | ✅ | ✅ | ❌ |
| roles.assign | ✅ | ❌ | ❌ |
| branches.view | ✅ | ✅ | ✅ |
| branches.create/update/delete | ✅ | ❌ | ❌ |
| tokens.view / tokens.revoke | ✅ | ✅ | ❌ |
| social-accounts.view/pages.view | ✅ | ✅ | ✅ |
| social-accounts.create/update | ✅ | ✅ | ❌ |
| social-accounts.delete | ✅ | ❌ | ❌ |
| social-accounts.refresh-token/test-connection/change-status | ✅ | ✅ | ❌ |
| social-accounts.oauth.* | ✅ | ✅ | ❌ |
| social-accounts.pages.sync/manage | ✅ | ✅ | ❌ |
| posts.view/create/update | ✅ | ✅ | ✅ |
| posts.delete | ✅ | ❌ | ❌ |
| posts.schedule/publish | ✅ | ✅ | ✅ |
| media.view/upload | ✅ | ✅ | ✅ |
| media.delete | ✅ | ✅ | ❌ |
| notifications.view | ✅ | ✅ | ✅ |
| settings.view | ✅ | ✅ | ✅ |
| system-settings.view/manage | ✅ | ❌ | ❌ |
| publishing.monitor | ✅ | ✅ | ❌ |
| publishing.manage | ✅ | ❌ | ❌ |

## Enforcement mechanics — two layers, used inconsistently by design history (not a bug, but worth knowing)

1. **Route middleware** (`->middleware('permission:posts.view')` etc.) — most routes in `routes/api.php` are gated this way. This is the primary, consistent gate.
2. **Policies** (`SocialAccountPolicy`, `PostPolicy`, `MediaAttachmentPolicy`) — object-level ownership checks (`$this->authorize('update', $socialAccount)` etc.), layered *on top of* the route-level permission gate for the specific object being touched, not a replacement for it.

Known inconsistency (recorded in `docs/audit/KNOWN_ISSUES.md`, not something to "fix" without a product decision first): `posts.update/delete/schedule/publish` and `media.delete` rely on Policy checks inside the controller rather than a `permission:` route middleware like most other routes. This was never a deliberate design choice, just how the routes evolved — flagged, not silently corrected, since changing route-level enforcement is a security-relevant decision that shouldn't be made without product sign-off.

## Branch scoping — organizational unit, not a tenant/billing concept

`users.branch_id` and `posts.branch_id` (both nullable, `nullOnDelete`) are the real scoping concept in this system — think "office/department," not "customer account." There is **no** enforced branch-level data isolation today (a user with `posts.view` can see posts across all branches) — Branch/User-level object ownership scoping was explicitly considered during an earlier audit round and *not* added, because no existing business rule justified it and guessing one risked breaking legitimate admin workflows. If branch-scoped visibility is ever wanted, that's a real product decision to make first, not an assumed requirement.

## Fixed security findings relevant to this model (for context, not re-verification)

- Privilege escalation via `UserController::update` accepting a `roles` field without `roles.assign` — fixed; role assignment is now only possible via `store()` (creation, itself gated) or the dedicated `/users/{user}/roles` endpoint (which requires `roles.assign`).
- `SocialAccountPolicy` was written but unused for a period (controller repeated manual ownership checks 5×) — fixed, wired via `$this->authorize(...)`.
- Permission cache had a 24h TTL with no invalidation on change (`events_enabled: false`) — fixed (`events_enabled: true`), so a revoked permission takes effect immediately, not up to a day later.
