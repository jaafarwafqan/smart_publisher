class QueueManager {
  const QueueManager();

  Future<void> enqueue(Object job) async {
    await Future<void>.value();
    if (job is! String) {
      throw ArgumentError('Job must be a string reference.');
    }
  }
}
