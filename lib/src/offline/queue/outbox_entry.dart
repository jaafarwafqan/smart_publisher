import 'queue_state_machine.dart';

enum OutboxOperation {
  createPost,
  updatePost,
  deletePost,
  uploadMedia,
  compressMedia,
  deleteMedia,
  publishPost,
}

class OutboxEntry {
  OutboxEntry({
    required this.id,
    required this.operation,
    required this.payload,
    this.state = QueueState.pending,
    this.attempts = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.nextAttemptAt,
    this.lastError,
    this.resumeToken,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final OutboxOperation operation;
  final Map<String, dynamic> payload;
  final QueueState state;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final String? resumeToken;

  OutboxEntry copyWith({
    QueueState? state,
    int? attempts,
    DateTime? nextAttemptAt,
    String? lastError,
    String? resumeToken,
    bool clearNextAttempt = false,
    bool clearError = false,
    bool clearResumeToken = false,
  }) {
    return OutboxEntry(
      id: id,
      operation: operation,
      payload: payload,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      nextAttemptAt: clearNextAttempt
          ? null
          : (nextAttemptAt ?? this.nextAttemptAt),
      lastError: clearError ? null : (lastError ?? this.lastError),
      resumeToken: clearResumeToken ? null : (resumeToken ?? this.resumeToken),
    );
  }
}
