import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/web/facebook_oauth_callback.dart';

void main() {
  group('FacebookOAuthCallback', () {
    test('a normal app load with no query params is not a callback', () {
      final callback = FacebookOAuthCallback.fromUri(
        Uri.parse('http://localhost:5055/'),
      );

      expect(callback.isCallback, isFalse);
      expect(callback.isSuccess, isFalse);
    });

    test('a successful redirect carries both code and state', () {
      final callback = FacebookOAuthCallback.fromUri(
        Uri.parse('http://localhost:5055/?code=abc&state=xyz'),
      );

      expect(callback.isCallback, isTrue);
      expect(callback.isSuccess, isTrue);
      expect(callback.code, 'abc');
      expect(callback.state, 'xyz');
      expect(callback.error, isNull);
    });

    test('a denied-consent redirect surfaces the error, not a fake success', () {
      final callback = FacebookOAuthCallback.fromUri(
        Uri.parse(
          'http://localhost:5055/?error=access_denied&error_description=User+denied',
        ),
      );

      expect(callback.isCallback, isTrue);
      expect(callback.isSuccess, isFalse);
      expect(callback.error, 'access_denied');
    });

    test(
      'code without state (malformed/tampered redirect) is not treated as success',
      () {
        final callback = FacebookOAuthCallback.fromUri(
          Uri.parse('http://localhost:5055/?code=abc'),
        );

        expect(callback.isCallback, isFalse);
        expect(callback.isSuccess, isFalse);
      },
    );
  });
}
