class UploadProgress {
  const UploadProgress({
    required this.mediaId,
    required this.totalBytes,
    required this.uploadedBytes,
  });

  final String mediaId;
  final int totalBytes;
  final int uploadedBytes;

  bool get isComplete => uploadedBytes >= totalBytes;
}

class UploadManager {
  UploadManager() : _progressByMediaId = <String, UploadProgress>{};

  final Map<String, UploadProgress> _progressByMediaId;

  void start({required String mediaId, required int totalBytes}) {
    _progressByMediaId[mediaId] = UploadProgress(
      mediaId: mediaId,
      totalBytes: totalBytes,
      uploadedBytes: 0,
    );
  }

  void update({required String mediaId, required int uploadedBytes}) {
    final current = _progressByMediaId[mediaId];
    if (current == null) {
      return;
    }

    _progressByMediaId[mediaId] = UploadProgress(
      mediaId: mediaId,
      totalBytes: current.totalBytes,
      uploadedBytes: uploadedBytes,
    );
  }

  UploadProgress? status(String mediaId) => _progressByMediaId[mediaId];

  void complete(String mediaId) {
    _progressByMediaId.remove(mediaId);
  }
}
