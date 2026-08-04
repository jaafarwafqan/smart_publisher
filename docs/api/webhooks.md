# Webhooks API — RETIRED (never actually built)

**2026-07-27**: This document previously described a `POST /api/webhooks/{platform}` endpoint as if it were a real, implemented feature. It never was — there is no webhook route anywhere in `routes/api.php`, no signature-verification code, no handler. It was aspirational documentation written during early scaffolding and never corrected until now.

If you need to know what's actually true about platform integrations (OAuth flows, which providers are real vs. mocked, how publishing actually works), see [`docs/api/integrations.md`](integrations.md).

If inbound webhooks (platform delivery/engagement callbacks) are genuinely needed, that's a real feature to design and build — including signature verification, event routing, and idempotent processing — not something to assume already exists. Track it in `docs/audit/KNOWN_ISSUES.md` under open gaps.
