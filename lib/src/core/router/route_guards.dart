import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

/// المسؤول عن حماية المسارات (Route Guards)
///
/// يقوم بتحديد الصفحة المناسبة للمستخدم اعتماداً على:
/// - حالة تسجيل الدخول.
/// - هل هذه أول مرة يستخدم التطبيق.
/// - المسار المطلوب.
final class RouteGuards {
  RouteGuards._();

  /// نقطة الدخول الرئيسية لجميع عمليات إعادة التوجيه.
  static FutureOr<String?> guard(GoRouterState state, Ref ref) {
    final authState = _isAuthenticated(ref);
    final firstLaunch = _isFirstLaunch(ref);

    final path = state.uri.path;

    // السماح دائماً بعرض شاشة Splash
    if (_isSplash(path)) {
      return null;
    }

    // المستخدم مسجل دخول
    if (authState) {
      return _redirectAuthenticatedUser(path);
    }

    // المستخدم غير مسجل دخول
    return _redirectGuestUser(path: path, isFirstLaunch: firstLaunch);
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  static bool _isAuthenticated(Ref ref) {
    // Placeholder for future auth integration.
    return false;
  }

  static bool _isFirstLaunch(Ref ref) {
    // Placeholder for future first-launch persistence.
    return true;
  }

  // ---------------------------------------------------------------------------
  // Redirect Rules
  // ---------------------------------------------------------------------------

  static String? _redirectAuthenticatedUser(String path) {
    if (_isAuthenticationRoute(path)) {
      return RouteNames.dashboardPath;
    }

    return null;
  }

  static String? _redirectGuestUser({
    required String path,
    required bool isFirstLaunch,
  }) {
    if (_isAuthenticationRoute(path)) {
      return null;
    }

    return isFirstLaunch ? RouteNames.welcomePath : RouteNames.loginPath;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isSplash(String path) {
    return path == RouteNames.splashPath;
  }

  static bool _isAuthenticationRoute(String path) {
    return path == RouteNames.loginPath || path == RouteNames.welcomePath;
  }
}
