# ADR-0003: Honest per-platform rich text — never a WYSIWYG that misrepresents capability

**Status:** Accepted (product decision confirmed explicitly by the user before implementation)

## Context

Facebook, Instagram, and WhatsApp do not support real bold/italic formatting in a published post at all — any `**`/`_` markers would show as literal asterisks/underscores to the real recipient. Telegram genuinely supports it via `parse_mode: HTML`. A generic rich-text editor (WYSIWYG) would either (a) falsely show bold/italic in the composer for platforms that can't actually render it, misleading the user about what will really be published, or (b) require per-platform preview logic to predict the real outcome.

The user was asked directly (`AskUserQuestion`) and chose explicitly: **"صادق لكل منصة" (honest per platform)** over a uniform WYSIWYG experience.

## Decision

- A formatting toolbar inserts literal `**bold**`/`_italic_` markers into the shared post body — visible as markers in the raw text, not rendered inline in the editor.
- At actual publish time (`PublishEngineService::publish()`, backend, the single source of truth): the raw content is transformed **per destination provider** — `LiteMarkdown::toTelegramHtml()` for Telegram (real `<b>`/`<i>` HTML), `LiteMarkdown::toPlainText()` for every other provider (markers stripped to clean text, never sent as literal asterisks).
- The Flutter composer mirrors the exact same transform logic (`lib/src/features/composer/domain/lite_markdown.dart`, deliberately duplicated rather than shared since PHP and Dart can't share source) purely to render an accurate *preview* — the preview never overrides or bypasses what the backend will actually do.
- Hashtags and @mentions are real plain text on every platform, so they're highlighted identically everywhere with no per-platform transform needed.

## Consequences

- Two copies of the same small regex-based transform exist (PHP and Dart) and must be kept in sync by hand — accepted tradeoff, documented via cross-referencing comments in both files.
- Any new platform added to the composer must have its own explicit entry in the per-provider transform switch — there is no "default to plain-text-safe" fallback silently assumed; a provider not explicitly handled would need a deliberate decision, matching this project's "never fabricate capability" principle applied elsewhere (health checks, analytics availability flags).
- The per-platform preview card in the composer is the actual verification mechanism a developer or user can use to confirm the promise holds — it was widget-tested specifically to assert Telegram renders real bold while Facebook renders stripped plain text for the identical input.
