import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/locale/locale_provider.dart';
import 'package:smart_publisher/src/core/theme/app_theme.dart';
import 'package:smart_publisher/src/core/theme/theme_provider.dart';
import 'package:smart_publisher/src/core/router/app_router.dart';
import 'package:smart_publisher/src/core/constants/app_constants.dart'; // 👈 استيراد الثوابت
import 'package:smart_publisher/l10n/app_localizations.dart';

class SmartPublisherApp extends ConsumerWidget {
  const SmartPublisherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    ref.watch(syncSchedulerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
