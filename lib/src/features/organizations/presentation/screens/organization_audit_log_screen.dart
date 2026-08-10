import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/base/pagination.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/audit_log_entry.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../application/current_organization_access.dart';

/// Sprint G (role/permission remediation, 2026-08-09): the org-scoped
/// counterpart to `PlatformAuditLogScreen` — an owner/admin (anyone holding
/// `audit_logs.view`) reviewing THIS organization's trail only, via
/// `GET /organizations/{organization}/audit-logs`. See
/// `OrganizationRepository.getAuditLogs()`.
class OrganizationAuditLogScreen extends ConsumerStatefulWidget {
  const OrganizationAuditLogScreen({super.key});

  @override
  ConsumerState<OrganizationAuditLogScreen> createState() =>
      _OrganizationAuditLogScreenState();
}

class _OrganizationAuditLogScreenState
    extends ConsumerState<OrganizationAuditLogScreen> {
  final _actionController = TextEditingController();
  Future<PaginatedResult<AuditLogEntry>>? _entries;
  Object? _error;
  int _page = 1;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    final access = ref.read(currentOrganizationAccessProvider).value;
    final organizationId = access?.currentOrganization?.id;
    if (organizationId == null) {
      return;
    }

    setState(() {
      _page = page ?? 1;
      _error = null;
      _entries = ref
          .read(organizationRepositoryProvider)
          .getAuditLogs(
            organizationId: organizationId,
            page: _page,
            action: _actionController.text,
            dateFrom: _isoDate(_dateFrom),
            dateTo: _isoDate(_dateTo),
          )
          .then((result) {
            if (result.isSuccess && result.data != null) {
              return result.data!;
            }
            throw StateError(result.message ?? 'Failed to load audit log');
          });
    });
  }

  String? _isoDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
      } else {
        _dateTo = picked;
      }
    });
    _reload();
  }

  void _clearFilters() {
    _actionController.clear();
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auditLogAppBarTitle)),
      body: AdaptiveContentWidth(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _AuditLogFilters(
                actionController: _actionController,
                dateFrom: _dateFrom,
                dateTo: _dateTo,
                onActionSubmitted: (_) => _reload(),
                onPickDateFrom: () => _pickDate(isFrom: true),
                onPickDateTo: () => _pickDate(isFrom: false),
                onClear: _clearFilters,
              ),
            ),
            Expanded(
              child: FutureBuilder<PaginatedResult<AuditLogEntry>>(
                future: _entries,
                builder: (context, snapshot) {
                  final state = snapshot.connectionState != ConnectionState.done
                      ? AppAsyncState.loading
                      : snapshot.hasError
                      ? AppAsyncState.error
                      : snapshot.data!.items.isEmpty
                      ? AppAsyncState.empty
                      : AppAsyncState.content;
                  return AppAsyncSwitcher(
                    state: state,
                    loading: const Center(child: CircularProgressIndicator()),
                    error: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppEmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: l10n.auditLogLoadError,
                          message: '${snapshot.error ?? _error ?? ''}',
                          actionLabel: l10n.auditLogRetryButton,
                          onAction: () => _reload(page: _page),
                        ),
                      ),
                    ),
                    empty: Center(
                      child: AppEmptyState(
                        message: l10n.auditLogEmptyMessage,
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                    content: _AuditLogList(
                      page: snapshot.data,
                      onPage: (page) => _reload(page: page),
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

class _AuditLogFilters extends StatelessWidget {
  const _AuditLogFilters({
    required this.actionController,
    required this.dateFrom,
    required this.dateTo,
    required this.onActionSubmitted,
    required this.onPickDateFrom,
    required this.onPickDateTo,
    required this.onClear,
  });

  final TextEditingController actionController;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<String> onActionSubmitted;
  final VoidCallback onPickDateFrom;
  final VoidCallback onPickDateTo;
  final VoidCallback onClear;

  String _format(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: <Widget>[
        TextField(
          controller: actionController,
          onSubmitted: onActionSubmitted,
          decoration: InputDecoration(
            labelText: l10n.auditLogFilterActionLabel,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: onPickDateFrom,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                dateFrom == null
                    ? l10n.auditLogFilterDateFromLabel
                    : _format(dateFrom!),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPickDateTo,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                dateTo == null
                    ? l10n.auditLogFilterDateToLabel
                    : _format(dateTo!),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(l10n.auditLogFilterClearButton),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuditLogList extends StatelessWidget {
  const _AuditLogList({required this.page, required this.onPage});

  final PaginatedResult<AuditLogEntry>? page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final data = page;
    if (data == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        ...data.items.map((entry) => AuditLogTile(entry: entry)),
        AuditLogPagination(page: page, onPage: onPage),
      ],
    );
  }
}

/// Shared between the organization-scoped and platform-wide screens — kept
/// public (unlike the rest of this file's private widgets) so
/// `PlatformAuditLogScreen` can reuse it directly instead of duplicating the
/// same tile/pagination rendering.
class AuditLogTile extends StatelessWidget {
  const AuditLogTile({
    super.key,
    required this.entry,
    this.showOrganization = false,
  });

  final AuditLogEntry entry;
  final bool showOrganization;

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return '';
    }
    final d =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final t =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actorLabel = entry.hasActor
        ? (entry.actorName?.isNotEmpty ?? false)
              ? entry.actorName!
              : entry.actorEmail ?? l10n.auditLogSystemActor
        : l10n.auditLogSystemActor;
    final subtitleParts = <String>[
      if (entry.auditableType != null && entry.auditableId != null)
        l10n.auditLogEntrySubtitle(
          entry.auditableType!,
          entry.auditableId.toString(),
        ),
      if (showOrganization && entry.organizationName != null)
        '${l10n.auditLogOrganizationColumn}: ${entry.organizationName}',
      _formatDateTime(entry.createdAt),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(entry.action),
        subtitle: Text(
          '$actorLabel${subtitleParts.isEmpty ? '' : ' · ${subtitleParts.join(' · ')}'}',
        ),
        isThreeLine: true,
        onTap: (entry.oldValues != null || entry.newValues != null)
            ? () => _showDetails(context, l10n)
            : null,
        trailing: (entry.oldValues != null || entry.newValues != null)
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }

  void _showDetails(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry.action),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.auditLogDetailsOldValues,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_formatValues(entry.oldValues, l10n)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.auditLogDetailsNewValues,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_formatValues(entry.newValues, l10n)),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatValues(Map<String, dynamic>? values, AppLocalizations l10n) {
    if (values == null || values.isEmpty) {
      return l10n.auditLogDetailsNone;
    }
    return values.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class AuditLogPagination extends StatelessWidget {
  const AuditLogPagination({
    super.key,
    required this.page,
    required this.onPage,
  });

  final PaginatedResult<AuditLogEntry>? page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final data = page;
    if (data == null || data.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: data.page > 1 ? () => onPage(data.page - 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(l10n.auditLogPreviousPage),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.auditLogPaginationLabel(
                data.page.toString(),
                data.totalPages.toString(),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: data.page < data.totalPages
                ? () => onPage(data.page + 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(l10n.auditLogNextPage),
          ),
        ],
      ),
    );
  }
}
