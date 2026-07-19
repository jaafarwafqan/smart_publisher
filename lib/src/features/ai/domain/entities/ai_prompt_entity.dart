import '../../../../core/base/base_entity.dart';

class AiPromptEntity extends BaseEntity {
  const AiPromptEntity({
    required this.id,
    required this.prompt,
    this.context,
    this.createdAt,
  });

  @override
  final String id;
  final String prompt;
  final String? context;
  final DateTime? createdAt;
}
