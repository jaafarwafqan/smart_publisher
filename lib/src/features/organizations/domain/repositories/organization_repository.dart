import '../../../../core/result/app_result.dart';
import '../entities/organization_entity.dart';

abstract interface class OrganizationRepository {
  Future<AppResult<List<OrganizationEntity>>> getMyOrganizations();

  /// Switches the active organization server-side (persisted as the user's
  /// current_organization_id) AND locally (so the next request's
  /// X-Organization-Id header reflects it immediately, before any refetch).
  Future<AppResult<OrganizationEntity>> switchTo(int organizationId);
}
