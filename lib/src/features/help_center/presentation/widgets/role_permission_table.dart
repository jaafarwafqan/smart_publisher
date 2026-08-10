import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/help_content_models.dart';

const List<String> _roleOrder = <String>[
  'viewer',
  'editor',
  'manager',
  'admin',
  'owner',
];
const Map<String, String> _roleLabels = <String, String>{
  'viewer': 'Viewer',
  'editor': 'Editor',
  'manager': 'Manager',
  'admin': 'Admin',
  'owner': 'Owner',
};

/// The "من يستطيع فعل ماذا؟" table — every ✓ traces back to
/// `App\Enums\OrganizationRole::permissions()` (see
/// `faq_and_troubleshooting_content.dart::buildRolePermissionRows()`),
/// never a client-invented matrix.
class RolePermissionTable extends StatelessWidget {
  const RolePermissionTable({super.key, required this.rows});

  final List<RolePermissionRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.userGuideRolePermissionTableTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: <DataColumn>[
                  const DataColumn(label: Text('')),
                  ..._roleOrder.map(
                    (role) => DataColumn(label: Text(_roleLabels[role]!)),
                  ),
                ],
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: <DataCell>[
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(row.action, softWrap: true),
                            ),
                          ),
                          ..._roleOrder.map(
                            (role) => DataCell(
                              row.grants(role)
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 18,
                                    )
                                  : Icon(
                                      Icons.remove,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
