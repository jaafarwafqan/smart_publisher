import 'package:flutter/widgets.dart';
import 'package:smart_publisher/src/core/logger/app_logger.dart';

class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.i('Navigated to: ${route.settings.name ?? 'unknown'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.i('Popped from: ${route.settings.name ?? 'unknown'}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.i('Replaced route: ${newRoute?.settings.name ?? 'unknown'}');
  }
}
