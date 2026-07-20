import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../di/app_providers.dart';
import '../feature_flags/feature_flags.dart';
import '../observability/metrics_registry.dart';
import '../performance/lazy_loader.dart';
import '../../features/auth/application/auth_session_controller.dart';
import '../../features/auth/domain/entities/account_entity.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/administration/presentation/screens/administration_screen.dart';
import '../../features/composer/presentation/pages/create_post_screen.dart';
import '../../features/distribution/presentation/pages/production_release_screen.dart';
import '../../features/media/presentation/pages/media_library_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/posts/domain/entities/post_entity.dart';
import '../../features/posts/presentation/pages/posts_list_screen.dart';
import '../../features/schedule/presentation/pages/calendar_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'guard_state_provider.dart';
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
                      'Smart Publisher',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Manage publishing, scheduling, accounts, and delivery from one control surface.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: () => context.go(RouteNames.loginPath),
                        child: const Text('Continue to Login'),
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final LazyLoader<String> _loader;
  late Future<List<AccountEntity>> _accountsFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loader = LazyLoader<String>(
      pageSize: 15,
      fetcher: (page, pageSize) async {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (page > 5) {
          return <String>[];
        }
        return List<String>.generate(
          pageSize,
          (index) => 'Post ${(page - 1) * pageSize + index + 1}',
        );
      },
    );
    _scrollController.addListener(_onScroll);
    _accountsFuture = _loadAccounts();
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final before = _loader.items.length;
    final page = await _loader.loadNext();
    if (!mounted) {
      return;
    }
    if (page.items.length > before) {
      globalMetricsRegistry.increment('ui.lazy_load.pages');
    }
    setState(() {});
  }

  void _onScroll() {
    if (!_loader.hasMore || _loader.isLoading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<List<AccountEntity>> _loadAccounts() async {
    final result = await ref.read(accountRepositoryProvider).getAccounts();
    return result.data ?? const <AccountEntity>[];
  }

  Future<void> _refreshDashboard() async {
    _loader.reset();
    setState(() {
      _accountsFuture = _loadAccounts();
    });
    await _loadMore();
    await _accountsFuture;
  }

  Future<void> _connectAccount(AccountEntity account) async {
    await ref.read(accountRepositoryProvider).connectAccount(account);
    if (!mounted) {
      return;
    }
    setState(() {
      _accountsFuture = _loadAccounts();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${account.name} connected successfully.')),
    );
  }

  Future<void> _disconnectAccount(AccountEntity account) async {
    await ref.read(accountRepositoryProvider).disconnectAccount(account.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _accountsFuture = _loadAccounts();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${account.name} disconnected.')));
  }

  @override
  Widget build(BuildContext context) {
    final items = _loader.items;
    final sessionFuture = ref
        .read(authSessionControllerProvider)
        .currentSession();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Publisher'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authSessionControllerProvider).logout();
              ref.invalidate(authStateProvider);
              ref.invalidate(currentUserRoleProvider);
              if (!context.mounted) {
                return;
              }
              context.go(RouteNames.loginPath);
            },
            icon: const Icon(Icons.logout),
          ),
          if (globalFeatureFlags.isEnabled(
            FeatureFlagKeys.performanceDashboard,
          ))
            IconButton(
              tooltip: 'Performance',
              onPressed: () => context.pushNamed(RouteNames.performanceDev),
              icon: const Icon(Icons.speed),
            ),
        ],
      ),
      body: FutureBuilder<AuthSession?>(
        future: sessionFuture,
        builder: (context, snapshot) {
          final session = snapshot.data;
          final stats = <_DashboardStat>[
            const _DashboardStat(
              label: 'Posts',
              value: '145',
              icon: Icons.article_outlined,
            ),
            const _DashboardStat(
              label: 'Scheduled',
              value: '23',
              icon: Icons.schedule,
            ),
            const _DashboardStat(
              label: 'Published',
              value: '1880',
              icon: Icons.send_outlined,
            ),
            const _DashboardStat(
              label: 'Failed',
              value: '4',
              icon: Icons.error_outline,
            ),
            const _DashboardStat(
              label: 'Accounts',
              value: '12',
              icon: Icons.groups_2_outlined,
            ),
          ];
          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: colorScheme.onPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitor posts, scheduled work, publishing health, and connected platforms from one place.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _PillInfo(
                            icon: Icons.person_outline,
                            label: session?.user.name ?? 'Authenticated User',
                            foreground: colorScheme.onPrimary,
                          ),
                          _PillInfo(
                            icon: Icons.mail_outline,
                            label: session?.user.email ?? 'No email available',
                            foreground: colorScheme.onPrimary,
                          ),
                          _PillInfo(
                            icon: Icons.verified_user_outlined,
                            label: session?.role.name.toUpperCase() ?? 'GUEST',
                            foreground: colorScheme.onPrimary,
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.onPrimary,
                              foregroundColor: colorScheme.primary,
                            ),
                            onPressed: () =>
                                context.go(RouteNames.postsCreatePath),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('Create Post'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onPrimary,
                              side: BorderSide(
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                context.go(RouteNames.postsListPath),
                            icon: const Icon(Icons.library_books_outlined),
                            label: const Text('Posts'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 900
                        ? (constraints.maxWidth - 36) / 4
                        : constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 18) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: stats
                          .map(
                            (stat) => SizedBox(
                              width: cardWidth,
                              child: _StatCard(stat: stat),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 860;
                    if (stacked) {
                      return Column(
                        children: <Widget>[
                          FutureBuilder<List<AccountEntity>>(
                            future: _accountsFuture,
                            builder: (context, accountSnapshot) {
                              return _AccountsSection(
                                accounts:
                                    accountSnapshot.data ??
                                    const <AccountEntity>[],
                                isLoading:
                                    accountSnapshot.connectionState ==
                                    ConnectionState.waiting,
                                onReconnect: _connectAccount,
                                onDisconnect: _disconnectAccount,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Publishing Health',
                            subtitle:
                                'Current operational snapshot across delivery and accounts.',
                            child: Column(
                              children: const <Widget>[
                                _StatusRow(
                                  label: 'Success Rate',
                                  value: '99.2%',
                                ),
                                _StatusRow(
                                  label: 'Queue Health',
                                  value: 'Stable',
                                ),
                                _StatusRow(
                                  label: 'Connected Accounts',
                                  value: '12/12',
                                ),
                                _StatusRow(
                                  label: 'Failed Deliveries',
                                  value: '4',
                                  isWarning: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: FutureBuilder<List<AccountEntity>>(
                            future: _accountsFuture,
                            builder: (context, accountSnapshot) {
                              return _AccountsSection(
                                accounts:
                                    accountSnapshot.data ??
                                    const <AccountEntity>[],
                                isLoading:
                                    accountSnapshot.connectionState ==
                                    ConnectionState.waiting,
                                onReconnect: _connectAccount,
                                onDisconnect: _disconnectAccount,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SectionCard(
                            title: 'Publishing Health',
                            subtitle:
                                'Current operational snapshot across delivery and accounts.',
                            child: Column(
                              children: const <Widget>[
                                _StatusRow(
                                  label: 'Success Rate',
                                  value: '99.2%',
                                ),
                                _StatusRow(
                                  label: 'Queue Health',
                                  value: 'Stable',
                                ),
                                _StatusRow(
                                  label: 'Connected Accounts',
                                  value: '12/12',
                                ),
                                _StatusRow(
                                  label: 'Failed Deliveries',
                                  value: '4',
                                  isWarning: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Workspace Modules',
                  subtitle:
                      'Access Media Library, Calendar, Analytics, Notifications, Settings, Administration, and Production Release.',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go(RouteNames.mediaLibraryPath),
                        icon: const Icon(Icons.perm_media_outlined),
                        label: const Text('Media Library'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(RouteNames.calendarPath),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Calendar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(RouteNames.analyticsPath),
                        icon: const Icon(Icons.insights_outlined),
                        label: const Text('Analytics'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go(RouteNames.notificationsPath),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Notifications'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(RouteNames.settingsPath),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go(RouteNames.administrationPath),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Administration'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            context.go(RouteNames.productionReleasePath),
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: const Text('Production Release'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Recent Activity',
                  subtitle: 'Latest publishing items and post operations.',
                  child: Column(
                    children: <Widget>[
                      for (final item in items.take(8))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.article_outlined,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: Text(item),
                          subtitle: const Text(
                            'Queued recently for review, scheduling, or publishing.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      if (_loader.hasMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.accounts,
    required this.isLoading,
    required this.onReconnect,
    required this.onDisconnect,
  });

  final List<AccountEntity> accounts;
  final bool isLoading;
  final Future<void> Function(AccountEntity account) onReconnect;
  final Future<void> Function(AccountEntity account) onDisconnect;

  @override
  Widget build(BuildContext context) {
    if (isLoading && accounts.isEmpty) {
      return const _SectionCard(
        title: 'Accounts',
        subtitle: 'Connected workspaces and permissions across all platforms.',
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return _SectionCard(
      title: 'Accounts',
      subtitle:
          'Manage Facebook, Instagram, Telegram, WhatsApp, LinkedIn, and X accounts.',
      child: Column(
        children: accounts
            .map(
              (account) => _AccountCard(
                account: account,
                onReconnect: () => onReconnect(account),
                onDisconnect: account.isConnected
                    ? () => onDisconnect(account)
                    : null,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onReconnect,
    required this.onDisconnect,
  });

  final AccountEntity account;
  final Future<void> Function() onReconnect;
  final Future<void> Function()? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = account.name.isEmpty ? '?' : account.name[0];
    final permissions = account.permissions.isEmpty
        ? 'No permissions assigned'
        : account.permissions.join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    initial.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _platformLabel(account.platform),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: account.isConnected
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    account.status,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: account.isConnected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Permissions', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(permissions, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onReconnect,
                  icon: const Icon(Icons.refresh),
                  label: Text(account.isConnected ? 'Reconnect' : 'Connect'),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _platformLabel(String platform) {
    switch (platform) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'telegram':
        return 'Telegram';
      case 'whatsapp':
        return 'WhatsApp';
      case 'linkedin':
        return 'LinkedIn';
      case 'twitter':
        return 'X';
      default:
        return platform;
    }
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(stat.icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 14),
            Text(
              stat.value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(stat.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  const _PillInfo({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isWarning ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ],
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authSessionControllerProvider)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserRoleProvider);
      ref.invalidate(firstLaunchProvider);
      if (!mounted) {
        return;
      }
      context.go(RouteNames.dashboardPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is AuthSessionException
            ? error.message
            : 'Login failed. Check credentials or backend availability.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Smart Publisher Login',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty || !text.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Enter a valid password';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitting ? null : _login(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _login,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PublisherScreen extends StatelessWidget {
  const PublisherScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Publisher Screen')));
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
    path: RouteNames.administrationPath,
    name: RouteNames.administration,
    builder: (context, state) => const AdministrationScreen(),
  ),
  GoRoute(
    path: RouteNames.productionReleasePath,
    name: RouteNames.productionRelease,
    builder: (context, state) => const ProductionReleaseScreen(),
  ),
];
