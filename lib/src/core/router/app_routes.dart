import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

// 💡 شاشات مؤقتة (Placeholders) للاختبار
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Welcome Screen')));
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Dashboard Screen')));
}

final List<GoRoute> appRoutes = [
  GoRoute(
    path: RouteNames.splashPath,
    name: RouteNames.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: RouteNames.welcomePath,
    name: RouteNames.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: RouteNames.dashboardPath,
    name: RouteNames.dashboard,
    builder: (context, state) => const DashboardScreen(),
  ),
];
