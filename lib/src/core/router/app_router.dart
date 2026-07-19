import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_navigation_observer.dart';
import 'app_routes.dart';
import 'route_guards.dart';
import 'route_names.dart';

/// مزود نظام التنقل الرئيسي للتطبيق.
///
/// مسؤول عن:
/// • إنشاء GoRouter.
/// • تطبيق Route Guards.
/// • مراقبة التنقلات.
/// • معالجة الصفحات غير الموجودة.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // أول شاشة يتم تشغيلها
    initialLocation: RouteNames.splashPath,

    // يطبع معلومات التنقل فقط أثناء التطوير
    debugLogDiagnostics: kDebugMode,

    // مراقبة جميع عمليات التنقل
    observers: [AppNavigationObserver()],

    // جميع مسارات التطبيق
    routes: appRoutes,

    // حماية المسارات
    redirect: (_, state) => RouteGuards.guard(state, ref),

    // صفحة الخطأ
    errorBuilder: (_, state) => const _NotFoundScreen(),
  );
});

/// صفحة تعرض عند محاولة الوصول إلى مسار غير موجود.
///
/// سيتم استبدالها لاحقاً بصفحة احترافية داخل:
/// core/widgets/errors/not_found_page.dart
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404 - Page Not Found')));
  }
}
