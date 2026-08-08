import 'package:dio/dio.dart';

import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';

class PlatformAdminException implements Exception {
  const PlatformAdminException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isForbidden => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class PlatformOrganization {
  const PlatformOrganization({
    required this.id,
    required this.name,
    required this.status,
    required this.membersCount,
    required this.createdAt,
    this.primaryOwner,
    this.lastActivityAt,
  });

  final int id;
  final String name;
  final String status;
  final int membersCount;
  final DateTime? createdAt;
  final PlatformOwner? primaryOwner;
  final DateTime? lastActivityAt;

  bool get isActive => status == 'active';

  factory PlatformOrganization.fromJson(Map<String, dynamic> json) {
    final owner = json['primary_owner'];
    return PlatformOrganization(
      id: _intValue(json['id']),
      name: _stringValue(json['name']),
      status: _stringValue(json['status'], fallback: 'active'),
      membersCount: _intValue(json['members_count']),
      createdAt: _dateValue(json['created_at']),
      primaryOwner: owner is Map<String, dynamic>
          ? PlatformOwner.fromJson(owner)
          : null,
      lastActivityAt: _dateValue(json['last_activity_at']),
    );
  }
}

class PlatformOwner {
  const PlatformOwner({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory PlatformOwner.fromJson(Map<String, dynamic> json) => PlatformOwner(
    id: _intValue(json['id']),
    name: _stringValue(json['name']),
    email: _stringValue(json['email']),
  );
}

class PlatformMembership {
  const PlatformMembership({
    required this.organizationId,
    required this.organizationName,
    required this.organizationStatus,
    required this.role,
    required this.status,
  });

  final int organizationId;
  final String organizationName;
  final String organizationStatus;
  final String role;
  final String status;

  factory PlatformMembership.fromJson(Map<String, dynamic> json) {
    final organization =
        json['organization'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return PlatformMembership(
      organizationId: _intValue(organization['id']),
      organizationName: _stringValue(organization['name']),
      organizationStatus: _stringValue(
        organization['status'],
        fallback: 'active',
      ),
      role: _stringValue(json['role']),
      status: _stringValue(json['status'], fallback: 'active'),
    );
  }
}

class PlatformUser {
  const PlatformUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.isSuperAdmin,
    required this.memberships,
    this.createdAt,
    this.lastLoginAt,
  });

  final int id;
  final String name;
  final String email;
  final bool isActive;
  final bool isSuperAdmin;
  final List<PlatformMembership> memberships;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  factory PlatformUser.fromJson(Map<String, dynamic> json) {
    final rawMemberships = json['memberships'];
    return PlatformUser(
      id: _intValue(json['id']),
      name: _stringValue(json['name']),
      email: _stringValue(json['email']),
      isActive: json['is_active'] == true,
      isSuperAdmin: json['is_super_admin'] == true,
      memberships: rawMemberships is List<dynamic>
          ? rawMemberships
                .whereType<Map<String, dynamic>>()
                .map(PlatformMembership.fromJson)
                .toList(growable: false)
          : const <PlatformMembership>[],
      createdAt: _dateValue(json['created_at']),
      lastLoginAt: _dateValue(json['last_login_at']),
    );
  }
}

class PlatformDashboardData {
  const PlatformDashboardData({
    required this.organizationsTotal,
    required this.organizationsActive,
    required this.organizationsInactive,
    required this.usersTotal,
    required this.usersLast30Days,
    required this.organizationsWithoutActiveOwner,
    required this.latestOrganizations,
    required this.latestUsers,
  });

  final int organizationsTotal;
  final int organizationsActive;
  final int organizationsInactive;
  final int usersTotal;
  final int usersLast30Days;
  final int organizationsWithoutActiveOwner;
  final List<PlatformOrganization> latestOrganizations;
  final List<PlatformUser> latestUsers;

  factory PlatformDashboardData.fromJson(Map<String, dynamic> json) {
    final stats =
        json['statistics'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return PlatformDashboardData(
      organizationsTotal: _intValue(stats['organizations_total']),
      organizationsActive: _intValue(stats['organizations_active']),
      organizationsInactive: _intValue(stats['organizations_inactive']),
      usersTotal: _intValue(stats['users_total']),
      usersLast30Days: _intValue(stats['users_last_30_days']),
      organizationsWithoutActiveOwner: _intValue(
        stats['organizations_without_active_owner'],
      ),
      latestOrganizations: _organizations(json['latest_organizations']),
      latestUsers: _users(json['latest_users']),
    );
  }
}

class PlatformPage<T> {
  const PlatformPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
}

class PlatformOrganizationDetails {
  const PlatformOrganizationDetails({
    required this.organization,
    required this.members,
    required this.socialAccounts,
    required this.postsSummary,
  });

