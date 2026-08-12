# Privacy Policy — Smart Publisher Closed Beta

Effective date: 2026-07-30

Smart Publisher is a closed-beta workspace for drafting, scheduling, and
publishing content to Telegram and Facebook Pages.  This document describes
the product as implemented for the beta; it is not a substitute for a review
by the organisation that operates the deployed service.

## Data processed

The service processes account profile data needed to sign in, organisation and
membership data, drafts and published-post metadata, uploaded media, audit and
operational logs, notification records, and the identifiers and credentials
needed to connect an approved social account.  The application receives only
the provider permissions granted during the connection flow.

Access and refresh tokens for connected social accounts are encrypted at rest
by the backend.  They are used only to provide the requested connection,
Page/channel discovery, and publishing functions.  They are not to be placed
in client-side source code, logs, test fixtures, or documentation.

## Use and sharing

Data is used to authenticate users, enforce organisation membership,
deliver publishing requests, diagnose failures, and operate the service.  A
publish request necessarily sends the selected content and target identifier
to the selected provider.  The service does not enable unimplemented
providers in production or claim that a mock integration has published.

## Retention and security

Operational data is retained for as long as the account remains active.
Following a verified deletion request, account data is retained for up to
**30 days** (to allow the request to be reversed in case of error), then
permanently deleted or anonymised — except where a longer period is required
by applicable law (e.g. financial or audit records). Production traffic is
TLS-only on Android; credentials must be supplied through a secret store, not
committed configuration.

## Access and deletion

An authenticated user can submit a deletion request through the documented
API in [data-deletion.md](data-deletion.md).  The deployment operator must
verify and process the request, including provider-token revocation and any
required legal retention exceptions.  See that document for the exact
endpoint and response behaviour.

## Operator and contact

Smart Publisher is operated by the **University of Kufa — College of
Nursing, Iraq**. For any privacy question, request, or concern, contact
<jaafarw.alkuby@uokufa.edu.iq>.

2026-08-12: this policy, along with [terms of service](terms_of_service.md)
and [data deletion instructions](data-deletion.md), is now published at real
public HTTPS URLs (`/legal/privacy-policy`, `/legal/terms-of-service`,
`/legal/data-deletion` on the deployed backend — see
`resources/views/legal/*.blade.php` and `routes/web.php` in the backend
repo) for Meta App Dashboard's Privacy Policy / Terms of Service / User Data
Deletion fields. This document remains the internal source of truth those
pages are filled in from — keep both in sync on any future change.
