import 'package:dio/dio.dart';

import 'web_cookie_adapter_stub.dart'
    if (dart.library.js_interop) 'web_cookie_adapter_web.dart'
    as implementation;

/// Enables credentialed browser requests without importing web-only APIs into
/// Android, iOS, desktop, or test builds.
void configureBrowserCookieTransport(Dio dio) {
  implementation.configureBrowserCookieTransport(dio);
}
