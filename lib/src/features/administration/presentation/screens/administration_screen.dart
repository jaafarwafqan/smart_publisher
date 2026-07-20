import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';

class AdministrationScreen extends ConsumerStatefulWidget {
  const AdministrationScreen({super.key});

  @override
  ConsumerState<AdministrationScreen> createState() =>
      _AdministrationScreenState();
}

class _AdministrationScreenState extends ConsumerState<AdministrationScreen> {
  bool _maintenanceMode = false;
  bool _freezePublishing = false;

  @override
  Widget build(BuildContext context) {
    final roleFuture = ref.read(currentUserRoleProvider.future);

    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: FutureBuilder<UserRole>(
        future: roleFuture,
        builder: (context, snapshot) {
          final role = snapshot.data ?? UserRole.guest;
          final canManagePolicies = role == UserRole.admin;
          final canViewReleaseOps = role == UserRole.admin;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              if (!canManagePolicies)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Administrative actions are restricted to admins. You currently have read-only access.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Access Profile'),
                  subtitle: Text('Current role: ${role.name.toUpperCase()}'),
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Maintenance Mode'),
                  subtitle: const Text(
                    'Limit editor access while conducting maintenance operations.',
                  ),
                  value: _maintenanceMode,
                  onChanged: canManagePolicies
                      ? (value) => setState(() => _maintenanceMode = value)
                      : null,
                ),
              ),
              Card(
                child: SwitchListTile(
                  title: const Text('Freeze Publishing Queue'),
                  subtitle: const Text(
                    'Pause new publish jobs while existing jobs complete.',
                  ),
                  value: _freezePublishing,
                  onChanged: canManagePolicies
                      ? (value) => setState(() => _freezePublishing = value)
                      : null,
                ),
              ),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: const Text('Release History'),
                      subtitle: const Text(
                        'Review recently deployed versions and rollout notes.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: canViewReleaseOps
                          ? () => context.go(RouteNames.productionReleasePath)
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: const Text('Operational Readiness'),
                      subtitle: const Text(
                        'Track go-live checks, incident playbooks, and rollback readiness.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: canViewReleaseOps
                          ? () => context.go(RouteNames.productionReleasePath)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: canManagePolicies
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Administrative policies applied successfully.',
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('Apply Administrative Policies'),
              ),
            ],
          );
        },
      ),
    );
  }
}
