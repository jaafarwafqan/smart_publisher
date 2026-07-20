enum QueueState { pending, reserved, processing, completed, retry, deadLetter }

class QueueStateMachine {
  const QueueStateMachine();

  bool canTransition(QueueState from, QueueState to) {
    switch (from) {
      case QueueState.pending:
        return to == QueueState.reserved || to == QueueState.deadLetter;
      case QueueState.reserved:
        return to == QueueState.processing || to == QueueState.retry;
      case QueueState.processing:
        return to == QueueState.completed ||
            to == QueueState.retry ||
            to == QueueState.deadLetter;
      case QueueState.retry:
        return to == QueueState.pending || to == QueueState.deadLetter;
      case QueueState.completed:
        return false;
      case QueueState.deadLetter:
        return false;
    }
  }
}
