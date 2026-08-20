import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/pagination.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/models/audit_log_entry.dart';
import '../../data/platform_admin_repository.dart';

typedef PlatformOrganizationsQuery = ({String search, String status, int page});

typedef PlatformUsersQuery = ({
  String search,
  bool? isActive,
  bool? isSuperAdmin,
  int? organizationId,
  String? membershipRole,
  int page,
});

typedef PlatformAuditLogQuery = ({
  String search,
  int? organizationId,
  int page,
});

final platformDashboardProvider =
    FutureProvider.autoDispose<PlatformDashboardData>((ref) {
      return ref.read(platformAdminRepositoryProvider).getDashboard();
    });

final platformOrganizationsQueryProvider =
    StateProvider.autoDispose<PlatformOrganizationsQuery>((ref) {
      return (search: '', status: 'all', page: 1);
    });

final platformOrganizationsPageProvider = FutureProvider.autoDispose
    .family<PlatformPage<PlatformOrganization>, PlatformOrganizationsQuery>((
      ref,
      query,
    ) {
      return ref
          .read(platformAdminRepositoryProvider)
          .getOrganizations(
            search: query.search,
            status: query.status == 'all' ? null : query.status,
            page: query.page,
          );
    });

final platformOrganizationDetailsProvider = FutureProvider.autoDispose
    .family<PlatformOrganizationDetails, int>((ref, organizationId) {
      return ref
          .read(platformAdminRepositoryProvider)
          .getOrganization(organizationId);
    });

final platformFilterOrganizationsProvider =
    FutureProvider.autoDispose<PlatformPage<PlatformOrganization>>((ref) {
      return ref
          .read(platformAdminRepositoryProvider)
          .getOrganizations(page: 1, perPage: 100);
    });

final platformUsersQueryProvider =
    StateProvider.autoDispose<PlatformUsersQuery>((ref) {
      return (
        search: '',
        isActive: null,
        isSuperAdmin: null,
        organizationId: null,
        membershipRole: null,
        page: 1,
      );
    });

final platformUsersPageProvider = FutureProvider.autoDispose
    .family<PlatformPage<PlatformUser>, PlatformUsersQuery>((ref, query) {
      return ref
          .read(platformAdminRepositoryProvider)
          .getUsers(
            search: query.search,
            isActive: query.isActive,
            isSuperAdmin: query.isSuperAdmin,
            organizationId: query.organizationId,
            membershipRole: query.membershipRole,
            page: query.page,
          );
    });

final platformAuditLogQueryProvider =
    StateProvider.autoDispose<PlatformAuditLogQuery>((ref) {
      return (search: '', organizationId: null, page: 1);
    });

final platformAuditLogPageProvider = FutureProvider.autoDispose
    .family<PaginatedResult<AuditLogEntry>, PlatformAuditLogQuery>((
      ref,
      query,
    ) {
      return ref
          .read(platformAdminRepositoryProvider)
          .getAuditLogs(
            action: query.search,
            organizationId: query.organizationId,
            page: query.page,
          );
    });
