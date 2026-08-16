# ADR-0008: Enforce the existing spacing token scale with a CI script, not a new lint package

**Status:** Accepted (2026-08-16, Phase 5 UI/UX token-discipline audit)

## Context

The original UI/UX plan's "Token discipline" item asked for a real design-token system (colors, spacing, radii, typography, elevation) "enforced via lint rule or code review checklist so no new widget hardcodes a raw color/spacing value." An audit found the token system itself already existed and was already well-adopted: `lib/src/core/theme/{app_colors,app_spacing,app_radius,app_elevation,app_duration,app_curves}.dart`, and zero raw `Color(0x...)` literals anywhere under `lib/src/features`. The one real, concrete gap was spacing specifically: `AppSpacing` (a 6-step scale: 4/8/12/16/24/32) existed and was already imported in 35 of the ~40 files that call `EdgeInsets`, but a same-file mix of `EdgeInsets.all(AppSpacing.lg)` next to `EdgeInsets.all(16)` showed the token wasn't consistently used even where it was already imported — and nothing enforced it, so the drift could only grow.

A first grep-based estimate of the scope ("163 raw literals across 40 files") turned out to be a measurement artifact of an overly broad pattern (`padding: const EdgeInsets` matches unconditionally, with no digit requirement, so it counted every `EdgeInsets` call including ones already using a token). The real, precise scope — every `EdgeInsets.all()`/`.symmetric()`/`.only()` named-argument value and every standalone `SizedBox(height:)`/`SizedBox(width:)` value that exactly matches the `AppSpacing` scale — was 22 occurrences across 3 files, found by re-running the check with an exact-match regex instead of a loose one.

## Decision

- Fixed the 22 real occurrences (`email_verification_banner.dart`, `account_data_deletion_screen.dart`, `account_data_export_screen.dart`) via a one-off mechanical script (not committed — same throwaway-codemod spirit as any one-time migration), then added the missing `app_spacing.dart` import to each of the 3 files.
- Added `scripts/ci/check_spacing_tokens.dart`, a pure-Dart-SDK, no-network CI gate mirroring `check_release_hardening.dart`'s own shape and its `docs/api/...`-adjacent "use only the Dart SDK" convention — **not** a new `custom_lint` package dependency, since introducing one needs the operator's explicit sign-off per this project's "ask before any new third-party package" rule, and a plain script does the same job here with zero new dependencies. Wired into `.github/workflows/ci.yml` right after the existing release-hardening step.
- The check is deliberately narrow, same philosophy as `check_release_hardening.dart`: it does not flag `EdgeInsets.fromLTRB` (positional args, harder to attribute safely without a false positive), a bare `height:`/`width:` on any widget other than `SizedBox` (a `Container`/`Image`/`ConstrainedBox` fixed pixel dimension is a real, unrelated design decision — not spacing), or any value that doesn't exactly match the token scale (an off-scale value like `EdgeInsets.symmetric(vertical: 2)` or `EdgeInsets.only(top: 6, ...)` is a deliberate design choice this check does not second-guess).

## Consequences

- A new raw on-scale spacing literal under `lib/src/features` now fails CI, not just a hoped-for review-checklist habit.
- The check's narrow scope means it is not a claim of zero spacing inconsistency — an off-scale raw value (2px, 6px, etc.) can still exist and is a legitimate, separate design question, not something this check silently papers over. No occurrence count is hidden: the two remaining raw `EdgeInsets` numeric literals in the whole `lib/src/features` tree after this fix (`about_system_screen.dart`, values `2` and `6`) were spot-checked and are exactly this off-scale case.
