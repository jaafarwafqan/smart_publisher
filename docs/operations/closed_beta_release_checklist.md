# Closed-Beta Release Checklist

This checklist is deliberately a release gate, not a claim that production is
already live.  Record the date, operator, environment, and evidence location
for every checked item.  The supported distribution is Android closed beta
only; this checklist cannot attest to a web deployment, a backend deployment,
a canary rollout, or an automated rollback.

## 1. Build and security gates

- [ ] Frontend CI is green: format check, `flutter analyze`, all Flutter
  tests, release-hardening scan, and secret scan.
- [ ] Backend CI is green: Composer validation, Pint, PHPStan with no
  `continue-on-error`, PHPUnit, and the MySQL 8.4 concurrency/isolation job.
- [ ] Android release signing variables are injected by the CI secret store;
  `verifyReleaseSigning` passes with a non-debug keystore.
- [ ] The Android-only `closed-beta` release workflow has a real Firebase App
  Distribution app ID, token, and tester group.  Missing values must fail the
  workflow; a local build is not distribution evidence.
- [ ] No `.env`, token, private key, keystore, or signing password is tracked
  or embedded in the produced APK/AAB.
- [ ] Staging uses HTTPS, a separate `APP_KEY`, and a production-shaped
  MySQL/InnoDB + queue worker configuration.

## 2. Required staging smoke test

Run this with two organisation memberships and record the request IDs:

1. Sign in, switch organisation, and verify the member sees only the posts
   permitted by that membership.
2. Create a draft, upload an allowed media file, attach it, and reopen it.
3. As an editor, submit schedule/publish for approval; as an authorised
   reviewer, approve and reject separate requests.  Verify both **in-app**
   notifications (push delivery is not implemented).
4. Publish a two-target test post using two configured Telegram channels, or
   Telegram plus a Facebook **Page** only after the Meta gate is complete.
   Verify that it remains `publishing` after the
   first target and becomes `published` only after every target succeeds.
5. Induce one retryable failure and one permanent failure in staging.  Verify
   backoff, the original idempotency attempt, DLQ visibility, final status,
   and a notification without duplicate provider posts.
6. Verify a real Telegram sandbox publish and cleanup.  After the Meta gate,
   verify a real Facebook **Page** staging publish, view the Page post, and
   perform the documented cleanup.  Never use a personal profile as a Page
   substitute.
7. Confirm Instagram, WhatsApp, X, LinkedIn, and all other unsupported
   providers show `Coming soon` in the client and receive a production
   rejection from the API.

## 3. Meta release evidence

- [ ] Final public HTTPS privacy-policy, terms, support, and data-deletion
  URLs are live and entered in the Meta app dashboard.
- [ ] The exact redirect URI, app ID, Graph API version, approved scopes, and
  access tier are recorded.  Re-check the dashboard for current Page
  permission / App Review requirements immediately before submission.
- [ ] Business verification / advanced access is complete if Meta requires it.
- [ ] A reviewer account, test Page, and current end-to-end screencast are
  supplied.  The screencast shows login, consent, Page selection, post
  creation, publish, and visible Page result.
- [ ] No credential appears in the evidence, the screen recording, CI logs,
  issue tracker, or this repository.

## 4. Go / no-go

Do not invite external beta users until every applicable box above is checked
and a responsible operator signs the deployment evidence.  A failed local
Docker, MySQL, secret-scan, signed-release, Firebase-distribution, or
real-provider check is a blocker, not a warning to waive silently.  A canary
switch or a successful local rollback script cannot waive this gate: neither
is an implemented production control.
