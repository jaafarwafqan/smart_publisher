import '../../features/platforms/data/platform_dto.dart';
import '../../features/platforms/domain/entities/platform_entity.dart';
import '../../shared/mappers/mapper.dart';

class PlatformMapper extends Mapper<PlatformDto, PlatformEntity> {
  const PlatformMapper();

  @override
  PlatformEntity map(PlatformDto input) {
    return PlatformEntity(
      id: input.id,
      name: input.name,
      typeKey: input.platform,
      isConnected: input.isConnected,
    );
  }
}
