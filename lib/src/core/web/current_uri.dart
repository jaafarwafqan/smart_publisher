/// Returns the browser's current URL on Flutter Web (reflects `Uri.base`,
/// which the Dart SDK implements per-platform — no `dart:html`/JS interop
/// needed just to read it). A mutable top-level reference rather than a
/// direct call to `Uri.base` so tests can substitute a synthetic callback
/// URL instead of depending on the real environment.
Uri Function() currentUri = () => Uri.base;
