import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/pages/dashboard_screen.dart';

void main() {
  test('mobile OAuth uses the registered production deep link', () {
    expect(
      DashboardScreen.oauthRedirectUriFor(isWeb: false),
      'smartpublisher://oauth/callback',
    );
    expect(
      DashboardScreen.oauthRedirectUriFor(isWeb: true),
      'http://localhost:5055/',
    );
  });
}
