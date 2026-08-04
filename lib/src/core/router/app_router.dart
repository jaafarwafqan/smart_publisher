import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import 'app_navigation_observer.dart';
import 'app_routes.dart';
import 'route_guards.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// مزود نظام التنقل الرئيسي للتطبيق.
///
/// مسؤول عن:
/// • إنشاء GoRouter.
/// • تطبيق Route Guards.
/// • مراقبة التنقلات.
/// • معالجة الصفحات غير الموجودة.
@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
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
}

/// صفحة تعرض عند محاولة الوصول إلى مسار غير موجود.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.search_off, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.notFoundTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notFoundSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(RouteNames.dashboardPath),
                child: Text(l10n.notFoundGoHomeButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
