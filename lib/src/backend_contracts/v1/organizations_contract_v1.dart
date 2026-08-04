class OrganizationMembershipDtoV1 {
  const OrganizationMembershipDtoV1({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.isCurrent,
  });

  final int id;
  final String name;
  final String slug;
  final String role;
  final bool isCurrent;

  factory OrganizationMembershipDtoV1.fromJson(Map<String, dynamic> json) {
    return OrganizationMembershipDtoV1(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      role: (json['role'] ?? 'viewer').toString(),
      isCurrent: (json['is_current'] ?? false) as bool,
    );
  }
}
