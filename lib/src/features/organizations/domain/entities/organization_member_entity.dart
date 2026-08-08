class OrganizationMemberEntity {
  const OrganizationMemberEntity({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final int userId;
  final String name;
  final String email;

  /// owner|admin|manager|editor|viewer — mirrors App\Enums\OrganizationRole
  /// on the backend.
  final String role;
}
