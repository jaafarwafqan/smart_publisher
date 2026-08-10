import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/organizations_contract_v1.dart';
import '../../../core/base/base_repository.dart';
import '../../../core/base/pagination.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../../../core/tenancy/active_organization_store.dart';
import '../../../shared/models/audit_log_entry.dart';
import '../domain/entities/organization_entity.dart';
import '../domain/entities/organization_member_entity.dart';
import '../domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl extends BaseRepository<OrganizationEntity>
    implements OrganizationRepository {
  OrganizationRepositoryImpl({
    required this.networkClient,
    required this.store,
  });

  final NetworkClient? networkClient;
  final ActiveOrganizationStore store;

  @override
  Future<AppResult<List<OrganizationEntity>>> getMyOrganizations() async {
    if (networkClient == null) {
      return Failure<List<OrganizationEntity>>(
        'Loading organizations requires a connection.',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.organizations,
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        return rawItems
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => _toEntity(OrganizationMembershipDtoV1.fromJson(json)),
            )
            .toList(growable: false);
      },
      operation: 'organizations.list',
      fallbackMessage: 'Failed to load organizations',
    );
  }

  @override
  Future<AppResult<OrganizationEntity>> switchTo(int organizationId) async {
    if (networkClient == null) {
      return Failure<OrganizationEntity>(
        'Switching organizations requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.organizationSwitch(organizationId.toString()),
        );
        final payload = Map<String, dynamic>.from(
          _unwrapPayload(response.data) as Map<String, dynamic>,
        )..putIfAbsent('is_current', () => true);
        final dto = OrganizationMembershipDtoV1.fromJson(payload);

        // Only persisted locally after the backend confirms the switch is
        // valid — never optimistically, since an invalid organizationId must
        // never silently become "active" on the device.
        await store.write(dto.id);

        return _toEntity(dto);
      },
      operation: 'organizations.switch',
      fallbackMessage: 'Failed to switch organizations',
    );
  }

  @override
  Future<AppResult<List<OrganizationMemberEntity>>> getMembers() async {
    if (networkClient == null) {
      return Failure<List<OrganizationMemberEntity>>(
        'Loading members requires a connection.',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.organizationMembers,
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        return rawItems
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => _toMemberEntity(OrganizationMemberDtoV1.fromJson(json)),
            )
            .toList(growable: false);
      },
      operation: 'organizations.members.list',
      fallbackMessage: 'Failed to load members',
    );
  }

  @override
  Future<AppResult<OrganizationMemberEntity>> addMember({
    required String email,
    required String role,
  }) async {
    if (networkClient == null) {
      return Failure<OrganizationMemberEntity>(
        'Adding a member requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.organizationMembers,
          data: <String, dynamic>{'email': email, 'role': role},
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid response from server.');
        }
        return _toMemberEntity(OrganizationMemberDtoV1.fromJson(payload));
      },
      operation: 'organizations.members.add',
      fallbackMessage: 'Failed to add member',
    );
  }

  @override
  Future<AppResult<OrganizationMemberEntity>> updateMemberRole({
    required int userId,
    required String role,
  }) async {
    if (networkClient == null) {
      return Failure<OrganizationMemberEntity>(
        'Updating a member requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.put(
          LaravelEndpoints.organizationMemberById(userId.toString()),
          data: <String, dynamic>{'role': role},
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid response from server.');
        }
        // update() only returns {user_id, role} — not the member's name/
        // email — so those are filled in from the caller's already-known
        // copy rather than re-fetching the whole list just for this.
        return OrganizationMemberEntity(
          userId: (payload['user_id'] as num?)?.toInt() ?? userId,
          name: '',
          email: '',
          role: (payload['role'] ?? role).toString(),
        );
      },
      operation: 'organizations.members.update_role',
      fallbackMessage: 'Failed to update member role',
    );
  }

  @override
  Future<AppResult<void>> removeMember({required int userId}) async {
    if (networkClient == null) {
      return const Failure<void>('Removing a member requires a connection.');
    }

    return execute(
      () async {
        await networkClient!.delete(
          LaravelEndpoints.organizationMemberById(userId.toString()),
        );
      },
      operation: 'organizations.members.remove',
      fallbackMessage: 'Failed to remove member',
    );
  }

  @override
  Future<AppResult<PaginatedResult<AuditLogEntry>>> getAuditLogs({
    required int organizationId,
    int page = 1,
    int perPage = 25,
    String? action,
    String? dateFrom,
    String? dateTo,
  }) async {
    if (networkClient == null) {
      return Failure<PaginatedResult<AuditLogEntry>>(
        'Loading the audit log requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.organizationAuditLogs(organizationId.toString()),
          queryParameters: <String, dynamic>{
            'page': page,
            'per_page': perPage,
            if (action?.trim().isNotEmpty ?? false) 'action': action!.trim(),
            if (dateFrom case final String dateFrom) 'date_from': dateFrom,
            if (dateTo case final String dateTo) 'date_to': dateTo,
          },
        );
        final envelope = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : const <String, dynamic>{};
        final rawItems = _unwrapPayload(envelope);
        final meta = envelope['meta'] is Map<String, dynamic>
            ? envelope['meta'] as Map<String, dynamic>
            : const <String, dynamic>{};
        final items = rawItems is List<dynamic>
            ? rawItems
                  .whereType<Map<String, dynamic>>()
                  .map(AuditLogEntry.fromJson)
                  .toList(growable: false)
            : const <AuditLogEntry>[];

        return PaginatedResult<AuditLogEntry>(
          items: items,
          page: (meta['current_page'] as num?)?.toInt() ?? page,
          pageSize: (meta['per_page'] as num?)?.toInt() ?? perPage,
          totalCount: (meta['total'] as num?)?.toInt() ?? items.length,
        );
      },
      operation: 'organizations.audit_logs.list',
      fallbackMessage: 'Failed to load the audit log',
    );
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }

  OrganizationMemberEntity _toMemberEntity(OrganizationMemberDtoV1 dto) {
    return OrganizationMemberEntity(
      userId: dto.userId,
      name: dto.name,
      email: dto.email,
      role: dto.role,
    );
  }

  OrganizationEntity _toEntity(OrganizationMembershipDtoV1 dto) {
    return OrganizationEntity(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      role: dto.role,
      isCurrent: dto.isCurrent,
      permissions: dto.permissions.toSet(),
    );
  }
}
