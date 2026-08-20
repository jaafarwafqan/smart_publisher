import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';
import '../feature_flags/feature_flags.dart';
import '../observability/metrics_registry.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/two_factor_challenge_screen.dart';
import '../../features/auth/presentation/screens/two_factor_setup_screen.dart';
import '../../features/help_center/presentation/screens/about_system_screen.dart';
import '../../features/help_center/presentation/screens/help_center_screen.dart';
import '../../features/help_center/presentation/screens/user_guide_screen.dart';
import '../../features/organizations/presentation/screens/organization_audit_log_screen.dart';
import '../../features/organizations/presentation/screens/organization_members_screen.dart';
import '../../features/settings/presentation/screens/account_data_export_screen.dart';
import '../../features/settings/presentation/screens/account_data_deletion_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/administration/presentation/screens/administration_screen.dart';
import '../../features/administration/presentation/screens/oauth_provider_settings_screen.dart';
import '../../features/composer/presentation/pages/create_post_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/distribution/presentation/pages/production_release_screen.dart';
import '../../features/media/presentation/pages/media_library_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/posts/domain/entities/post_entity.dart';
import '../../features/posts/presentation/pages/approvals_screen.dart';
import '../../features/posts/presentation/pages/posts_list_screen.dart';
import '../../features/platform_administration/presentation/screens/platform_admin_screens.dart';
import '../../features/schedule/presentation/pages/calendar_screen.dart';
import '../../features/organizations/presentation/screens/organization_switcher_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

