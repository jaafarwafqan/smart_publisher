import '../../../../core/base/base_entity.dart';

enum PlatformType {
  facebook,
  instagram,
  telegram,
  whatsapp,
  threads,
  linkedin,
  x,
}

class PlatformEntity extends BaseEntity {
  const PlatformEntity({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
  });

  @override
  final String id;
  final String name;
  final PlatformType type;
  final bool isConnected;
}
