import '../../../../core/base/base_entity.dart';

class UserEntity extends BaseEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  @override
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
}