// شاشات تجريبية بسيطة لعرض مسارات التطبيق
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.appName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcomeSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          FilledButton(
                            onPressed: () => context.go(RouteNames.loginPath),
                            child: Text(l10n.welcomeContinueButton),
                          ),
                          TextButton(
                            onPressed: () => context.push(RouteNames.aboutPath),
                            child: Text(
                              l10n.welcomeAboutLinkLabel(l10n.appName),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PerformanceDevScreen extends StatefulWidget {
  const PerformanceDevScreen({super.key});

  @override
  State<PerformanceDevScreen> createState() => _PerformanceDevScreenState();
}

class _PerformanceDevScreenState extends State<PerformanceDevScreen> {
  @override
  Widget build(BuildContext context) {
    final startupMs = globalMetricsRegistry.averageDurationMs(
      'app.startup.time',
    );
    final publishLatencyMs = globalMetricsRegistry.averageDurationMs(
      'publish.latency',
    );
    final publishSucceeded = globalMetricsRegistry.counter(
      'publish.jobs.succeeded',
    );
    final publishFailed = globalMetricsRegistry.counter('publish.jobs.failed');
    final imageCacheBytes = globalMetricsRegistry.gauge(
      'memory.image_cache.bytes',
    );
    final imageCacheEntries = globalMetricsRegistry.gauge(
      'memory.image_cache.entries',
    );
    final lazyPages = globalMetricsRegistry.counter('ui.lazy_load.pages');

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Dev Metrics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _MetricTile(
            label: 'Startup avg (ms)',
            value: startupMs.toStringAsFixed(1),
          ),
          _MetricTile(
            label: 'Publish latency avg (ms)',
            value: publishLatencyMs.toStringAsFixed(1),
          ),
          _MetricTile(label: 'Publish succeeded', value: '$publishSucceeded'),
          _MetricTile(label: 'Publish failed', value: '$publishFailed'),
          _MetricTile(label: 'Image cache bytes', value: '$imageCacheBytes'),
          _MetricTile(
            label: 'Image cache entries',
            value: '$imageCacheEntries',
          ),
          _MetricTile(label: 'Lazy pages loaded', value: '$lazyPages'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {}),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class FeatureUnavailableScreen extends StatelessWidget {
  const FeatureUnavailableScreen({super.key, required this.featureName});

  final String featureName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Disabled')),
      body: Center(
        child: Text('$featureName is currently disabled by feature flag.'),
      ),
    );
  }
}

// '/publisher' is unreachable from any real UI element (confirmed via
// project-wide search — nothing ever navigates here except direct URL
// entry), but it's real, permission-gated route (RouteGuards groups it
// with postsCreatePath) rather than dead code. It used to dead-end at a
// literal "Publisher Screen" placeholder; this delegates to the actual
// composer instead of leaving a broken screen reachable by direct link.
class PublisherScreen extends StatelessWidget {
  const PublisherScreen({super.key});
  @override
  Widget build(BuildContext context) => const CreatePostScreen();
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) => const AdministrationScreen();
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
    path: RouteNames.loginPath,
    name: RouteNames.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: RouteNames.registerPath,
    name: RouteNames.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: RouteNames.forgotPasswordPath,
    name: RouteNames.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: RouteNames.resetPasswordPath,
    name: RouteNames.resetPassword,
    builder: (context, state) => const ResetPasswordScreen(),
  ),
  GoRoute(
    path: RouteNames.twoFactorChallengePath,
    name: RouteNames.twoFactorChallenge,
    builder: (context, state) {
      final challengeToken = state.extra;
      return TwoFactorChallengeScreen(
        challengeToken: challengeToken is String ? challengeToken : '',
      );
    },
  ),
  GoRoute(
    path: RouteNames.twoFactorSetupPath,
    name: RouteNames.twoFactorSetup,
    builder: (context, state) => const TwoFactorSetupScreen(),
  ),
  GoRoute(
    path: RouteNames.organizationMembersPath,
    name: RouteNames.organizationMembers,
    builder: (context, state) => const OrganizationMembersScreen(),
  ),
  GoRoute(
    path: RouteNames.organizationAuditLogPath,
    name: RouteNames.organizationAuditLog,
    builder: (context, state) => const OrganizationAuditLogScreen(),
  ),
  GoRoute(
    path: RouteNames.accountDataExportPath,
    name: RouteNames.accountDataExport,
    builder: (context, state) => const AccountDataExportScreen(),
  ),
  GoRoute(
    path: RouteNames.accountDataDeletionPath,
    name: RouteNames.accountDataDeletion,
    builder: (context, state) => const AccountDataDeletionScreen(),
  ),
  GoRoute(
    path: RouteNames.dashboardPath,
    name: RouteNames.dashboard,
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: RouteNames.publisherPath,
    name: RouteNames.publisher,
    builder: (context, state) => const PublisherScreen(),
  ),
  GoRoute(
    path: RouteNames.adminPath,
    name: RouteNames.admin,
    builder: (context, state) => const AdminScreen(),
  ),
  GoRoute(
    path: RouteNames.performanceDevPath,
    name: RouteNames.performanceDev,
    builder: (context, state) {
      if (!globalFeatureFlags.isEnabled(FeatureFlagKeys.performanceDashboard)) {
        return const FeatureUnavailableScreen(
          featureName: 'Performance Dashboard',
        );
      }
      return const PerformanceDevScreen();
    },
  ),
  GoRoute(
    path: RouteNames.postsCreatePath,
    name: RouteNames.postsCreate,
    builder: (context, state) {
      final draft = state.extra;
      return CreatePostScreen(initialDraft: draft is PostEntity ? draft : null);
    },
  ),
  GoRoute(
    path: RouteNames.postsListPath,
    name: RouteNames.postsList,
    builder: (context, state) => const PostsListScreen(),
  ),
  GoRoute(
    path: RouteNames.postsApprovalsPath,
    name: RouteNames.postsApprovals,
    builder: (context, state) => const ApprovalsScreen(),
  ),
  GoRoute(
    path: RouteNames.mediaLibraryPath,
    name: RouteNames.mediaLibrary,
    builder: (context, state) => const MediaLibraryScreen(),
  ),
  GoRoute(
    path: RouteNames.calendarPath,
    name: RouteNames.calendar,
    builder: (context, state) => const CalendarScreen(),
  ),
  GoRoute(
    path: RouteNames.analyticsPath,
    name: RouteNames.analytics,
    builder: (context, state) => const AnalyticsScreen(),
  ),
  GoRoute(
    path: RouteNames.notificationsPath,
    name: RouteNames.notifications,
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    path: RouteNames.settingsPath,
    name: RouteNames.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: RouteNames.organizationsPath,
    name: RouteNames.organizations,
    builder: (context, state) => const OrganizationSwitcherScreen(),
  ),
  GoRoute(
    path: RouteNames.administrationPath,
    name: RouteNames.administration,
    builder: (context, state) => const AdministrationScreen(),
  ),
  GoRoute(
    path: RouteNames.platformAdministrationPath,
    name: RouteNames.platformAdministration,
    builder: (context, state) => const PlatformAdministrationScreen(),
  ),
  GoRoute(
    path: RouteNames.platformOrganizationsPath,
    name: RouteNames.platformOrganizations,
    builder: (context, state) => const PlatformOrganizationsScreen(),
  ),
  GoRoute(
    path: RouteNames.platformOrganizationDetailPath,
    name: RouteNames.platformOrganizationDetail,
    builder: (context, state) => PlatformOrganizationDetailScreen(
      organizationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
    ),
  ),
  GoRoute(
    path: RouteNames.platformUsersPath,
    name: RouteNames.platformUsers,
    builder: (context, state) => const PlatformUsersScreen(),
  ),
  GoRoute(
    path: RouteNames.platformAuditLogPath,
    name: RouteNames.platformAuditLog,
    builder: (context, state) => const PlatformAuditLogScreen(),
  ),
  GoRoute(
    path: RouteNames.oauthProviderSettingsPath,
    name: RouteNames.oauthProviderSettings,
    builder: (context, state) => const OAuthProviderSettingsScreen(),
  ),
  GoRoute(
    path: RouteNames.productionReleasePath,
    name: RouteNames.productionRelease,
    builder: (context, state) => const ProductionReleaseScreen(),
  ),
  GoRoute(
    path: RouteNames.aboutPath,
    name: RouteNames.about,
    builder: (context, state) => const AboutSystemScreen(),
  ),
  GoRoute(
    path: RouteNames.helpCenterPath,
    name: RouteNames.helpCenter,
    builder: (context, state) => const HelpCenterScreen(),
  ),
  GoRoute(
    path: RouteNames.userGuidePath,
    name: RouteNames.userGuide,
    builder: (context, state) {
      final extra = state.extra;
      return UserGuideScreen(initialQuery: extra is String ? extra : null);
    },
  ),
];