  final PlatformOrganization organization;
  final List<PlatformOrganizationMember> members;
  final List<Map<String, dynamic>> socialAccounts;
  final Map<String, int> postsSummary;

  factory PlatformOrganizationDetails.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final rawAccounts = json['social_accounts'];
    final rawSummary = json['posts_summary'];
    return PlatformOrganizationDetails(
      organization: PlatformOrganization.fromJson(
        json['organization'] as Map<String, dynamic>,
      ),
      members: rawMembers is List<dynamic>
          ? rawMembers
                .whereType<Map<String, dynamic>>()
                .map(PlatformOrganizationMember.fromJson)
                .toList(growable: false)
          : const <PlatformOrganizationMember>[],
      socialAccounts: rawAccounts is List<dynamic>
          ? rawAccounts.whereType<Map<String, dynamic>>().toList(
              growable: false,
            )
          : const <Map<String, dynamic>>[],
      postsSummary: rawSummary is Map<String, dynamic>
          ? rawSummary.map((key, value) => MapEntry(key, _intValue(value)))
          : const <String, int>{},
    );
  }
}

class PlatformOrganizationMember {
  const PlatformOrganizationMember({
    required this.user,
    required this.role,
    required this.status,
  });

  final PlatformUser user;
  final String role;
  final String status;

  factory PlatformOrganizationMember.fromJson(Map<String, dynamic> json) {
    final rawUser =
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PlatformOrganizationMember(
      user: PlatformUser.fromJson(rawUser),
      role: _stringValue(json['role']),
      status: _stringValue(json['status'], fallback: 'active'),
    );
  }
}

class PlatformAdminRepository {
  PlatformAdminRepository({required this.networkClient});

  final NetworkClient networkClient;

  Future<PlatformDashboardData> getDashboard() async {
    final response = await _get(LaravelEndpoints.platformAdminDashboard);
    return PlatformDashboardData.fromJson(_map(_unwrap(response.data)));
  }

  Future<PlatformPage<PlatformOrganization>> getOrganizations({
    String? search,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _get(
      LaravelEndpoints.platformAdminOrganizations,
      queryParameters: <String, dynamic>{
        if (search?.trim().isNotEmpty ?? false) 'search': search!.trim(),
        if (status case final String status) 'status': status,
        'page': page,
        'per_page': perPage,
      },
    );
    final raw = _unwrap(response.data);
    final envelope = _map(response.data);
    final meta =
        envelope['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PlatformPage(
      items: _organizations(raw),
      currentPage: _intValue(meta['current_page'], fallback: page),
      lastPage: _intValue(meta['last_page'], fallback: 1),
      total: _intValue(meta['total']),
    );
  }

  Future<PlatformOrganizationDetails> getOrganization(int id) async {
    final response = await _get(
      LaravelEndpoints.platformAdminOrganizationById(id.toString()),
    );
    return PlatformOrganizationDetails.fromJson(_map(_unwrap(response.data)));
  }

  Future<PlatformOrganization> createOrganization({
    required String name,
    int? ownerUserId,
    String? newOwnerName,
    String? newOwnerEmail,
    String? newOwnerPassword,
  }) async {
    final response = await _post(
      LaravelEndpoints.platformAdminOrganizations,
      data: <String, dynamic>{
        'name': name,
        if (ownerUserId case final int ownerUserId)
          'owner_user_id': ownerUserId,
        if (ownerUserId case null)
          'new_owner': <String, dynamic>{
            'name': newOwnerName,
            'email': newOwnerEmail,
            'password': newOwnerPassword,
          },
      },
    );
    return PlatformOrganization.fromJson(_map(_unwrap(response.data)));
  }

  Future<void> updateOrganizationStatus(int id, String status) async {
    await _post(
      LaravelEndpoints.platformAdminOrganizationStatus(id.toString()),
      data: <String, dynamic>{'status': status},
    );
  }

  Future<void> updateOrganization({
    required int id,
    required String name,
  }) async {
    await _put(
      LaravelEndpoints.platformAdminOrganizationById(id.toString()),
      data: <String, dynamic>{'name': name},
    );
  }

  Future<PlatformPage<PlatformUser>> getUsers({
    String? search,
    bool? isActive,
    bool? isSuperAdmin,
    int? organizationId,
    String? membershipRole,
    int page = 1,
  }) async {
    final response = await _get(
      LaravelEndpoints.platformAdminUsers,
      queryParameters: <String, dynamic>{
        if (search?.trim().isNotEmpty ?? false) 'search': search!.trim(),
        if (isActive case final bool isActive) 'is_active': isActive,
        if (isSuperAdmin case final bool isSuperAdmin)
          'is_super_admin': isSuperAdmin,
        if (organizationId case final int organizationId)
          'organization_id': organizationId,
        if (membershipRole case final String membershipRole)
          'membership_role': membershipRole,
        'page': page,
      },
    );
    final raw = _unwrap(response.data);
    final envelope = _map(response.data);
    final meta =
        envelope['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PlatformPage(
      items: _users(raw),
      currentPage: _intValue(meta['current_page'], fallback: page),
      lastPage: _intValue(meta['last_page'], fallback: 1),
      total: _intValue(meta['total']),
    );
  }

  Future<PlatformUser> createUser({
    required String name,
    required String email,
    required String password,
    int? organizationId,
    String? membershipRole,
  }) async {
    final response = await _post(
      LaravelEndpoints.platformAdminUsers,
      data: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        if (organizationId case final int organizationId)
          'organization_id': organizationId,
        if (membershipRole case final String membershipRole)
          'membership_role': membershipRole,
      },
    );
    return PlatformUser.fromJson(_map(_unwrap(response.data)));
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String email,
  }) async {
    await _put(
      LaravelEndpoints.platformAdminUserById(id.toString()),
      data: <String, dynamic>{'name': name, 'email': email},
    );
  }

