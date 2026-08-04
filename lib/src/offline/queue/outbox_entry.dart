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
    this.organizationId,
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
  // The organization active on the device at the moment this entry was
  // enqueued. Null only for entries persisted before this field existed
  // (SyncWorker treats null as "unknown, always safe to replay" so old
  // queued entries aren't stranded) — every entry enqueued from now on
  // always carries a real value, and replay is refused if the device's
  // active organization has since changed (see SyncWorker.runOnce).
  final int? organizationId;
  final QueueState state;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final String? resumeToken;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'operation': operation.name,
      'payload': payload,
      'organizationId': organizationId,
      'state': state.name,
      'attempts': attempts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'nextAttemptAt': nextAttemptAt?.toIso8601String(),
      'lastError': lastError,
      'resumeToken': resumeToken,
    };
  }

  factory OutboxEntry.fromJson(Map<String, dynamic> json) {
    return OutboxEntry(
      id: json['id'] as String,
      operation: OutboxOperation.values.byName(json['operation'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      organizationId: json['organizationId'] as int?,
      state: QueueState.values.byName(json['state'] as String),
      attempts: json['attempts'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      nextAttemptAt: json['nextAttemptAt'] == null
          ? null
          : DateTime.parse(json['nextAttemptAt'] as String),
      lastError: json['lastError'] as String?,
      resumeToken: json['resumeToken'] as String?,
    );
  }

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
      organizationId: organizationId,
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
