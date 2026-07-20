import '../../domain/publish_target.dart';

class PostRequestDtoV1 {
  const PostRequestDtoV1({
    required this.title,
    required this.content,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
    this.scheduledAt,
  });

  final String title;
  final String content;
  final List<String> attachments;
  final List<String> platforms;
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'content': content,
      'attachments': attachments,
      'platforms': platforms,
      'scheduled_at': scheduledAt?.toIso8601String(),
    };
  }
}

class PostUpdateRequestDtoV1 {
  const PostUpdateRequestDtoV1({required this.title, required this.content});

  final String title;
  final String content;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'content': content};
  }
}

class PostResponseDtoV1 {
  const PostResponseDtoV1({
    required this.id,
    required this.title,
    required this.content,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
  });

  final String id;
  final String title;
  final String content;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final List<String> attachments;
  final List<String> platforms;

  factory PostResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return PostResponseDtoV1(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      status: (json['status'] ?? 'draft') as String,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      scheduledAt: _parseDate(json['scheduled_at']),
      attachments: _parseStringList(json['attachments']),
      platforms: _parseStringList(json['platforms']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List<dynamic>) {
      return value
          .whereType<Object>()
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}

class PublishRequestDtoV1 {
  const PublishRequestDtoV1({
    required this.postId,
    required this.platformIds,
    this.scheduleAt,
  });

  final String postId;
  final List<String> platformIds;
  final DateTime? scheduleAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'post_id': postId,
      'platform_ids': platformIds,
      'schedule_at': scheduleAt?.toIso8601String(),
    };
  }

  factory PublishRequestDtoV1.fromTargets({
    required String postId,
    required List<PublishTarget> targets,
    DateTime? scheduleAt,
  }) {
    return PublishRequestDtoV1(
      postId: postId,
      platformIds: targets.map((target) => target.destinationKey).toList(),
      scheduleAt: scheduleAt,
    );
  }
}
