import 'dart:typed_data';

import '../../../../core/base/base_entity.dart';

class MediaEntity extends BaseEntity {
  const MediaEntity({
    required this.id,
    required this.postId,
    required this.url,
    this.mimeType = 'application/octet-stream',
    this.sizeInBytes = 0,
    this.isCompressed = false,
    this.bytes,
    this.thumbnailUrl,
    this.collection = 'default',
    this.tags = const <String>[],
    this.createdAt,
    this.isDuplicateOfId,
  });

  @override
  final String id;
  final String postId;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final bool isCompressed;

  /// Raw file content, used instead of reading [url] as a filesystem path
  /// when there is no real path to read from (Flutter Web has no
  /// filesystem — file_picker can only return bytes there).
  final Uint8List? bytes;

  final String? thumbnailUrl;
  final String collection;
  final List<String> tags;
  final DateTime? createdAt;

  /// Set only right after upload, and only when an identical file was
  /// already on record for this user — informational, never a block.
  final String? isDuplicateOfId;
}
