class MediaUploadRequestDtoV1 {
  const MediaUploadRequestDtoV1({
    required this.postId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  final String postId;
  final String fileName;
  final String mimeType;
  final int fileSize;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'post_id': postId,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
    };
  }
}

class MediaResponseDtoV1 {
  const MediaResponseDtoV1({
    required this.id,
    required this.postId,
    required this.url,
    this.mimeType = 'application/octet-stream',
    this.sizeInBytes = 0,
    this.isCompressed = false,
    this.thumbnailUrl,
    this.collection = 'default',
    this.tags = const <String>[],
    this.createdAt,
    this.duplicateOfId,
  });

  final String id;
  final String postId;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final bool isCompressed;
  final String? thumbnailUrl;
  final String collection;
  final List<String> tags;
  final DateTime? createdAt;

  /// Set only on the upload response, and only when an earlier upload with
  /// identical content already exists for this user — informational, the
  /// upload itself always succeeds regardless.
  final String? duplicateOfId;

  factory MediaResponseDtoV1.fromJson(Map<String, dynamic> json) {
    final meta =
        json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return MediaResponseDtoV1(
      id: _asString(json['id']),
      postId: _asString(json['post_id'] ?? json['postId']),
      url: _asString(json['url'], fallback: _asString(json['path'])),
      mimeType: _asString(
        json['mime_type'] ?? json['mimeType'],
        fallback: 'application/octet-stream',
      ),
      sizeInBytes: _asInt(
        json['size_in_bytes'] ?? json['sizeInBytes'] ?? json['size'],
      ),
      isCompressed:
          (meta['compressed'] ??
                  json['is_compressed'] ??
                  json['isCompressed'] ??
                  false)
              as bool,
      thumbnailUrl: json['thumbnail_path'] == null
          ? null
          : _asString(json['thumbnail_path']),
      collection: _asString(json['collection'], fallback: 'default'),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((tag) => tag.toString())
          .toList(growable: false),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      duplicateOfId: json['duplicate_of_id'] == null
          ? null
          : _asString(json['duplicate_of_id']),
    );
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
