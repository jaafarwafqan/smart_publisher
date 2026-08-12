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

Real, monitored support contact: <jaafarw.alkuby@uokufa.edu.iq>. Published
alongside the privacy policy and terms at `/legal/privacy-policy`,
`/legal/terms-of-service`, and `/legal/data-deletion` on the deployed
backend (2026-08-12).
