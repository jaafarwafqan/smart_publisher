class OrganizationEntity {
  const OrganizationEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.isCurrent,
    this.permissions = const <String>{},
  });

  final int id;
  final String name;
  final String slug;

  /// owner|admin|manager|editor|viewer — mirrors App\Enums\OrganizationRole
  /// on the backend. Kept for display (role badges, member lists) — UI
  /// authorization decisions must go through [permissions], never branch on
  /// this name directly.
  final String role;
  final bool isCurrent;

  /// Sprint E (role/permission remediation): resolved server-side from
  /// App\Enums\OrganizationRole::permissions() and sent directly by
  /// GET /organizations / POST /organizations/{id}/switch — this is the
  /// single source of truth Flutter consumes, replacing a hand-maintained
  /// role-name-to-permissions map that risked drifting from the backend.
  final Set<String> permissions;
}