/// Routes that must remain outside the persistent workspace shell. This keeps
/// public screens distraction-free and ensures the sensitive two-factor setup
/// flow is disposed as soon as the user leaves it instead of being retained in
/// an inactive navigation branch.
final rootAppRoutes = _routesFor(<String>{
  RouteNames.splashPath,
  RouteNames.welcomePath,
  RouteNames.loginPath,
  RouteNames.registerPath,
  RouteNames.forgotPasswordPath,
  RouteNames.resetPasswordPath,
  RouteNames.twoFactorChallengePath,
  RouteNames.twoFactorSetupPath,
  RouteNames.aboutPath,
});

/// Independent navigation stacks for the persistent workspace shell. A branch
/// owns its own Navigator, so a user can switch between work areas without
/// destroying scroll position, form state, or the branch back stack.
final workspaceNavigationBranches = <List<GoRoute>>[
  _routesFor(<String>{
    RouteNames.dashboardPath,
    RouteNames.publisherPath,
    RouteNames.adminPath,
    RouteNames.performanceDevPath,
    RouteNames.platformAdministrationPath,
    RouteNames.platformOrganizationsPath,
    RouteNames.platformOrganizationDetailPath,
    RouteNames.platformUsersPath,
    RouteNames.platformAuditLogPath,
  }),
  _routesFor(<String>{RouteNames.postsListPath, RouteNames.postsApprovalsPath}),
  _routesFor(<String>{RouteNames.postsCreatePath}),
  _routesFor(<String>{RouteNames.calendarPath}),
  _routesFor(<String>{RouteNames.analyticsPath}),
  _routesFor(<String>{RouteNames.mediaLibraryPath}),
  _routesFor(<String>{
    RouteNames.organizationsPath,
    RouteNames.organizationMembersPath,
    RouteNames.organizationAuditLogPath,
  }),
  _routesFor(<String>{
    RouteNames.settingsPath,
    RouteNames.notificationsPath,
    RouteNames.administrationPath,
    RouteNames.oauthProviderSettingsPath,
    RouteNames.accountDataExportPath,
    RouteNames.accountDataDeletionPath,
    RouteNames.productionReleasePath,
  }),
  _routesFor(<String>{RouteNames.helpCenterPath, RouteNames.userGuidePath}),
];

List<GoRoute> _routesFor(Set<String> paths) {
  return paths
      .map((path) => appRoutes.singleWhere((route) => route.path == path))
      .toList(growable: false);
}
