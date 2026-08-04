import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/network/laravel_api.dart';

void main() {
  group('release network configuration', () {
    test(
      'requires HTTPS endpoints rather than localhost development defaults',
      () {
        expect(
          LaravelApi.isSecureProductionEndpoint('http://127.0.0.1:8000/api/v1'),
          isFalse,
        );
        expect(
          LaravelApi.hasSecureReleaseEndpoints(
            api: 'https://api.example.test/api/v1',
            auth: 'https://api.example.test/api/v1',
            oauth: 'https://api.example.test',
          ),
          isTrue,
        );
      },
    );
  });
}
