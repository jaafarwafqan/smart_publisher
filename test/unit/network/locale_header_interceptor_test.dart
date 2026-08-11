import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/network/network_interceptor.dart';

void main() {
  group('LocaleHeaderInterceptor', () {
    test('sends the current locale language code as Accept-Language', () async {
      final interceptor = LocaleHeaderInterceptor(
        localeReader: () => const Locale('ar'),
      );
      final options = RequestOptions(path: '/posts');

      final handler = _CapturingRequestHandler();
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(options.headers['Accept-Language'], 'ar');
    });

    test('reads the locale fresh on every request, not just once', () async {
      var current = const Locale('en');
      final interceptor = LocaleHeaderInterceptor(localeReader: () => current);

      final firstOptions = RequestOptions(path: '/posts');
      await interceptor.onRequest(firstOptions, _CapturingRequestHandler());
      expect(firstOptions.headers['Accept-Language'], 'en');

      // Simulates the user switching language mid-session (see
      // LocaleNotifier.setLocale) — the very next request must reflect it
      // without reconstructing the interceptor/network client.
      current = const Locale('ar');
      final secondOptions = RequestOptions(path: '/posts');
      await interceptor.onRequest(secondOptions, _CapturingRequestHandler());
      expect(secondOptions.headers['Accept-Language'], 'ar');
    });
  });
}

class _CapturingRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(
    RequestOptions requestOptions, {
    bool? callFollowingErrorInterceptor,
  }) {
    nextCalled = true;
  }
}
