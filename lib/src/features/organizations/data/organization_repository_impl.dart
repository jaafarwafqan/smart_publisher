import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/organizations_contract_v1.dart';
import '../../../core/base/base_repository.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../../../core/tenancy/active_organization_store.dart';
import '../domain/entities/organization_entity.dart';
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

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }

  OrganizationEntity _toEntity(OrganizationMembershipDtoV1 dto) {
    return OrganizationEntity(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      role: dto.role,
      isCurrent: dto.isCurrent,
    );
  }
}
