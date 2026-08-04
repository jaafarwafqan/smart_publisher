# Closed-Beta Support

For privacy and account-data requests, use the authenticated deletion-request
endpoint documented in [data-deletion.md](data-deletion.md).  Include the
returned request ID in any follow-up with the deployment operator.

For a publishing incident, capture the post ID, organisation ID, target type
(Telegram channel or Facebook Page), approximate time, and visible error
message.  Do **not** include access tokens, bot tokens, passwords, API
secrets, or APK signing credentials.  The operator can use the
[incident runbook](../operations/incident_runbook.md) and the DLQ record to
investigate safely.

Before sending closed-beta invitations, the operator must replace this
repository-only support path with a real monitored support email or HTTPS
contact form and publish it alongside the privacy policy and terms.  That is
an external launch prerequisite, not an implemented claim.
