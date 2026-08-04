import '../../../../core/base/base_entity.dart';

class PostEntity extends BaseEntity {
  const PostEntity({
    required this.id,
    required this.title,
    required this.body,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.aiImproved = false,
    this.hasMedia = false,
    this.scheduledAt,
    this.publishedAt,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
    this.targetPageIds = const <String>[],
    this.platformContent = const <String, String>{},
  });

  @override
  final String id;
  final String title;
  final String body;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool aiImproved;
  final bool hasMedia;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final List<String> attachments;
  final List<String> platforms;

  /// Backend `social_pages.id` values this post targets — the specific
  /// Pages/Channels/Business Accounts selected in the composer, not just
  /// platform strings.
  final List<String> targetPageIds;

  /// Optional per-platform caption override — keyed by provider (e.g.
  /// `facebook`, `telegram`). Empty/absent means "use the shared [body]" for
  /// that platform.
  final Map<String, String> platformContent;

  PostEntity copyWith({
    String? id,
    String? title,
    String? body,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? aiImproved,
    bool? hasMedia,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    List<String>? attachments,
    List<String>? platforms,
    List<String>? targetPageIds,
    Map<String, String>? platformContent,
  }) {
    return PostEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiImproved: aiImproved ?? this.aiImproved,
      hasMedia: hasMedia ?? this.hasMedia,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      publishedAt: publishedAt ?? this.publishedAt,
      attachments: attachments ?? this.attachments,
      platforms: platforms ?? this.platforms,
      targetPageIds: targetPageIds ?? this.targetPageIds,
      platformContent: platformContent ?? this.platformContent,
    );
  }
}
