import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_navigation_observer.dart';
import 'app_routes.dart';
import 'route_guards.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: kDebugMode,
    observers: [AppNavigationObserver()],
    routes: appRoutes,
    redirect: (context, state) => RouteGuards.guard(state, ref),
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404 - Page Not Found')));
  }
}
