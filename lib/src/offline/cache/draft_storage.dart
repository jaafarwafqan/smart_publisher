import '../../features/posts/domain/entities/post_entity.dart';

class DraftStorage {
  DraftStorage() : _drafts = <String, PostEntity>{};

  final Map<String, PostEntity> _drafts;

  Future<void> saveDraft(PostEntity draft) async {
    _drafts[draft.id] = draft;
  }

  Future<PostEntity?> getDraft(String postId) async {
    return _drafts[postId];
  }

  Future<List<PostEntity>> listDrafts() async {
    return _drafts.values.toList(growable: false);
  }

  Future<void> deleteDraft(String postId) async {
    _drafts.remove(postId);
  }
}
