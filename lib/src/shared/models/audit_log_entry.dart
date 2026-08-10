/// Sprint G (role/permission remediation, 2026-08-09): the client-side shape
/// of one row from either audit-log read endpoint —
/// `GET /organizations/{organization}/audit-logs` (org-scoped) and
/// `GET /admin/audit-logs` (platform-wide, super_admin). The two endpoints
/// share almost the same JSON shape (see `IndexAuditLogsRequest` /
/// `OrganizationController::auditLogs()` / `AdminAuditLogController`
/// on the backend); the platform-wide one additionally includes
/// `organization`, `request_id`, and `ip_address`, which are simply left
/// null when reading the org-scoped response.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.auditableType,
    required this.auditableId,
    required this.oldValues,
    required this.newValues,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.actorEmail,
    this.organizationId,
    this.organizationName,
    this.requestId,
    this.ipAddress,
  });

  final int id;
  final String action;
  final String? auditableType;
  final int? auditableId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime? createdAt;
  final int? actorId;
  final String? actorName;
  final String? actorEmail;
  final int? organizationId;
  final String? organizationName;
  final String? requestId;
  final String? ipAddress;

  /// A system-initiated event (no authenticated actor at record time) has no
  /// `actor` in the payload at all — distinct from a since-deleted user,
  /// which the backend has no way to signal separately today.
  bool get hasActor => actorId != null;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    final organization = json['organization'];
    return AuditLogEntry(
      id: _intValue(json['id']),
      action: json['action']?.toString() ?? '',
      auditableType: json['auditable_type']?.toString(),
      auditableId: json['auditable_id'] == null
          ? null
          : _intValue(json['auditable_id']),
      oldValues: json['old_values'] is Map<String, dynamic>
          ? json['old_values'] as Map<String, dynamic>
          : null,
      newValues: json['new_values'] is Map<String, dynamic>
          ? json['new_values'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      actorId: actor is Map<String, dynamic> ? _intValue(actor['id']) : null,
      actorName: actor is Map<String, dynamic>
          ? actor['name']?.toString()
          : null,
      actorEmail: actor is Map<String, dynamic>
          ? actor['email']?.toString()
          : null,
      organizationId: organization is Map<String, dynamic>
          ? _intValue(organization['id'])
          : null,
      organizationName: organization is Map<String, dynamic>
          ? organization['name']?.toString()
          : null,
      requestId: json['request_id']?.toString(),
      ipAddress: json['ip_address']?.toString(),
    );
  }
}

int _intValue(Object? value) =>
    (value as num?)?.toInt() ?? int.tryParse(value?.toString() ?? '') ?? 0;
