import 'dart:convert';

import '../../core/storage/storage_service.dart';
import '../../features/posts/domain/entities/post_entity.dart';

/// Phase 1 (2026-08-16): previously an in-memory-only `Map` whose
/// `getDraft`/`listDrafts` were never actually called by anything —
/// [PostRepositoryImpl] wrote every draft here on every create/update but
/// read from its own separate, equally non-persistent `_inMemoryStore`
/// instead. The practical effect: a post created/edited while offline
/// survived a hot-reload but was gone from every read path (`getPost`,
/// `getPosts`) the moment the app process restarted — even though the
/// outbox's own queued mutation (a different, already-persistent concern;
/// see [OutboxStore]) would still be sitting there ready to replay once a
/// connection came back. This class is now the actual persistent local
/// cache backing those reads, mirroring [OutboxStore]'s own
/// hydrate-once/persist-on-write pattern against the same [StorageService].
class DraftStorage {
  DraftStorage({this._storage});

  static const _storageKey = 'draft_posts_v1';

  final Map<String, PostEntity> _drafts = <String, PostEntity>{};
  final StorageService? _storage;
  Future<void>? _hydration;

  Future<void> _ensureHydrated() {
    return _hydration ??= _hydrate();
  }

  Future<void> _hydrate() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }

    final raw = await storage.readString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _drafts[entry.key] = _postFromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    } catch (_) {
      // Persisted draft state is corrupted/unreadable — start clean rather
      // than crash app startup over cached data we can no longer trust. The
      // server (or a still-queued outbox entry) remains the real source of
      // truth for anything lost here.
    }
  }

  Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }

    final serialized = _drafts.map(
      (id, draft) => MapEntry(id, _postToJson(draft)),
    );
    await storage.writeString(_storageKey, jsonEncode(serialized));
  }

  Future<void> saveDraft(PostEntity draft) async {
    await _ensureHydrated();
    _drafts[draft.id] = draft;
    await _persist();
  }

  Future<PostEntity?> getDraft(String postId) async {
    await _ensureHydrated();
    return _drafts[postId];
  }

  Future<List<PostEntity>> listDrafts() async {
    await _ensureHydrated();
    return _drafts.values.toList(growable: false);
  }

  Future<void> deleteDraft(String postId) async {
    await _ensureHydrated();
    _drafts.remove(postId);
    await _persist();
  }

  static Map<String, dynamic> _postToJson(PostEntity post) {
    return <String, dynamic>{
      'id': post.id,
      'title': post.title,
      'body': post.body,
      'status': post.status,
      'created_at': post.createdAt?.toIso8601String(),
      'updated_at': post.updatedAt?.toIso8601String(),
      'ai_improved': post.aiImproved,
      'has_media': post.hasMedia,
      'scheduled_at': post.scheduledAt?.toIso8601String(),
      'published_at': post.publishedAt?.toIso8601String(),
      'attachments': post.attachments,
      'platforms': post.platforms,
      'target_page_ids': post.targetPageIds,
      'platform_content': post.platformContent,
      'rich_content': post.richContent,
      'approval_status': post.approvalStatus,
      'approval_requested_action': post.approvalRequestedAction,
      'approval_note': post.approvalNote,
      'approved_by_name': post.approvedByName,
      'author_name': post.authorName,
    };
  }

  static PostEntity _postFromJson(Map<String, dynamic> json) {
    return PostEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      aiImproved: json['ai_improved'] as bool? ?? false,
      hasMedia: json['has_media'] as bool? ?? false,
      scheduledAt: _parseDate(json['scheduled_at']),
      publishedAt: _parseDate(json['published_at']),
      attachments: List<String>.from(
        json['attachments'] as List<dynamic>? ?? const <String>[],
      ),
      platforms: List<String>.from(
        json['platforms'] as List<dynamic>? ?? const <String>[],
      ),
      targetPageIds: List<String>.from(
        json['target_page_ids'] as List<dynamic>? ?? const <String>[],
      ),
      platformContent: Map<String, String>.from(
        json['platform_content'] as Map<dynamic, dynamic>? ??
            const <String, String>{},
      ),
      richContent: _richContent(json['rich_content']),
      approvalStatus: json['approval_status'] as String?,
      approvalRequestedAction: json['approval_requested_action'] as String?,
      approvalNote: json['approval_note'] as String?,
      approvedByName: json['approved_by_name'] as String?,
      authorName: json['author_name'] as String?,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static List<Map<String, dynamic>> _richContent(Object? value) {
    if (value is! List<dynamic>) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
