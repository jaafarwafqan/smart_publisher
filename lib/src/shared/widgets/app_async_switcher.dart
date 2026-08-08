import 'package:flutter/material.dart';

import '../../core/theme/app_curves.dart';
import '../../core/theme/app_duration.dart';

enum AppAsyncState { loading, empty, content, error }

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
