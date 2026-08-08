import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/account_operation_access.dart';
import '../../../auth/domain/entities/account_entity.dart';
import '../utils/platform_label.dart';
import 'account_pages_panel.dart';

String _formatDate(DateTime dt, AppLocalizations l10n) {
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

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefreshToken,
    required this.onTestConnection,
    required this.onSyncPages,
    required this.onAddChannel,
    required this.onSaveSelection,
    required this.onDeletePage,
    this.operationAccess = const AccountOperationAccess.denied(),
  });

  final AccountEntity account;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<void> Function() onRefreshToken;
  final Future<void> Function() onTestConnection;
  final Future<void> Function() onSyncPages;
  final Future<void> Function() onAddChannel;
  final Future<void> Function(List<String> pageIds) onSaveSelection;
  final Future<void> Function(String pageId) onDeletePage;
  final AccountOperationAccess operationAccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final initial = account.name.isEmpty ? '?' : account.name[0];
    final permissions = account.permissions.isEmpty
        ? l10n.accountCardNoPermissions
        : account.permissions.join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    initial.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            platformLabel(account.platform),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (isBetaLaunchPlatform(account.platform)) ...[
                            const SizedBox(width: AppSpacing.sm),
                            StatusPill(
                              label: l10n.betaTag,
                              tone: PillTone.warning,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            StatusPill(
              label: _accountStatusLabel(account.status, l10n),
              tone: _accountStatusTone(account.status),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              permissions,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (account.isConnected &&
                (account.tokenExpiresAt != null ||
                    account.lastSyncedAt != null ||
                    account.lastPublishedAt != null)) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                <String>[
                  if (account.tokenExpiresAt != null)
                    l10n.accountCardTokenExpires(
                      _formatDate(account.tokenExpiresAt!, l10n),
                    ),
                  if (account.lastSyncedAt != null)
                    l10n.accountCardLastSynced(
                      _formatDate(account.lastSyncedAt!, l10n),
                    ),
                  if (account.lastPublishedAt != null)
                    l10n.accountCardLastPublished(
                      _formatDate(account.lastPublishedAt!, l10n),
                    ),
                ].join(' • '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Only Facebook and Telegram are approved for this closed beta.
            // A connected legacy/non-launch account may remain visible for
            // diagnosis, but it must never expose connect, publish-related,
            // token, or page-management actions as if those worked here.
            if (!isBetaLaunchPlatform(account.platform))
              _ComingSoonRow(platform: account.platform)
            else ...[
              _ActionRow(
                status: account.status,
                hasRefreshToken: account.hasRefreshToken,
                onConnect: onConnect,
                onDisconnect: onDisconnect,
                onRefreshToken: onRefreshToken,
                onTestConnection: onTestConnection,
                operationAccess: operationAccess,
              ),
            ],
            if (account.isConnected &&
                isBetaLaunchPlatform(account.platform)) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              AccountPagesPanel(
                pages: account.pages,
                discoveryMode: account.discoveryMode,
                onSync: onSyncPages,
                onAddChannel: onAddChannel,
                onSaveSelection: onSaveSelection,
                onDeletePage: onDeletePage,
                canManagePages: operationAccess.canManagePages,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Replaces the Connect button entirely for platforms whose backend
/// integration is still `GenericOAuthProvider` (CTO audit P0-5) — never
/// offers an action that would silently "succeed" against a mock.
class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow({required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.hourglass_top,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              l10n.comingSoonSuffix(platformLabel(platform)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PillTone _accountStatusTone(String status) {
  switch (status) {
    case AccountStatus.connected:
      return PillTone.success;
    case AccountStatus.pending:
      return PillTone.warning;
    case AccountStatus.expired:
    case AccountStatus.revoked:
    case AccountStatus.failed:
      return PillTone.danger;
    case AccountStatus.disconnected:
    default:
      return PillTone.neutral;
  }
}

String _accountStatusLabel(String status, AppLocalizations l10n) {
  switch (status) {
    case AccountStatus.connected:
      return l10n.accountStatusConnected;
    case AccountStatus.expired:
      return l10n.accountStatusExpired;
    case AccountStatus.revoked:
      return l10n.accountStatusRevoked;
    case AccountStatus.failed:
      return l10n.accountStatusFailed;
    case AccountStatus.pending:
      return l10n.accountStatusPending;
    case AccountStatus.disconnected:
    default:
      return l10n.accountStatusDisconnected;
  }
}

/// The button set is driven entirely by [status] — never both a "Connect"
/// and a "Disconnect" affordance at once, which is what made the previous
/// design confusing (both always rendered, one merely disabled).
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.status,
    required this.hasRefreshToken,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefreshToken,
    required this.onTestConnection,
    required this.operationAccess,
  });

  final String status;
  final bool hasRefreshToken;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<void> Function() onRefreshToken;
  final Future<void> Function() onTestConnection;
  final AccountOperationAccess operationAccess;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case AccountStatus.connected:
        final actions = <Widget>[
          if (operationAccess.canDisconnect)
            OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l10n.actionDisconnect),
            ),
          if (hasRefreshToken && operationAccess.canConnect)
            OutlinedButton.icon(
              onPressed: onRefreshToken,
              icon: const Icon(Icons.autorenew, size: 18),
              label: Text(l10n.actionRefreshToken),
            ),
          if (operationAccess.canConnect)
            OutlinedButton.icon(
              onPressed: onTestConnection,
              icon: const Icon(Icons.wifi_tethering, size: 18),
              label: Text(l10n.actionTestConnection),
            ),
        ];
        if (actions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(spacing: 8, runSpacing: 8, children: actions);
      case AccountStatus.expired:
        final actions = <Widget>[
          if (operationAccess.canConnect)
            if (hasRefreshToken)
              FilledButton.icon(
                onPressed: onRefreshToken,
                icon: const Icon(Icons.autorenew, size: 18),
                label: Text(l10n.actionRefreshToken),
              )
            else
              FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.login, size: 18),
                label: Text(l10n.actionReauthenticate),
              ),
          if (operationAccess.canConnect)
            OutlinedButton.icon(
              onPressed: onTestConnection,
              icon: const Icon(Icons.wifi_tethering, size: 18),
              label: Text(l10n.actionTestConnection),
            ),
          if (operationAccess.canDisconnect)
            OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l10n.actionDisconnect),
            ),
        ];
        if (actions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions /*
            // dead end — the only way forward is a full re-authentication,
            // not a silent token refresh that can't succeed.
            if (hasRefreshToken)
              FilledButton.icon(
                onPressed: onRefreshToken,
                icon: const Icon(Icons.autorenew, size: 18),
                label: Text(l10n.actionRefreshToken),
              )
            else
              FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.login, size: 18),
                label: Text(l10n.actionReauthenticate),
              ),
            testConnectionButton,
            OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l10n.actionDisconnect),
            ),
          ], */,
        );
      case AccountStatus.pending:
        return Chip(
          avatar: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text(l10n.actionWorkingOnIt),
        );
      case AccountStatus.revoked:
      case AccountStatus.failed:
      case AccountStatus.disconnected:
      default:
        if (!operationAccess.canConnect) {
          return const SizedBox.shrink();
        }
        return FilledButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.link, size: 18),
          label: Text(l10n.actionConnect),
        );
    }
  }
}
