import 'dart:async';

enum PublishErrorType {
  transient,
  throttling,
  timeout,
  circuitOpen,
  authentication,
  authorization,
  validation,
  permanent,
  unknown,
}

class PublishErrorClassification {
  const PublishErrorClassification({
    required this.type,
    required this.retryable,
    required this.code,
    required this.message,
  });

  final PublishErrorType type;
  final bool retryable;
  final String code;
  final String message;
}

class PublishErrorClassifier {
  const PublishErrorClassifier();

  PublishErrorClassification classify(Object error) {
    if (error is TimeoutException) {
      return PublishErrorClassification(
        type: PublishErrorType.timeout,
        retryable: true,
        code: 'TIMEOUT',
        message: error.message ?? 'Operation timed out.',
      );
    }

    final rawMessage = error.toString();
    final message = rawMessage.toLowerCase();

    if (message.contains('circuit is open')) {
      return const PublishErrorClassification(
        type: PublishErrorType.circuitOpen,
        retryable: true,
        code: 'CIRCUIT_OPEN',
        message: 'Circuit breaker is open.',
      );
    }

    if (message.contains('429') || message.contains('rate limit')) {
      return const PublishErrorClassification(
        type: PublishErrorType.throttling,
        retryable: true,
        code: 'RATE_LIMIT',
        message: 'Rate limit reached.',
      );
    }

    if (message.contains('401')) {
      return const PublishErrorClassification(
        type: PublishErrorType.authentication,
        retryable: false,
        code: 'AUTH_401',
        message: 'Authentication failed.',
      );
    }

    if (message.contains('403')) {
      return const PublishErrorClassification(
        type: PublishErrorType.authorization,
        retryable: false,
        code: 'AUTHZ_403',
        message: 'Authorization failed.',
      );
    }

    if (message.contains('validation') || message.contains('required')) {
      return PublishErrorClassification(
        type: PublishErrorType.validation,
        retryable: false,
        code: 'VALIDATION',
        message: rawMessage,
      );
    }

    if (message.contains('500') ||
        message.contains('502') ||
        message.contains('503')) {
      return PublishErrorClassification(
        type: PublishErrorType.transient,
        retryable: true,
        code: 'SERVER',
        message: rawMessage,
      );
    }

    return PublishErrorClassification(
      type: PublishErrorType.unknown,
      retryable: false,
      code: 'UNKNOWN',
      message: rawMessage,
    );
  }
}
