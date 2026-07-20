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

class MediaCompressRequestDtoV1 {
  const MediaCompressRequestDtoV1({required this.mediaId});

  final String mediaId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'media_id': mediaId};
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
  });

  final String id;
  final String postId;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final bool isCompressed;

  factory MediaResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return MediaResponseDtoV1(
      id: (json['id'] ?? '') as String,
      postId: (json['post_id'] ?? json['postId'] ?? '') as String,
      url: (json['url'] ?? '') as String,
      mimeType:
          (json['mime_type'] ?? json['mimeType'] ?? 'application/octet-stream')
              as String,
      sizeInBytes: (json['size_in_bytes'] ?? json['sizeInBytes'] ?? 0) as int,
      isCompressed:
          (json['is_compressed'] ?? json['isCompressed'] ?? false) as bool,
    );
  }
}
