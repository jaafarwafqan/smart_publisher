import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';

void configureBrowserCookieTransport(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
