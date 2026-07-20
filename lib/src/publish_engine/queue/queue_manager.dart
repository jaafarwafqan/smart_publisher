import '../jobs/publish_job.dart';

class QueueManager {
  QueueManager() : _jobs = <String, PublishJob>{}, _order = <String>[];

  final Map<String, PublishJob> _jobs;
  final List<String> _order;

  Future<void> enqueue(PublishJob job) async {
    _jobs[job.id] = job;
    if (!_order.contains(job.id)) {
      _order.add(job.id);
    }
  }

  Future<PublishJob?> findById(String id) async {
    return _jobs[id];
  }

  Future<void> markProcessing(String id) async {
    final job = _jobs[id];
    if (job == null) {
      return;
    }
    _jobs[id] = job.copyWith(
      status: PublishJobStatus.processing,
      clearRetryAt: true,
    );
  }

  Future<void> markSucceeded(String id) async {
    final job = _jobs[id];
    if (job == null) {
      return;
    }
    _jobs[id] = job.copyWith(
      status: PublishJobStatus.succeeded,
      clearRetryAt: true,
      clearError: true,
      completedAt: DateTime.now(),
    );
  }

  Future<void> markFailed(
    String id, {
    required String errorCode,
    required String errorMessage,
    DateTime? retryAt,
    bool incrementRetryCount = false,
  }) async {
    final job = _jobs[id];
    if (job == null) {
      return;
    }
    _jobs[id] = job.copyWith(
      status: PublishJobStatus.failed,
      retryCount: incrementRetryCount ? job.retryCount + 1 : job.retryCount,
      lastErrorCode: errorCode,
      lastErrorMessage: errorMessage,
      nextRetryAt: retryAt,
    );
  }

  List<PublishJob> readyForRecovery({DateTime? now}) {
    final time = now ?? DateTime.now();
    return _order
        .map((id) => _jobs[id])
        .whereType<PublishJob>()
        .where((job) {
          if (job.status == PublishJobStatus.pending) {
            return true;
          }
          if (job.status != PublishJobStatus.failed) {
            return false;
          }
          final retryAt = job.nextRetryAt;
          return retryAt != null && !retryAt.isAfter(time);
        })
        .toList(growable: false);
  }
}
