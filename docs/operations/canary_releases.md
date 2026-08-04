# Canary Releases

Canary release controls are not implemented for the current Android
closed-beta distribution.  The app's release-management UI deliberately keeps
canary/release actions disabled because it cannot attest to CI, distribution,
or backend traffic state.

Do not set `SP_RELEASE_CHANNEL=canary`, `SP_CANARY_PERCENT`, or claim that an
`X-Canary-Percent` request header changes a deployed rollout.  The only
supported release channel in `.github/workflows/release.yml` is `closed-beta`.

If a future deployment needs progressive delivery, add a real backend traffic
controller, provider-specific distribution configuration, measured promotion
criteria, audited rollback capability, and automated tests.  Until then,
closed-beta tester groups are the controlled exposure mechanism.
