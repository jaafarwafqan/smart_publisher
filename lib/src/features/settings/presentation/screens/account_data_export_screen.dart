import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../backend_contracts/v1/account_contract_v1.dart';
import '../../../../core/di/app_providers.dart';
import '../../../auth/application/auth_session_controller.dart';

/// Sprint 4 (Commercial SaaS): "download my data" —
/// GET /account/data-export. Shown as a readable summary rather than a raw
/// file, since this build has no file-download/share dependency wired up;
/// "Copy full data as JSON" is the actual export mechanism today.
class AccountDataExportScreen extends ConsumerStatefulWidget {
  const AccountDataExportScreen({super.key});

  @override
  ConsumerState<AccountDataExportScreen> createState() =>
      _AccountDataExportScreenState();
}

class _AccountDataExportScreenState
    extends ConsumerState<AccountDataExportScreen> {
  DataExportDtoV1? _export;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final export = await ref
          .read(authSessionControllerProvider)
          .exportMyData();
      if (!mounted) {
        return;
      }
      setState(() => _export = export);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is AuthSessionException
            ? error.message
            : AppLocalizations.of(context)!.dataExportLoadError;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _copyJson() async {
    final export = _export;
    if (export == null) {
      return;
    }
    final pretty = const JsonEncoder.withIndent('  ').convert(export.rawJson);
    await Clipboard.setData(ClipboardData(text: pretty));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.dataExportCopiedMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataExportAppBarTitle)),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text(l10n.dataExportRetryButton),
              ),
            ],
          ),
        ),
      );
    }

    final export = _export!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(l10n.dataExportIntro),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.dataExportUserSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(export.userName),
                Text(export.userEmail),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              _CountTile(
                icon: Icons.business_outlined,
                label: l10n.dataExportOrganizationsCount,
                count: export.organizationsCount,
              ),
              _CountTile(
                icon: Icons.article_outlined,
                label: l10n.dataExportPostsCount,
                count: export.postsCount,
              ),
              _CountTile(
                icon: Icons.link_outlined,
                label: l10n.dataExportSocialAccountsCount,
                count: export.socialAccountsCount,
              ),
              _CountTile(
                icon: Icons.perm_media_outlined,
                label: l10n.dataExportMediaAttachmentsCount,
                count: export.mediaAttachmentsCount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text(l10n.dataExportExportedAtLabel),
          subtitle: Text(export.exportedAt),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _copyJson,
          icon: const Icon(Icons.copy_outlined),
          label: Text(l10n.dataExportCopyJsonButton),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$count', style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
