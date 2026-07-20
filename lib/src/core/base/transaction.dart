abstract interface class TransactionRunner {
  Future<T> runInTransaction<T>(Future<T> Function() action);
}

class NoopTransactionRunner implements TransactionRunner {
  const NoopTransactionRunner();

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) {
    return action();
  }
}
