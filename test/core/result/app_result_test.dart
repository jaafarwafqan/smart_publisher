import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';

void main() {
  group('AppResult', () {
    test('returns success data and preserves state', () {
      const result = Success<String>('created');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 'created');
      expect(result.message, isNull);
    });

    test('returns failure message and exception', () {
      const result = Failure<String>('failed', exception: 'boom');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.message, 'failed');
      expect(result.exception, 'boom');
    });
  });
}
