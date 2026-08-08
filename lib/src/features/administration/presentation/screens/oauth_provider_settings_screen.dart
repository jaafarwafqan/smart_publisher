import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../dashboard/presentation/utils/platform_label.dart';
import '../../domain/entities/oauth_provider_setting_entity.dart';

String _formatTimestamp(DateTime dt, AppLocalizations l10n) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (isToday) {
    return '${l10n.accountCardTodayPrefix} $time';
  }
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $time';
}

class OAuthProviderSettingsScreen extends ConsumerStatefulWidget {
  const OAuthProviderSettingsScreen({super.key});

  @override
  ConsumerState<OAuthProviderSettingsScreen> createState() =>
      _OAuthProviderSettingsScreenState();
}

class _OAuthProviderSettingsScreenState
    extends ConsumerState<OAuthProviderSettingsScreen> {
  late Future<List<OAuthProviderSettingEntity>> _providersFuture;
  final Set<String> _testingProviders = <String>{};

  @override
  void initState() {
    super.initState();
    _providersFuture = _load();
  }

  Future<List<OAuthProviderSettingEntity>> _load() async {
    final result = await ref
        .read(systemSettingsRepositoryProvider)
        .getOAuthProviderSettings();
    if (result.isFailure) {
      // Thrown, not swallowed into an empty list — FutureBuilder's
      // snapshot.hasError is what lets build() tell "genuinely zero
      // providers configured" apart from "the request failed."
      throw StateError(
        result.message ?? 'Failed to load OAuth provider settings.',
      );
    }
    return result.data ?? const <OAuthProviderSettingEntity>[];
  }

  Future<void> _refresh() async {
    setState(() {
      _providersFuture = _load();
    });
    try {
      await _providersFuture;
    } catch (_) {
      // Swallowed here — the FutureBuilder watching _providersFuture
      // independently picks up the rejection via snapshot.hasError and
      // renders the error/retry UI. This await only exists so
      // RefreshIndicator/the retry button know when loading finished.
    }
  }

  Future<void> _editProvider(OAuthProviderSettingEntity provider) async {
    final result = await showDialog<_ProviderFormResult>(
      context: context,
      builder: (context) => _ProviderEditDialog(provider: provider),
    );
    if (result == null || !mounted) {
      return;
    }

    final updateResult = await ref
        .read(systemSettingsRepositoryProvider)
        .updateOAuthProviderSetting(
          provider.provider,
          clientId: result.clientId,
          clientSecret: result.clientSecret,
          isEnabled: result.isEnabled,
        );
    if (!mounted) {
      return;
    }
    if (updateResult.isSuccess) {
      await _refresh();
    }
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updateResult.isSuccess
              ? l10n.oauthSettingsSaveSuccess(platformLabel(provider.provider))
              : updateResult.message ?? l10n.oauthSettingsSaveFailedDefault,
        ),
      ),
    );
  }

  Future<void> _testConnection(OAuthProviderSettingEntity provider) async {
    setState(() => _testingProviders.add(provider.provider));

    final result = await ref
        .read(systemSettingsRepositoryProvider)
        .testConnection(provider.provider);

    if (!mounted) {
      return;
    }
    setState(() => _testingProviders.remove(provider.provider));

    await _refresh();
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final message = result.isSuccess
        ? result.data!.message
        : result.message ?? l10n.oauthSettingsTestFailedDefault;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showHistory(OAuthProviderSettingEntity provider) async {
    final label = platformLabel(provider.provider);
    final result = await ref
        .read(systemSettingsRepositoryProvider)
        .getAuditLog(provider.provider);

    if (!mounted) {
      return;
    }

    final entries = result.data ?? const <OAuthProviderAuditLogEntryEntity>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AuditLogSheet(label: label, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.administrationCredentialsTitle)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OAuthProviderSettingEntity>>(
          future: _providersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l10n.oauthSettingsFailedToLoad),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.commonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final providers =
                snapshot.data ?? const <OAuthProviderSettingEntity>[];

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                Text(
                  l10n.oauthSettingsIntro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...providers.map(
                  (provider) => _ProviderCard(
                    provider: provider,
                    isTesting: _testingProviders.contains(provider.provider),
                    onEdit: () => _editProvider(provider),
                    onTestConnection: () => _testConnection(provider),
                    onShowHistory: () => _showHistory(provider),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.isTesting,
    required this.onEdit,
    required this.onTestConnection,
    required this.onShowHistory,
  });

  final OAuthProviderSettingEntity provider;
  final bool isTesting;
  final Future<void> Function() onEdit;
  final Future<void> Function() onTestConnection;
  final Future<void> Function() onShowHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = platformLabel(provider.provider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.oauthSettingsHistoryTooltip,
                  icon: const Icon(Icons.history_outlined, size: 20),
                  onPressed: onShowHistory,
                ),
              ],
            ),
            if (provider.isMockIntegration) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.oauthSettingsMockNotice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              provider.clientId?.isNotEmpty == true
                  ? l10n.oauthSettingsClientIdSet(provider.clientId!)
                  : l10n.oauthSettingsClientIdNotSet,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (provider.updatedByName != null &&
                provider.updatedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.oauthSettingsUpdatedBy(
                  provider.updatedByName!,
                  _formatTimestamp(provider.updatedAt!, l10n),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _StatusBlock(provider: provider, isTesting: isTesting),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (provider.isConfigured) ...[
                  OutlinedButton.icon(
                    onPressed: isTesting ? null : onTestConnection,
                    icon: isTesting
                        ? const SizedBox(
                            width: AppSizes.iconSm,
                            height: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering, size: 18),
                    label: Text(
                      provider.lastTestSuccess == false
                          ? l10n.oauthSettingsTestAgain
                          : l10n.oauthSettingsTestConnection,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.commonEdit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.provider, required this.isTesting});

  final OAuthProviderSettingEntity provider;
  final bool isTesting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final Widget status;
    final String statusKey;
    if (isTesting) {
      statusKey = 'testing';
      status = Row(
        children: <Widget>[
          const SizedBox(
            width: AppSizes.iconSm,
            height: AppSizes.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.oauthSettingsTestConnection),
        ],
      );
    } else if (!provider.isConfigured) {
      statusKey = 'not-configured';
      status = _pill(
        label: l10n.oauthSettingsNotConfigured,
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.onSurfaceVariant,
      );
    } else if (provider.lastTestSuccess == true) {
      statusKey = 'verified';
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _pill(
            label: l10n.oauthSettingsConfigured,
            background: colorScheme.primaryContainer,
            foreground: colorScheme.onPrimaryContainer,
          ),
          if (provider.lastTestedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.oauthSettingsLastVerified(
                _formatTimestamp(provider.lastTestedAt!, l10n),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      );
    } else if (provider.lastTestSuccess == false) {
      statusKey = 'failed';
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _pill(
            label: l10n.oauthSettingsInvalidConfig,
            background: colorScheme.errorContainer,
            foreground: colorScheme.onErrorContainer,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.oauthSettingsAuthFailed,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    } else {
      statusKey = 'not-tested';
      status = _pill(
        label: l10n.oauthSettingsConfiguredNotTested,
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      );
    }

    return AnimatedSwitcher(
      duration: AppDuration.normal,
      switchInCurve: AppCurves.standard,
      switchOutCurve: AppCurves.standard,
      child: KeyedSubtree(key: ValueKey<String>(statusKey), child: status),
    );
  }

  Widget _pill({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return StatusPill(
      label: label,
      backgroundColor: background,
      foregroundColor: foreground,
    );
  }
}

class _AuditLogSheet extends StatelessWidget {
  const _AuditLogSheet({required this.label, required this.entries});

  final String label;
  final List<OAuthProviderAuditLogEntryEntity> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.oauthSettingsHistorySheetTitle(label),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (entries.isEmpty)
              AppEmptyState(
                message: l10n.oauthSettingsNoHistory,
                icon: Icons.history_toggle_off_outlined,
                compact: true,
                showCard: false,
                alignment: CrossAxisAlignment.start,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final description = entry.action == 'tested'
                        ? (entry.success == true
                              ? l10n.oauthSettingsTestedSucceeded
                              : l10n.oauthSettingsTestedFailed)
                        : entry.changedFields.isEmpty
                        ? l10n.oauthSettingsUpdatedSettings
                        : l10n.oauthSettingsUpdatedFields(
                            entry.changedFields.join(', '),
                          );

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        entry.action == 'tested'
                            ? Icons.wifi_tethering
                            : Icons.edit_outlined,
                        size: 18,
                      ),
                      title: Text(description),
                      subtitle: Text(
                        [
                          entry.userName ?? l10n.oauthSettingsAutomatedCheck,
                          if (entry.createdAt != null)
                            _formatTimestamp(entry.createdAt!, l10n),
                        ].join(' • '),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderFormResult {
  const _ProviderFormResult({this.clientId, this.clientSecret, this.isEnabled});

  final String? clientId;
  final String? clientSecret;
  final bool? isEnabled;
}

class _ProviderEditDialog extends StatefulWidget {
  const _ProviderEditDialog({required this.provider});

  final OAuthProviderSettingEntity provider;

  @override
  State<_ProviderEditDialog> createState() => _ProviderEditDialogState();
}

class _ProviderEditDialogState extends State<_ProviderEditDialog> {
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _clientIdController = TextEditingController(
      text: widget.provider.clientId ?? '',
    );
    _clientSecretController = TextEditingController();
    _isEnabled = widget.provider.isEnabled;
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = platformLabel(widget.provider.provider);

    return AlertDialog(
      title: Text(l10n.oauthSettingsEditDialogTitle(label)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _clientIdController,
            decoration: InputDecoration(
              labelText: l10n.oauthSettingsClientIdLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _clientSecretController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.oauthSettingsClientSecretLabel,
              hintText: widget.provider.hasClientSecret
                  ? l10n.oauthSettingsClientSecretHintKeep
                  : l10n.oauthSettingsClientSecretHintNotSet,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.oauthSettingsEnabledLabel),
            value: _isEnabled,
            onChanged: (value) => setState(() => _isEnabled = value),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _ProviderFormResult(
                clientId: _clientIdController.text.trim(),
                clientSecret: _clientSecretController.text.trim().isEmpty
                    ? null
                    : _clientSecretController.text.trim(),
                isEnabled: _isEnabled,
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
