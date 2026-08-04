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

The deployment operator determines the retention period for operational data
and backups.  Before public rollout, the operator must publish that period,
the legal entity name, jurisdiction, and a reachable support contact at the
same public URL configured in the provider dashboards.  Production traffic is
TLS-only on Android; credentials must be supplied through a secret store, not
committed configuration.

## Access and deletion

An authenticated user can submit a deletion request through the documented
API in [data-deletion.md](data-deletion.md).  The deployment operator must
verify and process the request, including provider-token revocation and any
required legal retention exceptions.  See that document for the exact
endpoint and response behaviour.

## Contact

The current source repository does not contain a real public support address.
Publishing this policy to a public HTTPS URL and adding the operator's live
support contact are mandatory external release gates before Meta App Review or
tester invitations.
