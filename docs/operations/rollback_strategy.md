# Rollback Strategy

Automated rollback is deliberately **not** implemented in this repository.
`scripts/rollback.ps1` fails rather than printing a deceptive success message.
The deployment owner must establish and test the real rollback procedure for
the chosen Firebase distribution and backend hosting targets before external
closed-beta invitations.

## Required operator procedure

1. Assign an incident owner and stop new release workflow runs.
2. Identify the prior verified signed AAB, its version code, SHA-256, and
   Firebase App Distribution record.
3. Use the authorised Firebase distribution process to re-distribute the
   prior artifact to the closed-beta tester group.  Record the resulting
   release URL; do not claim a rollback merely because a shell script ran.
4. Roll back backend code/configuration only through the hosting provider's
   documented process.  Do not perform destructive database rollbacks without
   a tested backup and migration plan.
5. Run the staging smoke path: login, organisation selection, draft, upload,
   approval, publish/schedule, status, and notification.
6. Keep the incident evidence, queue/DLQ state, and audit logs for the
   follow-up investigation.

## Release blocker

If the operator cannot identify a prior signed artifact and a tested backend
rollback path, the release is not ready.  A checklist or UI switch is not a
rollback mechanism.
