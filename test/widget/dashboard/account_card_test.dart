import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/account_entity.dart';
import 'package:smart_publisher/src/features/dashboard/application/account_operation_access.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/widgets/account_card.dart';

import '../../helpers/localized_test_app.dart';

const _managerAccess = AccountOperationAccess(
  canCreate: true,
  canUpdate: true,
  canConnect: true,
  canDisconnect: true,
  canDelete: true,
  canTest: true,
  canRefresh: true,
  canSyncPages: true,
  canSelectPages: true,
);

Future<void> _pump(
  WidgetTester tester,
  AccountEntity account, {
  AccountOperationAccess operationAccess = _managerAccess,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: Scaffold(
        body: AccountCard(
          account: account,
          onConnect: () async {},
          onDisconnect: () async {},
          onRefreshToken: () async {},
          onTestConnection: () async {},
          onSyncPages: () async {},
          onAddChannel: () async {},
          onSaveSelection: (pageIds) async {},
          onDeletePage: (pageId) async {},
          operationAccess: operationAccess,
        ),
      ),
    ),
  );
}

void main() {
  const base = AccountEntity(
    id: 'facebook',
    name: 'Business Page',
    platform: 'facebook',
  );

  testWidgets('disconnected: shows only Connect', (tester) async {
    await _pump(tester, base.copyWith(status: AccountStatus.disconnected));

    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    expect(find.text('Disconnect'), findsNothing);
    expect(find.text('Refresh Token'), findsNothing);
  });

  testWidgets(
    'connected with a refresh token: shows Disconnect and Refresh Token, never Connect',
    (tester) async {
      await _pump(
        tester,
        base.copyWith(status: AccountStatus.connected, hasRefreshToken: true),
      );

      expect(find.text('Connect'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Disconnect'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Refresh Token'),
        findsOneWidget,
      );
    },
  );

  testWidgets('connected without a refresh token: shows only Disconnect', (
    tester,
  ) async {
    await _pump(
      tester,
      base.copyWith(status: AccountStatus.connected, hasRefreshToken: false),
    );

    expect(find.widgetWithText(OutlinedButton, 'Disconnect'), findsOneWidget);
    expect(find.text('Refresh Token'), findsNothing);
    expect(find.text('Connect'), findsNothing);
  });

  testWidgets(
    'expired: Refresh Token is the primary action, Disconnect also available',
    (tester) async {
      await _pump(
        tester,
        base.copyWith(status: AccountStatus.expired, hasRefreshToken: true),
      );

      expect(
        find.widgetWithText(FilledButton, 'Refresh Token'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Disconnect'), findsOneWidget);
      expect(find.text('Connect'), findsNothing);
    },
  );

  testWidgets(
    'pending: shows neither Connect nor Disconnect nor Refresh Token',
    (tester) async {
      await _pump(tester, base.copyWith(status: AccountStatus.pending));

      expect(find.text('Connect'), findsNothing);
      expect(find.text('Disconnect'), findsNothing);
      expect(find.text('Refresh Token'), findsNothing);
      expect(find.textContaining('Working on it'), findsOneWidget);
    },
  );

  for (final status in <String>[AccountStatus.revoked, AccountStatus.failed]) {
    testWidgets('$status: shows only Connect', (tester) async {
      await _pump(tester, base.copyWith(status: status));

      expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
      expect(find.text('Disconnect'), findsNothing);
      expect(find.text('Refresh Token'), findsNothing);
    });
  }

  testWidgets(
    'expired without a refresh token: shows Re-authenticate instead of a disabled Refresh Token',
    (tester) async {
      await _pump(
        tester,
        base.copyWith(status: AccountStatus.expired, hasRefreshToken: false),
      );

      expect(
        find.widgetWithText(FilledButton, 'Re-authenticate'),
        findsOneWidget,
      );
      expect(find.text('Refresh Token'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Disconnect'), findsOneWidget);
    },
  );

  testWidgets('connected: tapping Test Connection calls the callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(
          body: AccountCard(
            account: base.copyWith(status: AccountStatus.connected),
            onConnect: () async {},
            onDisconnect: () async {},
            onRefreshToken: () async {},
            onTestConnection: () async {
              tapped = true;
            },
            onSyncPages: () async {},
            onAddChannel: () async {},
            onSaveSelection: (pageIds) async {},
            onDeletePage: (pageId) async {},
            operationAccess: _managerAccess,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets(
    'renders token expiry / last synced / last published only when present',
    (tester) async {
      await _pump(
        tester,
        base
            .copyWith(status: AccountStatus.connected)
            .copyWith(lastSyncedAt: DateTime.now()),
      );

      expect(find.textContaining('Last synced:'), findsOneWidget);
      expect(find.textContaining('Token expires:'), findsNothing);
      expect(find.textContaining('Last published:'), findsNothing);
    },
  );

  testWidgets(
    'a connected non-beta platform exposes no operational account actions',
    (tester) async {
      await _pump(
        tester,
        const AccountEntity(
          id: 'whatsapp',
          name: 'WhatsApp Business',
          platform: 'whatsapp',
          status: AccountStatus.connected,
          hasRefreshToken: true,
        ),
      );

      expect(find.text('WhatsApp — Coming soon'), findsOneWidget);
      expect(find.text('Connect'), findsNothing);
      expect(find.text('Disconnect'), findsNothing);
      expect(find.text('Refresh Token'), findsNothing);
      expect(find.text('Test Connection'), findsNothing);
    },
  );

  testWidgets(
    'an editor-level denied access exposes no account management controls',
    (tester) async {
      await _pump(
        tester,
        base.copyWith(status: AccountStatus.connected, hasRefreshToken: true),
        operationAccess: const AccountOperationAccess.denied(),
      );

      expect(find.text('Disconnect'), findsNothing);
      expect(find.text('Refresh Token'), findsNothing);
      expect(find.text('Test Connection'), findsNothing);
    },
  );

  group(
    'Instagram — always a derived, read-only row (never a real Connect/Disconnect account)',
    () {
      testWidgets(
        'not connected via Facebook: shows the neutral "Connects via Facebook" row, no Connect button',
        (tester) async {
          await _pump(
            tester,
            const AccountEntity(
              id: 'instagram',
              name: 'Instagram',
              platform: 'instagram',
              status: AccountStatus.disconnected,
            ),
          );

          expect(find.text('Connects via Facebook'), findsOneWidget);
          expect(find.widgetWithText(FilledButton, 'Connect'), findsNothing);
          expect(find.text('Instagram — Coming soon'), findsNothing);
        },
      );

      testWidgets(
        'connected via Facebook (a real linked Instagram Business page was found): shows the green "Connected via Facebook" row, never Disconnect/Refresh/Test or a pages panel',
        (tester) async {
          await _pump(
            tester,
            const AccountEntity(
              id: 'instagram',
              name: 'qolob_tantather_alnoor',
              platform: 'instagram',
              status: AccountStatus.connected,
              discoveryMode: 'auto',
            ),
          );

          expect(find.text('Connected via Facebook'), findsOneWidget);
          expect(find.text('Disconnect'), findsNothing);
          expect(find.text('Refresh Token'), findsNothing);
          expect(find.text('Test Connection'), findsNothing);
          expect(find.text('Nothing added yet.'), findsNothing);
        },
      );

      testWidgets(
        'tapping the row invokes onConnect (shows the "managed via Facebook" explanation)',
        (tester) async {
          var tapped = false;
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: testSupportedLocales,
              home: Scaffold(
                body: AccountCard(
                  account: const AccountEntity(
                    id: 'instagram',
                    name: 'Instagram',
                    platform: 'instagram',
                    status: AccountStatus.disconnected,
                  ),
                  onConnect: () async => tapped = true,
                  onDisconnect: () async {},
                  onRefreshToken: () async {},
                  onTestConnection: () async {},
                  onSyncPages: () async {},
                  onAddChannel: () async {},
                  onSaveSelection: (pageIds) async {},
                  onDeletePage: (pageId) async {},
                  operationAccess: _managerAccess,
                ),
              ),
            ),
          );

          await tester.tap(find.text('Connects via Facebook'));
          await tester.pump();

          expect(tapped, isTrue);
        },
      );
    },
  );
}
