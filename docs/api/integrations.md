# OAuth & Platform Integrations — Closed Beta

**Release scope:** closed beta only.  Production is intentionally limited to
Telegram and Facebook **Pages**.  This is a server-enforced allow-list, not a
client-side visibility convention.

The word `Available` below means that a guarded implementation path exists.  It does
**not** mean the provider is approved, configured, or ready for external
testers.  Until the Meta gate and the staging evidence below are complete,
Facebook access is limited to the release owner's permitted app-role testing
and is not a launch claim.

| Provider | Closed-beta production behaviour | Delivery implementation |
|---|---|---|
| Telegram | Implemented closed-beta path after a bot is connected and made an administrator of the target channel; real staging evidence is still required. | Telegram Bot API (`getMe`, `getChat`, `sendMessage`) |
| Facebook Page | Implemented Page-only OAuth and publishing path, pending Meta approval and real Page staging evidence before external beta use. | Facebook Graph API |
| Instagram, WhatsApp, X, LinkedIn and every other provider | `Coming soon`; connection and publishing are rejected in production. | No production delivery path |

`GenericOAuthProvider` can still be used in non-production automated tests.
It must never be treated as proof of a live integration, and production rejects
it rather than fabricating a successful publish.

## Connection flows

- **Telegram:** `POST /users/{user}/social-accounts/telegram/connect` accepts a
  bot token, verifies it with Telegram, then the user adds a channel.  The bot
  must already have permission to post in that channel.
- **Facebook Pages:** `POST /users/{user}/social-accounts/authorize`, followed
  by `/callback`, completes the OAuth flow.  Only discovered targets whose
  `kind` is `page` are eligible for closed-beta publishing; discovering an
  Instagram business account through Facebook does not enable Instagram
  publishing.
- **Mobile callback:** Android declares
  `smartpublisher://oauth/callback`.  Register the exact redirect URI used by
  the deployed client in each provider console; do not use a localhost or
  debug-only URI in production.

## Publishing and reliability

Every selected target is represented by an individual
`post_publication_attempts` row.  A publish batch remains `publishing` until
all of its target attempts settle.  It becomes `published` only when every
target succeeded; a terminal failure stays visible and is routed to the DLQ.
Retries re-use the exact original attempt and idempotency key.

The backend also refuses a non-allow-listed target in `APP_ENV=production`.
The Flutter client hides its controls as an additional usability safeguard;
the server is the trust boundary.

## Facebook / Meta App Review release gate

Before inviting any tester who is not an app-role user, the release owner must
complete and record all items below in the deployment evidence:

1. Configure the final privacy-policy URL, terms URL, support contact, and
   data-deletion-instructions URL in the Meta app dashboard.
2. Request only the least Facebook Page permissions actually exercised by the
   beta.  For the current Page-listing and Page-posting flow, review the
   current Meta dashboard requirements for `pages_show_list`,
   `pages_read_engagement`, and `pages_manage_posts`; permissions and access
   tiers can change, so the dashboard is authoritative at release time.
3. Complete any business verification / advanced-access requirement shown by
   Meta for the configured app and requested permissions.
4. Submit a current screencast and reviewer test account that demonstrate the
   exact closed-beta flow: sign in, connect Facebook, choose a Page, create a
   post, publish it, and verify the Page post.
5. Record the Graph API version, App ID, approved scopes, redirect URI, tester
   account, Page ID, and the date of a real staging publish.  Do not put any
   token or App Secret in this repository or in evidence files.

No completion of these Meta items is asserted by this repository.  They are
external release gates, even if a local or app-role OAuth flow appears to
work.

## Configuration safety

Provider credentials belong only in the deployment secret store or a
gitignored `.env`.  `SocialAccount` access and refresh tokens are encrypted at
rest by Laravel casts.  Rotate a credential in the provider console and the
secret store if it is ever exposed.
