import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/presentation/screens/organization_switcher_screen.dart';

import '../../helpers/localized_test_app.dart';

Future<void> _pumpSwitcher(
  WidgetTester tester,
  Future<OrganizationAccessState> Function() loadAccess,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        currentOrganizationAccessProvider.overrideWith((_) => loadAccess()),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: OrganizationSwitcherScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a distinct empty state when the user has no memberships', (
    tester,
  ) async {
    await _pumpSwitcher(
      tester,
      () async =>
          OrganizationAccessState.noActiveOrganization(memberships: const []),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('You are not a member of any organization yet.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the membership error and a retry action', (tester) async {
    await _pumpSwitcher(
      tester,
      () async => throw const OrganizationAccessException(
        'Membership service unavailable.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Membership service unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('keeps an explicit loading indicator until memberships resolve', (
    tester,
  ) async {
    final response = Completer<OrganizationAccessState>();
    await _pumpSwitcher(tester, () => response.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(
      OrganizationAccessState.noActiveOrganization(memberships: const []),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You are not a member of any organization yet.'),
      findsOneWidget,
    );
  });
}
