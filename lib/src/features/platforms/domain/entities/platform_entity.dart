import '../../../../core/base/base_entity.dart';

class PlatformEntity extends BaseEntity {
  const PlatformEntity({
    required this.id,
    required this.name,
    required this.typeKey,
    this.isConnected = false,
  });

  @override
  final String id;
  final String name;
  final String typeKey;
  final bool isConnected;
}
