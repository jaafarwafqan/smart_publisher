import '../../../../core/result/app_result.dart';
import '../entities/organization_entity.dart';
import '../entities/organization_member_entity.dart';

abstract interface class OrganizationRepository {
  Future<AppResult<List<OrganizationEntity>>> getMyOrganizations();

  /// Switches the active organization server-side (persisted as the user's
  /// current_organization_id) AND locally (so the next request's
  /// X-Organization-Id header reflects it immediately, before any refetch).
  Future<AppResult<OrganizationEntity>> switchTo(int organizationId);

  /// Sprint 4 (Commercial SaaS): members of the CURRENT active
  /// organization (resolved server-side from the tenant context, same as
  /// every other tenant-scoped resource).
  Future<AppResult<List<OrganizationMemberEntity>>> getMembers();

  /// Adds an EXISTING user (by email) to the current organization — this
  /// is not an email-invite flow; the backend requires the email to
  /// already belong to a registered account.
  Future<AppResult<OrganizationMemberEntity>> addMember({
    required String email,
    required String role,
  });

  Future<AppResult<OrganizationMemberEntity>> updateMemberRole({
    required int userId,
    required String role,
  });

  Future<AppResult<void>> removeMember({required int userId});
}
