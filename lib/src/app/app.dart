import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/src/core/theme/app_theme.dart';
import 'package:smart_publisher/src/core/theme/theme_provider.dart';
import 'package:smart_publisher/src/core/router/app_router.dart';
import 'package:smart_publisher/src/core/constants/app_constants.dart'; // 👈 استيراد الثوابت

class SmartPublisherApp extends ConsumerWidget {
  const SmartPublisherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref
        .watch(themeProvider)
        .when(
          data: (mode) => mode,
          loading: () => ThemeMode.system,
          error: (_, _) => ThemeMode.system,
        );
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
