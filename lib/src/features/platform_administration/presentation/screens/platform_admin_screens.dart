import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/base/pagination.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/organizations/application/current_organization_access.dart';
import '../../../../features/organizations/presentation/screens/organization_audit_log_screen.dart';
import '../../../../shared/models/audit_log_entry.dart';
import '../../../../shared/widgets/adaptive_card_grid.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../data/platform_admin_repository.dart';
import 'platform_admin_state.dart';

part 'platform_admin_dashboard_screens.dart';
part 'platform_admin_organization_screens.dart';
part 'platform_admin_user_screens.dart';
part 'platform_admin_shared_widgets.dart';
part 'platform_admin_dialogs.dart';

const _membershipRoles = <String>[
  'owner',
  'admin',
  'manager',
  'editor',
  'viewer',
];

String _roleLabel(String role, AppLocalizations l10n) {
  return switch (role) {
    'owner' => l10n.platformAdminRoleOwner,
    'admin' => l10n.platformAdminRoleAdmin,
    'manager' => l10n.platformAdminRoleManager,
    'editor' => l10n.platformAdminRoleEditor,
    'viewer' => l10n.platformAdminRoleViewer,
    _ => role,
  };
}

String _formatDate(DateTime? date, AppLocalizations l10n) {
  if (date == null) return l10n.platformAdminNotAvailable;
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
