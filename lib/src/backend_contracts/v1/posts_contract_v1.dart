import '../../domain/publish_target.dart';
import 'media_contract_v1.dart';

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

class PostRequestDtoV1 {
  const PostRequestDtoV1({
    required this.title,
    required this.content,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
    this.targetPageIds = const <String>[],
    this.scheduledAt,
    this.platformContent = const <String, String>{},
  });

  final String title;
  final String content;
  final List<String> attachments;
  final List<String> platforms;
  final List<String> targetPageIds;
  final DateTime? scheduledAt;
  final Map<String, String> platformContent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'content': content,
      'attachments': attachments,
      'platforms': platforms,
      'target_page_ids': targetPageIds.map(int.parse).toList(),
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'meta': <String, dynamic>{'platform_content': platformContent},
    };
  }
}

class PostUpdateRequestDtoV1 {
  const PostUpdateRequestDtoV1({
    required this.title,
    required this.content,
    this.targetPageIds = const <String>[],
    this.platformContent = const <String, String>{},
  });

  final String title;
  final String content;
  final List<String> targetPageIds;
  final Map<String, String> platformContent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'content': content,
      'target_page_ids': targetPageIds.map(int.parse).toList(),
      'meta': <String, dynamic>{'platform_content': platformContent},
    };
  }
}

class PublishNowRequestDtoV1 {
  const PublishNowRequestDtoV1({this.socialPageIds = const <String>[]});

  final List<String> socialPageIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (socialPageIds.isNotEmpty)
        'social_page_ids': socialPageIds.map(int.parse).toList(),
    };
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
    this.publishedAt,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
    this.targetPageIds = const <String>[],
    this.platformContent = const <String, String>{},
    this.approvalStatus,
    this.approvalRequestedAction,
    this.approvalNote,
    this.approvedByName,
    this.authorName,
  });

  final String id;
  final String title;
  final String content;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final List<String> attachments;
  final List<String> platforms;
  final List<String> targetPageIds;
  final Map<String, String> platformContent;

  // Sprint F (role/permission remediation): powers the Approvals screen —
  // null/absent means the post never entered the approval workflow at all
  // (a direct-publish-capable role scheduled/published it itself).
  final String? approvalStatus;
  final String? approvalRequestedAction;
  final String? approvalNote;
  final String? approvedByName;
  final String? authorName;

  factory PostResponseDtoV1.fromJson(Map<String, dynamic> json) {
    final metaValue = json['meta'];
    final meta = metaValue is Map<String, dynamic>
        ? metaValue
        : const <String, dynamic>{};
    // PHP serializes an empty associative array as a JSON `[]`, not `{}` —
    // an empty `platform_content` legitimately arrives as a List here.
    final platformContentValue = meta['platform_content'];
    final rawPlatformContent = platformContentValue is Map<String, dynamic>
        ? platformContentValue
        : const <String, dynamic>{};
    final approvedByValue = json['approved_by'];
    final approvedByMap = approvedByValue is Map<String, dynamic>
        ? approvedByValue
        : null;
    final userValue = json['user'];
    final userMap = userValue is Map<String, dynamic> ? userValue : null;

    return PostResponseDtoV1(
      id: _asString(json['id']),
      title: _asString(json['title']),
      content: _asString(json['content']),
      status: _asString(json['status'], fallback: 'draft'),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      scheduledAt: _parseDate(json['scheduled_at']),
      publishedAt: _parseDate(json['published_at']),
      attachments: _parseMediaAttachmentUrls(json),
      platforms: _parseStringList(json['platforms']),
      targetPageIds: _parseStringList(json['target_page_ids']),
      platformContent: rawPlatformContent.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      approvalStatus: json['approval_status']?.toString(),
      approvalRequestedAction: json['approval_requested_action']?.toString(),
      approvalNote: json['approval_note']?.toString(),
      approvedByName: approvedByMap?['name']?.toString(),
      authorName: userMap?['name']?.toString(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// The real API response nests media as `media_attachments` (full
  /// MediaAttachment objects — see docs/api/openapi_v1.yaml), never a flat
  /// `attachments` string list. Reading a field that plainly doesn't exist
  /// in the real response always silently produced an empty list —
  /// reproduced live: media uploaded and genuinely linked server-side (the
  /// real, tested upload+attach path) simply vanished from the composer
  /// the moment the draft was reopened, because this is exactly where that
  /// reload re-hydrates from. Reuses MediaResponseDtoV1's own parsing
  /// (already correct for this exact object shape via the Media Library) —
  /// falls back to a legacy flat `attachments` list only if present, for
  /// any older/other response shape that might still send one.
  static List<String> _parseMediaAttachmentUrls(Map<String, dynamic> json) {
    final mediaAttachments = json['media_attachments'];
    if (mediaAttachments is List<dynamic>) {
      return mediaAttachments
          .whereType<Map<String, dynamic>>()
          .map((item) => MediaResponseDtoV1.fromJson(item).url)
          .where((url) => url.trim().isNotEmpty)
          .toList(growable: false);
    }
    return _parseStringList(json['attachments']);
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

class ScheduleRequestDtoV1 {
  const ScheduleRequestDtoV1({required this.scheduledAt});

  final DateTime scheduledAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    };
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
