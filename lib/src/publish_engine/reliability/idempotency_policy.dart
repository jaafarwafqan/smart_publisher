class IdempotencyPolicy {
  IdempotencyPolicy() : _inFlightKeys = <String>{}, _completedKeys = <String>{};

  final Set<String> _inFlightKeys;
  final Set<String> _completedKeys;

  bool acquire(String key) {
    if (_completedKeys.contains(key) || _inFlightKeys.contains(key)) {
      return false;
    }
    _inFlightKeys.add(key);
    return true;
  }

  void complete(String key) {
    _inFlightKeys.remove(key);
    _completedKeys.add(key);
  }

  void release(String key) {
    _inFlightKeys.remove(key);
  }
}
