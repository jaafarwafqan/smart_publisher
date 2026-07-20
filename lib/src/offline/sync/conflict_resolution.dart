enum ConflictResolutionStrategy { serverWins, clientWins, merge }

class ConflictContext {
  const ConflictContext({
    required this.localPayload,
    required this.remotePayload,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
  });

  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final DateTime? localUpdatedAt;
  final DateTime? remoteUpdatedAt;
}

class ConflictResolver {
  const ConflictResolver({
    this.defaultStrategy = ConflictResolutionStrategy.merge,
  });

  final ConflictResolutionStrategy defaultStrategy;

  Map<String, dynamic> resolve(
    ConflictContext context, {
    ConflictResolutionStrategy? strategy,
  }) {
    final applied = strategy ?? defaultStrategy;
    switch (applied) {
      case ConflictResolutionStrategy.serverWins:
        return Map<String, dynamic>.from(context.remotePayload);
      case ConflictResolutionStrategy.clientWins:
        return Map<String, dynamic>.from(context.localPayload);
      case ConflictResolutionStrategy.merge:
        return _merge(context);
    }
  }

  Map<String, dynamic> _merge(ConflictContext context) {
    final merged = Map<String, dynamic>.from(context.remotePayload);
    merged.addAll(context.localPayload);

    final localAt = context.localUpdatedAt;
    final remoteAt = context.remoteUpdatedAt;
    if (localAt != null && remoteAt != null) {
      merged['updated_at'] = localAt.isAfter(remoteAt)
          ? localAt.toIso8601String()
          : remoteAt.toIso8601String();
    }
    return merged;
  }
}