  Future<void> updateUserStatus(int id, bool isActive) async {
    await _post(
      LaravelEndpoints.platformAdminUserStatus(id.toString()),
      data: <String, dynamic>{'is_active': isActive},
    );
  }

  Future<void> updatePlatformRole(int id, bool isSuperAdmin) async {
    await _post(
      LaravelEndpoints.platformAdminUserRole(id.toString()),
      data: <String, dynamic>{'is_super_admin': isSuperAdmin},
    );
  }

  Future<void> syncMemberships(
    int id,
    List<PlatformMembership> memberships,
  ) async {
    await _put(
      LaravelEndpoints.platformAdminUserMemberships(id.toString()),
      data: <String, dynamic>{
        'memberships': memberships
            .map(
              (membership) => <String, dynamic>{
                'organization_id': membership.organizationId,
                'role': membership.role,
                'status': membership.status,
              },
            )
            .toList(growable: false),
      },
    );
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await networkClient.get(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw _exception(error);
    }
  }

  Future<Response<dynamic>> _post(String path, {dynamic data}) async {
    try {
      return await networkClient.post(path, data: data);
    } on DioException catch (error) {
      throw _exception(error);
    }
  }

  Future<Response<dynamic>> _put(String path, {dynamic data}) async {
    try {
      return await networkClient.put(path, data: data);
    } on DioException catch (error) {
      throw _exception(error);
    }
  }

  PlatformAdminException _exception(DioException error) {
    final raw = error.response?.data;
    final map = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final message = _stringValue(
      map['message'],
      fallback: 'تعذر تنفيذ طلب إدارة المنصة.',
    );
    return PlatformAdminException(
      message,
      statusCode: error.response?.statusCode,
    );
  }

  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }
}

List<PlatformOrganization> _organizations(dynamic raw) => raw is List<dynamic>
    ? raw
          .whereType<Map<String, dynamic>>()
          .map(PlatformOrganization.fromJson)
          .toList(growable: false)
    : const <PlatformOrganization>[];

List<PlatformUser> _users(dynamic raw) => raw is List<dynamic>
    ? raw
          .whereType<Map<String, dynamic>>()
          .map(PlatformUser.fromJson)
          .toList(growable: false)
    : const <PlatformUser>[];

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String _stringValue(Object? value, {String fallback = ''}) {
  final result = value?.toString() ?? '';
  return result.isEmpty ? fallback : result;
}

int _intValue(Object? value, {int fallback = 0}) =>
    (value as num?)?.toInt() ??
    int.tryParse(value?.toString() ?? '') ??
    fallback;

DateTime? _dateValue(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
