import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guard_state_provider.dart';
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
    final path = state.uri.path;

    if (_isSplash(path)) {
      return const SplashGuard().redirect(state, ref);
    }

    if (_isAdminRoute(path)) {
      return const AdminGuard().redirect(state, ref);
    }

    if (_isPublisherRoute(path)) {
      return const PublisherGuard().redirect(state, ref);
    }

    if (_isAuthenticationRoute(path)) {
      return const GuestGuard().redirect(state, ref);
    }

    return const LoginGuard().redirect(state, ref);
  }

  static bool _isSplash(String path) {
    return path == RouteNames.splashPath;
  }

  static bool _isAdminRoute(String path) {
    return path.startsWith(RouteNames.adminPath) ||
        path.startsWith(RouteNames.administrationPath) ||
        path.startsWith(RouteNames.productionReleasePath);
  }

  static bool _isPublisherRoute(String path) {
    return path.startsWith(RouteNames.publisherPath) ||
        path.startsWith(RouteNames.postsCreatePath) ||
        path.startsWith(RouteNames.postsListPath) ||
        path.startsWith(RouteNames.mediaLibraryPath) ||
        path.startsWith(RouteNames.calendarPath) ||
        path.startsWith(RouteNames.analyticsPath) ||
        path.startsWith(RouteNames.notificationsPath) ||
        path.startsWith(RouteNames.settingsPath);
  }

  static bool _isAuthenticationRoute(String path) {
    return path == RouteNames.loginPath || path == RouteNames.welcomePath;
  }
}

abstract class _BaseRouteGuard {
  const _BaseRouteGuard();

  FutureOr<String?> redirect(GoRouterState state, Ref ref);
}

class LoginGuard extends _BaseRouteGuard {
  const LoginGuard();

  @override
  Future<String?> redirect(GoRouterState state, Ref ref) async {
    final isAuthenticated = await ref.read(authStateProvider.future);

    if (isAuthenticated) {
      return RouteNames.dashboardPath;
    }

    return RouteNames.loginPath;
  }
}

class SplashGuard extends _BaseRouteGuard {
  const SplashGuard();

  @override
  Future<String?> redirect(GoRouterState state, Ref ref) async {
    final isAuthenticated = await ref.read(authStateProvider.future);
    if (!isAuthenticated) {
      return RouteNames.loginPath;
    }
    return RouteNames.dashboardPath;
  }
}

class GuestGuard extends _BaseRouteGuard {
  const GuestGuard();

  @override
  Future<String?> redirect(GoRouterState state, Ref ref) async {
    final isAuthenticated = await ref.read(authStateProvider.future);
    if (!isAuthenticated) {
      return null;
    }

    return RouteNames.dashboardPath;
  }
}

class AdminGuard extends _BaseRouteGuard {
  const AdminGuard();

  @override
  Future<String?> redirect(GoRouterState state, Ref ref) async {
    final isAuthenticated = await ref.read(authStateProvider.future);
    if (!isAuthenticated) {
      return RouteNames.loginPath;
    }

    final role = await ref.read(currentUserRoleProvider.future);
    if (role == UserRole.admin) {
      return null;
    }

    return RouteNames.dashboardPath;
  }
}

class PublisherGuard extends _BaseRouteGuard {
  const PublisherGuard();

  @override
  Future<String?> redirect(GoRouterState state, Ref ref) async {
    final isAuthenticated = await ref.read(authStateProvider.future);
    if (!isAuthenticated) {
      return RouteNames.loginPath;
    }

    final role = await ref.read(currentUserRoleProvider.future);
    if (role == UserRole.publisher || role == UserRole.admin) {
      return null;
    }

    return RouteNames.dashboardPath;
  }
}
