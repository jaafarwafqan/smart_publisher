import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/network/backend_error_message.dart';

void main() {
  group('extractBackendErrorMessage', () {
    test('prefers the first field-specific validation message on a 422', () {
      final message = extractBackendErrorMessage(<String, dynamic>{
        'success': false,
        'message': 'Validation failed',
        'errors': <String, dynamic>{
          'new_owner.password': <String>[
            'The new owner.password field must contain at least one symbol.',
          ],
        },
      }, 422);

      expect(
        message,
        'The new owner.password field must contain at least one symbol.',
      );
    });

    test('falls back to the top-level message on a 422 with no errors map', () {
      final message = extractBackendErrorMessage(<String, dynamic>{
        'success': false,
        'message': 'Validation failed',
      }, 422);

      expect(message, 'Validation failed');
    });

    test(
      'uses the top-level message for non-422 statuses, ignoring internal error codes',
      () {
        final message = extractBackendErrorMessage(<String, dynamic>{
          'success': false,
          'message': 'Unauthenticated.',
          'errors': <String, dynamic>{
            'code': <String>['unauthenticated'],
          },
        }, 401);

        // Must NOT return the internal code "unauthenticated" — that's
        // never meant for display.
        expect(message, 'Unauthenticated.');
      },
    );

    test('returns null for a non-map response body', () {
      expect(extractBackendErrorMessage('plain text', 500), isNull);
      expect(extractBackendErrorMessage(null, 500), isNull);
    });

    test('returns null when message is missing or empty', () {
      expect(extractBackendErrorMessage(<String, dynamic>{}, 500), isNull);
      expect(
        extractBackendErrorMessage(<String, dynamic>{'message': ''}, 500),
        isNull,
      );
    });
  });
}
