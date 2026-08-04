class UploadSession {
  UploadSession({
    required this.mediaId,
    required this.filePath,
    required this.totalBytes,
    required this.uploadedBytes,
    this.remoteUploadId,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  final String mediaId;
  final String filePath;
  final int totalBytes;
  final int uploadedBytes;
  final String? remoteUploadId;
  final DateTime startedAt;

  UploadSession copyWith({int? uploadedBytes, String? remoteUploadId}) {
    return UploadSession(
      mediaId: mediaId,
      filePath: filePath,
      totalBytes: totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      remoteUploadId: remoteUploadId ?? this.remoteUploadId,
      startedAt: startedAt,
    );
  }

  bool get isComplete => uploadedBytes >= totalBytes;
}

class ResumableUploadManager {
  ResumableUploadManager() : _sessions = <String, UploadSession>{};

  final Map<String, UploadSession> _sessions;

  /// CTO audit 4.6: there's no cancel-upload flow anywhere in the app today
  /// (confirmed — no UI/repository call site for it), so an upload that's
  /// abandoned any other way (app killed, permanent network loss, user
  /// navigates away mid-upload) previously left its session in this Map
  /// forever, since only [complete] ever removed one. Rather than inventing
  /// a cancel-UX product decision this doesn't call for, [startSession]
  /// opportunistically sweeps anything old enough that it can no longer be
  /// a real in-progress upload — self-limiting, no timer/isolate needed.
  static const _staleAfter = Duration(hours: 2);

  Future<void> startSession(UploadSession session) async {
    _sessions.removeWhere(
      (_, existing) =>
          DateTime.now().difference(existing.startedAt) > _staleAfter,
    );
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
