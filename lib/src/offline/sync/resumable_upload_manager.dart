class UploadSession {
  const UploadSession({
    required this.mediaId,
    required this.filePath,
    required this.totalBytes,
    required this.uploadedBytes,
    this.remoteUploadId,
  });

  final String mediaId;
  final String filePath;
  final int totalBytes;
  final int uploadedBytes;
  final String? remoteUploadId;

  UploadSession copyWith({int? uploadedBytes, String? remoteUploadId}) {
    return UploadSession(
      mediaId: mediaId,
      filePath: filePath,
      totalBytes: totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      remoteUploadId: remoteUploadId ?? this.remoteUploadId,
    );
  }

  bool get isComplete => uploadedBytes >= totalBytes;
}

class ResumableUploadManager {
  ResumableUploadManager() : _sessions = <String, UploadSession>{};

  final Map<String, UploadSession> _sessions;

  Future<void> startSession(UploadSession session) async {
    _sessions[session.mediaId] = session;
  }

  Future<UploadSession?> getSession(String mediaId) async {
    return _sessions[mediaId];
  }

  Future<void> updateProgress(String mediaId, int uploadedBytes) async {
    final existing = _sessions[mediaId];
    if (existing == null) {
      return;
    }
    _sessions[mediaId] = existing.copyWith(uploadedBytes: uploadedBytes);
  }

  Future<void> complete(String mediaId) async {
    _sessions.remove(mediaId);
  }
}
