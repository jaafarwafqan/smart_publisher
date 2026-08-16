import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/social_page_entity.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/widgets/account_pages_panel.dart';

import '../../helpers/localized_test_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<SocialPageEntity> pages,
  required String discoveryMode,
  Future<void> Function()? onSync,
  Future<void> Function()? onAddChannel,
  Future<void> Function(List<String>)? onSaveSelection,
  Future<void> Function(String)? onDeletePage,
  bool canSync = true,
  bool canSelect = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: Scaffold(
        body: AccountPagesPanel(
          pages: pages,
          discoveryMode: discoveryMode,
          onSync: onSync ?? () async {},
          onAddChannel: onAddChannel ?? () async {},
          onSaveSelection: onSaveSelection ?? (_) async {},
          onDeletePage: onDeletePage ?? (_) async {},
          canSync: canSync,
          canSelect: canSelect,
        ),
      ),
    ),
  );
  await tester.tap(find.byType(ExpansionTile));
  await tester.pumpAndSettle();
}

void main() {
  const channel = SocialPageEntity(
    id: '9',
    socialAccountId: '42',
    pageId: '-1001',
    kind: 'channel',
    name: 'Nursing Channel',
    canPublish: true,
    status: SocialPageStatus.valid,
  );

  testWidgets('manual discovery shows Add Channel, not Sync Pages', (
    tester,
  ) async {
    await _pump(
      tester,
      pages: const <SocialPageEntity>[channel],
      discoveryMode: 'manual',
    );

    expect(find.text('Add Channel'), findsOneWidget);
    expect(find.text('Sync Pages'), findsNothing);
  });

  testWidgets('auto discovery shows Sync Pages, not Add Channel', (
    tester,
  ) async {
    await _pump(
      tester,
      pages: const <SocialPageEntity>[channel],
      discoveryMode: 'auto',
    );

    expect(find.text('Sync Pages'), findsOneWidget);
    expect(find.text('Add Channel'), findsNothing);
  });

  testWidgets('empty pages list shows the empty state, not a crash', (
    tester,
  ) async {
    await _pump(
      tester,
      pages: const <SocialPageEntity>[],
      discoveryMode: 'manual',
    );

    expect(find.text('Nothing added yet.'), findsOneWidget);
  });

  testWidgets(
    'toggling a page enables Save Selection, which reports the new ids',
    (tester) async {
      List<String>? saved;
      await _pump(
        tester,
        pages: const <SocialPageEntity>[channel],
        discoveryMode: 'manual',
        onSaveSelection: (ids) async => saved = ids,
      );

      final saveButtonFinder = find.widgetWithText(
        FilledButton,
        'Save Selection',
      );
      expect(tester.widget<FilledButton>(saveButtonFinder).onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(saveButtonFinder).onPressed,
        isNotNull,
      );
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(saved, <String>['9']);
    },
  );

  testWidgets(
    'an embedded Instagram Business page is selectable; WhatsApp stays visibly disabled and excluded on save',
    (tester) async {
      const facebookPage = SocialPageEntity(
        id: 'facebook-page',
        socialAccountId: '42',
        pageId: 'facebook-page-1',
        kind: 'page',
        name: 'Launch Page',
        status: SocialPageStatus.valid,
      );
      // 2026-08: instagram_business graduated into the closed beta (see
      // platform_label.dart's isBetaLaunchPublishingTargetForDiscoveryMode)
      // — no longer an "embedded non-beta" kind like whatsapp_number below.
      const instagramPage = SocialPageEntity(
        id: '10',
        socialAccountId: '42',
        pageId: 'ig-1',
        kind: 'instagram_business',
        name: 'my_business',
        isSelected: true,
        status: SocialPageStatus.valid,
      );
      const whatsappPage = SocialPageEntity(
        id: '11',
        socialAccountId: '43',
        pageId: 'phone-1',
        kind: 'whatsapp_number',
        name: 'Support Line',
        isSelected: true,
        status: SocialPageStatus.valid,
      );
      List<String>? saved;

      await _pump(
        tester,
        pages: const <SocialPageEntity>[
          facebookPage,
          instagramPage,
          whatsappPage,
        ],
        discoveryMode: 'auto',
        onSaveSelection: (ids) async => saved = ids,
      );

      expect(find.text('my_business — Instagram — Coming soon'), findsNothing);
      expect(
        find.text('Support Line — WhatsApp — Coming soon'),
        findsOneWidget,
      );

      final tiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      // facebookPage: eligible, not pre-selected.
      expect(tiles.elementAt(0).value, isFalse);
      expect(tiles.elementAt(0).onChanged, isNotNull);
      // instagramPage: eligible now, and pre-selected (isSelected: true).
      expect(tiles.elementAt(1).value, isTrue);
      expect(tiles.elementAt(1).onChanged, isNotNull);
      // whatsappPage: still not an eligible beta target.
      expect(tiles.elementAt(2).value, isFalse);
      expect(tiles.elementAt(2).onChanged, isNull);

      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save Selection'));
      await tester.pumpAndSettle();

      expect(saved, <String>['facebook-page', '10']);
    },
  );

  testWidgets('a non-manager sees pages but no page-management actions', (
    tester,
  ) async {
    await _pump(
      tester,
      pages: const <SocialPageEntity>[channel],
      discoveryMode: 'manual',
      canSync: false,
      canSelect: false,
    );

    expect(find.text('Nursing Channel'), findsOneWidget);
    expect(find.text('Add Channel'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('Save Selection'), findsNothing);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged,
      isNull,
    );
  });
}
