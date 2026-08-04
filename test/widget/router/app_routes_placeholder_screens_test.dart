import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/app_routes.dart';
import 'package:smart_publisher/src/core/theme/app_colors.dart';
import 'package:smart_publisher/src/core/theme/app_input_theme.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  testWidgets(
    'WelcomeScreen renders localized text, not a hardcoded English literal',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          home: WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Smart Publisher'), findsOneWidget);
      expect(
        find.text(
          'Manage publishing, scheduling, accounts, and delivery from one control surface.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue to Login'), findsOneWidget);
    },
  );

  test(
    'dark-mode input border is no longer identical to the dark fill color',
    () {
      const darkScheme = ColorScheme.dark();
      final theme = AppInputTheme.theme(colorScheme: darkScheme);
      final borderColor =
          (theme.enabledBorder as OutlineInputBorder?)?.borderSide.color;

      expect(borderColor, isNotNull);
      expect(borderColor, isNot(equals(AppColors.surfaceDark)));
    },
  );
}
