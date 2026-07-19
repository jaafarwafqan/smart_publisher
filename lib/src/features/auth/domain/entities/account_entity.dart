import '../../../../core/base/base_entity.dart';

class AccountEntity extends BaseEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.platform,
    this.isConnected = false,
  });

  @override
  final String id;
  final String name;
  final String platform;
  final bool isConnected;
}
