import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../auth/domain/entities/account_entity.dart';
import '../../application/account_operation_access.dart';
import 'account_card.dart';
import 'dashboard_section_card.dart';

class AccountsGrid extends StatelessWidget {
  const AccountsGrid({
    super.key,
    required this.accounts,
    required this.isLoading,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefreshToken,
    required this.onTestConnection,
    required this.onSyncPages,
    required this.onAddChannel,
    required this.onSaveSelection,
    required this.onDeletePage,
    required this.operationAccess,
  });

  final List<AccountEntity> accounts;
  final bool isLoading;
  final Future<void> Function(AccountEntity account) onConnect;
  final Future<void> Function(AccountEntity account) onDisconnect;
  final Future<void> Function(AccountEntity account) onRefreshToken;
  final Future<void> Function(AccountEntity account) onTestConnection;
  final Future<void> Function(AccountEntity account) onSyncPages;
  final Future<void> Function(AccountEntity account) onAddChannel;
  final Future<void> Function(AccountEntity account, List<String> pageIds)
  onSaveSelection;
  final Future<void> Function(AccountEntity account, String pageId)
  onDeletePage;
  final AccountOperationAccess operationAccess;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading && accounts.isEmpty) {
      return DashboardSectionCard(
        title: l10n.accountsGridTitle,
        subtitle: l10n.accountsGridLoadingSubtitle,
        child: const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return DashboardSectionCard(
      title: l10n.accountsGridTitle,
      subtitle: l10n.accountsGridSubtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 640
              ? 2
              : 1;
          final spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: accounts
                .map(
                  (account) => SizedBox(
                    width: cardWidth,
                    child: AccountCard(
                      account: account,
                      onConnect: () => onConnect(account),
                      onDisconnect: () => onDisconnect(account),
                      onRefreshToken: () => onRefreshToken(account),
                      onTestConnection: () => onTestConnection(account),
                      onSyncPages: () => onSyncPages(account),
                      onAddChannel: () => onAddChannel(account),
                      onSaveSelection: (pageIds) =>
                          onSaveSelection(account, pageIds),
                      onDeletePage: (pageId) => onDeletePage(account, pageId),
                      operationAccess: operationAccess,
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}
