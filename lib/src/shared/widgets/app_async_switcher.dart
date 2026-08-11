import 'package:flutter/material.dart';

import '../../core/theme/app_curves.dart';
import '../../core/theme/app_duration.dart';

enum AppAsyncState { loading, empty, content, error }

/// Renders exactly one of [loading]/[empty]/[content]/[error] depending on
/// [state] — but all four are still ordinary constructor arguments, which
/// Dart evaluates **eagerly, every single build**, regardless of which one
/// ends up displayed. A call site building `content` (or any of the
/// others) from a value that's only valid in that state — most commonly
/// `content: SomeWidget(data: snapshot.data!)` from a `FutureBuilder` —
/// throws on every build where a *different* branch is actually selected
/// (classically the very first frame, while still loading and
/// `snapshot.data` is null). This is not hypothetical: exactly this
/// pattern crashed every FutureBuilder-backed screen in
/// platform_admin_screens.dart (fixed 2026-08-10). Guard any
/// state-dependent argument yourself, e.g.
/// `content: snapshot.hasData ? SomeWidget(data: snapshot.data!) : const SizedBox.shrink()`.
class AppAsyncSwitcher extends StatelessWidget {
  const AppAsyncSwitcher({
    super.key,
    required this.state,
    required this.loading,
    required this.empty,
    required this.content,
    this.error,
    this.duration = AppDuration.normal,
    this.reverseDuration = AppDuration.fast,
  });

  final AppAsyncState state;
  final Widget loading;
  final Widget empty;
  final Widget content;
  final Widget? error;
  final Duration duration;
  final Duration reverseDuration;

  @override
  Widget build(BuildContext context) {
    final child = switch (state) {
      AppAsyncState.loading => loading,
      AppAsyncState.empty => empty,
      AppAsyncState.content => content,
      AppAsyncState.error => error ?? empty,
    };

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: AppCurves.standard,
      switchOutCurve: AppCurves.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<AppAsyncState>(state), child: child),
    );
  }
}
