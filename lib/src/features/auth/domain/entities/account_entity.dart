import '../../../../core/base/base_entity.dart';

class AccountEntity extends BaseEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.platform,
    this.isConnected = false,
    this.avatarUrl,
    this.status = 'Disconnected',
    this.permissions = const <String>[],
  });

  @override
  final String id;
  final String name;
  final String platform;
  final bool isConnected;
  final String? avatarUrl;
  final String status;
  final List<String> permissions;

  AccountEntity copyWith({
    String? id,
    String? name,
    String? platform,
    bool? isConnected,
    String? avatarUrl,
    String? status,
    List<String>? permissions,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      isConnected: isConnected ?? this.isConnected,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
    );
  }
}
