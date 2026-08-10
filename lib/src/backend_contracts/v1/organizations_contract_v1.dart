/// Sprint 4 (Commercial SaaS): a member of the CURRENT active organization
/// — distinct from [OrganizationMembershipDtoV1], which lists the
/// organizations *I* belong to. Mirrors
/// `OrganizationMembershipController::index/store/update`'s response shape.
class OrganizationMemberDtoV1 {
  const OrganizationMemberDtoV1({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final int userId;
  final String name;
  final String email;

  /// owner|admin|manager|editor|viewer.
  final String role;

  factory OrganizationMemberDtoV1.fromJson(Map<String, dynamic> json) {
    return OrganizationMemberDtoV1(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'viewer').toString(),
    );
  }
}

class OrganizationMembershipDtoV1 {
  const OrganizationMembershipDtoV1({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.isCurrent,
    required this.permissions,
  });

  final int id;
  final String name;
  final String slug;
  final String role;
  final bool isCurrent;

  // Sprint E (role/permission remediation): resolved server-side from
  // App\Enums\OrganizationRole::permissions() — both GET /organizations
  // and POST /organizations/{id}/switch include it.
  final List<String> permissions;

  factory OrganizationMembershipDtoV1.fromJson(Map<String, dynamic> json) {
    return OrganizationMembershipDtoV1(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      role: (json['role'] ?? 'viewer').toString(),
      isCurrent: (json['is_current'] ?? false) as bool,
      permissions: (json['permissions'] as List<dynamic>? ?? const <dynamic>[])
          .map((permission) => permission.toString())
          .toList(growable: false),
    );
  }
}
