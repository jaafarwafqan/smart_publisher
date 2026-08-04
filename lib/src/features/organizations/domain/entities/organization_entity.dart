class OrganizationEntity {
  const OrganizationEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.isCurrent,
  });

  final int id;
  final String name;
  final String slug;

  /// owner|admin|manager|editor|viewer — mirrors App\Enums\OrganizationRole
  /// on the backend.
  final String role;
  final bool isCurrent;
}
