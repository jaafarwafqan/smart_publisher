import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/account_entity.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/account_health_check_entity.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/social_page_entity.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/user_entity.dart';
import 'package:smart_publisher/src/features/auth/domain/repositories/account_repository.dart';
import 'package:smart_publisher/src/features/composer/presentation/pages/create_post_screen.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';
import '../../helpers/organization_role_fixtures.dart';

class _FakeAuthSessionController extends AuthSessionController {
  _FakeAuthSessionController()
    : super(
        networkClient: FakeNetworkClient(),
        tokenLifecycleManager: TokenLifecycleManager(
          tokenStorage: EncryptedTokenStorage(
            secretsManager: InMemorySecretsManager(),
          ),
        ),
        storageService: InMemoryStorageService(),
        authEventPublisher: AuthEventPublisher(
          app_events.EventDispatcher(EventBus()),
        ),
      );

  @override
  Future<AuthSession?> currentSession() async {
    return const AuthSession(
      user: UserEntity(
        id: 'user-1',
        name: 'Jane Doe',
        email: 'jane@example.com',
      ),
      role: UserRole.publisher,
    );
  }
}

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository(this._accounts);

  final List<AccountEntity> _accounts;

  @override
  Future<AppResult<List<AccountEntity>>> getAccounts({
    required String userId,
  }) async {
    return Success<List<AccountEntity>>(_accounts);
  }

  @override
  Future<AppResult<AccountEntity>> connectAccount(
    AccountEntity account, {
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<void>> disconnectAccount(
    AccountEntity account, {
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> refreshToken(
    AccountEntity account, {
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountHealthCheckEntity>> testConnection(
    AccountEntity account, {
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> connectTelegramBot({
    required String userId,
    required String botToken,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<SocialPageEntity>>> getPages(
    AccountEntity account, {
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<SocialPageEntity>>> syncPages(
    AccountEntity account, {
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<SocialPageEntity>> addPage(
    AccountEntity account, {
    required String userId,
    required String identifier,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<SocialPageEntity>>> selectPages(
    AccountEntity account, {
    required String userId,
    required List<String> pageIds,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<void>> deletePage(
    AccountEntity account, {
    required String userId,
    required String pageId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<String>> beginFacebookOAuth({
    required String userId,
    required String redirectUri,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> completeFacebookOAuth({
    required String userId,
    required String code,
    required String state,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> connectFacebookNative({
    required String userId,
    required String accessToken,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<String>> beginWhatsAppOAuth({
    required String userId,
    required String redirectUri,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> completeWhatsAppOAuth({
    required String userId,
    required String code,
    required String state,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> setWhatsAppBusinessId({
    required String userId,
    required String socialAccountId,
    required String businessId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<String>> beginXOAuth({
    required String userId,
    required String redirectUri,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<AccountEntity>> completeXOAuth({
    required String userId,
    required String code,
    required String state,
  }) => throw UnimplementedError();
}

class _FailingAccountRepository extends _FakeAccountRepository {
  _FailingAccountRepository() : super(const <AccountEntity>[]);

  @override
  Future<AppResult<List<AccountEntity>>> getAccounts({
    required String userId,
  }) async {
    return const Failure<List<AccountEntity>>('Network unreachable');
  }
}

const _telegramPage = SocialPageEntity(
  id: 'page-tg-1',
  socialAccountId: 'acc-telegram',
  pageId: '-1001',
  kind: 'channel',
  name: 'News Channel',
  canPublish: true,
  status: SocialPageStatus.valid,
);

const _facebookPage = SocialPageEntity(
  id: 'page-fb-1',
  socialAccountId: 'acc-facebook',
  pageId: 'fb-page-1',
  kind: 'page',
  name: 'Business Page',
  canPublish: true,
  status: SocialPageStatus.valid,
);

const _instagramPageUnderFacebook = SocialPageEntity(
  id: 'page-instagram-1',
  socialAccountId: 'acc-facebook',
  pageId: 'instagram-business-1',
  kind: 'instagram_business',
  name: 'Instagram Business',
  canPublish: true,
  status: SocialPageStatus.valid,
);

const _whatsAppPageUnderFacebook = SocialPageEntity(
  id: 'page-whatsapp-1',
  socialAccountId: 'acc-facebook',
  pageId: 'whatsapp-number-1',
  kind: 'whatsapp_number',
  name: 'WhatsApp Number',
  canPublish: true,
  status: SocialPageStatus.valid,
);

const _connectedAccounts = <AccountEntity>[
  AccountEntity(
    id: 'acc-telegram',
    name: 'News Channel',
    platform: 'telegram',
    remoteId: 'acc-telegram',
    status: AccountStatus.connected,
    discoveryMode: 'manual',
    pages: <SocialPageEntity>[_telegramPage],
  ),
  AccountEntity(
    id: 'acc-facebook',
    name: 'Business Page',
    platform: 'facebook',
    remoteId: 'acc-facebook',
    status: AccountStatus.connected,
    discoveryMode: 'auto',
    pages: <SocialPageEntity>[_facebookPage],
  ),
];

const _facebookAccountWithEmbeddedNonBetaTargets = AccountEntity(
  id: 'acc-facebook',
  name: 'Business Page',
  platform: 'facebook',
  remoteId: 'acc-facebook',
  status: AccountStatus.connected,
  discoveryMode: 'auto',
  pages: <SocialPageEntity>[
    _facebookPage,
    _instagramPageUnderFacebook,
    _whatsAppPageUnderFacebook,
  ],
);

final _ownerAccess = OrganizationAccessState.active(
  memberships: <OrganizationEntity>[
    OrganizationEntity(
      id: 1,
      name: 'Owner Organization',
      slug: 'owner-organization',
      role: 'owner',
      isCurrent: true,
      permissions: permissionsForRole('owner'),
    ),
  ],
  currentOrganization: OrganizationEntity(
    id: 1,
    name: 'Owner Organization',
    slug: 'owner-organization',
    role: 'owner',
    isCurrent: true,
    permissions: permissionsForRole('owner'),
  ),
);

final _editorAccess = OrganizationAccessState.active(
  memberships: <OrganizationEntity>[
    OrganizationEntity(
      id: 1,
      name: 'Editorial Organization',
      slug: 'editorial-organization',
      role: 'editor',
      isCurrent: true,
      permissions: permissionsForRole('editor'),
    ),
  ],
  currentOrganization: OrganizationEntity(
    id: 1,
    name: 'Editorial Organization',
    slug: 'editorial-organization',
    role: 'editor',
    isCurrent: true,
    permissions: permissionsForRole('editor'),
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  OrganizationAccessState? organizationAccess,
  List<AccountEntity> accounts = _connectedAccounts,
  AccountRepository? accountRepositoryOverride,
  PostEntity? initialDraft,
  bool selectDefaultTargets = true,
}) async {
  // The composer is a long scrollable form — Sliver-based ListView only
  // mounts elements within the viewport + cache extent, so at the default
  // test surface size the lower cards (Pages & Channels onward) never
  // build at all. Use a tall viewport instead of scrolling to each one.
  tester.view.physicalSize = const Size(1200, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionControllerProvider.overrideWithValue(
          _FakeAuthSessionController(),
        ),
        accountRepositoryProvider.overrideWithValue(
          accountRepositoryOverride ?? _FakeAccountRepository(accounts),
        ),
        postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
        currentOrganizationAccessProvider.overrideWith(
          (_) async => organizationAccess ?? _ownerAccess,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: CreatePostScreen(initialDraft: initialDraft),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (!selectDefaultTargets) {
    return;
  }

  // Select both standard beta targets when the fixture provides them, so
  // preview-focused tests retain their two-provider coverage.
  for (final pageName in <String>['News Channel', 'Business Page']) {
    final page = find.text(pageName);
    if (page.evaluate().isNotEmpty) {
      await tester.tap(page);
    }
  }
  await tester.pumpAndSettle();
}

/// Scopes a finder to the "Per-Platform Preview" card only, since the
/// shared/override TextFields elsewhere on the same screen can legitimately
/// echo the exact same literal text and would otherwise create ambiguous
/// matches.
Finder _withinPreviewSection(Finder matching) {
  final previewCard = find.ancestor(
    of: find.text('Per-Platform Preview'),
    matching: find.byType(Card),
  );
  return find.descendant(of: previewCard, matching: matching);
}

quill.QuillController _richContentController(WidgetTester tester) {
  return tester
      .widget<quill.QuillEditor>(
        find.byKey(const ValueKey<String>('composer-rich-editor')),
      )
      .controller;
}

void main() {
  testWidgets(
    'WYSIWYG bold renders for Telegram and never exposes Markdown in Facebook preview',
    (tester) async {
      await _pump(tester);

      final controller = _richContentController(tester);
      controller.formatSelection(quill.Attribute.bold);
      controller.replaceText(
        0,
        0,
        'big',
        const TextSelection.collapsed(offset: 3),
      );
      await tester.pumpAndSettle();

      // Facebook's preview card is keyed deterministically and renders a
      // genuinely plain `Text` (markers stripped, no asterisks survive).
      final facebookText = tester.widget<Text>(
        find.byKey(const ValueKey<String>('platform-preview-text-facebook')),
      );
      expect(facebookText.data, 'big');

      // Telegram's preview card is the Text.rich twin, keyed separately —
      // no structural guessing needed to find the right RichText.
      final telegramTextRich = tester.widget<Text>(
        find.byKey(const ValueKey<String>('platform-preview-text-telegram')),
      );
      final spans = (telegramTextRich.textSpan! as TextSpan).children!;
      final boldSpan =
          spans.firstWhere((span) => (span as TextSpan).text == 'big')
              as TextSpan;
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
    },
  );

  testWidgets(
    'a per-platform override replaces the shared body just for that platform',
    (tester) async {
      await _pump(tester);

      _richContentController(tester).replaceText(
        0,
        0,
        'Shared body text.',
        const TextSelection.collapsed(offset: 17),
      );
      await tester.enterText(
        find
            .widgetWithText(TextField, 'Leave blank to use the shared content')
            .first,
        'Telegram-only caption.',
      );
      await tester.pumpAndSettle();

      expect(
        _withinPreviewSection(find.text('Telegram-only caption.')),
        findsOneWidget,
      );
      expect(
        _withinPreviewSection(find.text('Shared body text.')),
        findsOneWidget,
      );
    },
  );

  testWidgets('rich editor never writes Markdown markers for bold text', (
    tester,
  ) async {
    await _pump(tester);

    final controller = _richContentController(tester);
    controller.replaceText(
      0,
      0,
      'hello',
      const TextSelection.collapsed(offset: 5),
    );
    await tester.pumpAndSettle();

    controller.formatSelection(quill.Attribute.bold);
    await tester.pumpAndSettle();

    controller.replaceText(
      5,
      0,
      ' world',
      const TextSelection.collapsed(offset: 11),
    );
    await tester.pumpAndSettle();

    expect(find.text('**hello world**'), findsNothing);
  });

  testWidgets(
    'editor sees approval submission actions instead of direct publish actions',
    (tester) async {
      await _pump(tester, organizationAccess: _editorAccess);

      expect(
        find.text(
          'Your schedule and publish requests will be sent for approval before they are executed.',
        ),
        findsOneWidget,
      );
      expect(find.text('Submit schedule for approval'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Submit publish request for approval').last,
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      expect(find.text('Publish'), findsNothing);
    },
  );

  testWidgets(
    'Facebook Pages, Telegram Channels, and Instagram Business accounts are selectable beta targets — WhatsApp is not',
    (tester) async {
      await _pump(
        tester,
        accounts: const <AccountEntity>[
          _facebookAccountWithEmbeddedNonBetaTargets,
        ],
        selectDefaultTargets: false,
      );

      final facebookTarget = find.byKey(
        const ValueKey<String>('publish-target-page-fb-1'),
      );
      final instagramTarget = find.byKey(
        const ValueKey<String>('publish-target-page-instagram-1'),
      );
      final whatsAppTarget = find.byKey(
        const ValueKey<String>('publish-target-page-whatsapp-1'),
      );

      expect(tester.widget<FilterChip>(facebookTarget).onSelected, isNotNull);
      // 2026-08: Instagram graduated into the closed beta —
      // InstagramProvider makes real Content Publishing API calls now
      // (see platform_label.dart's isBetaLaunchPublishingTarget).
      expect(tester.widget<FilterChip>(instagramTarget).onSelected, isNotNull);
      expect(tester.widget<FilterChip>(whatsAppTarget).onSelected, isNull);
      expect(
        find.text('Instagram Business — Instagram — Coming soon'),
        findsNothing,
      );
      expect(
        find.text('WhatsApp Number — WhatsApp — Coming soon'),
        findsOneWidget,
      );

      await tester.tap(facebookTarget);
      await tester.tap(instagramTarget);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(facebookTarget).selected, isTrue);
      expect(tester.widget<FilterChip>(instagramTarget).selected, isTrue);

      await tester.tap(whatsAppTarget);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(whatsAppTarget).selected, isFalse);
    },
  );

  testWidgets('a stale WhatsApp draft target fails closed before publish', (
    tester,
  ) async {
    const staleDraft = PostEntity(
      id: 'draft-with-stale-whatsapp-target',
      title: 'Safe beta draft',
      body: 'This must not target WhatsApp.',
      targetPageIds: <String>['page-whatsapp-1'],
      platforms: <String>['whatsapp'],
      platformContent: <String, String>{
        'whatsapp': 'Do not send this caption.',
      },
    );

    await _pump(
      tester,
      accounts: const <AccountEntity>[
        _facebookAccountWithEmbeddedNonBetaTargets,
      ],
      initialDraft: staleDraft,
      selectDefaultTargets: false,
    );

    expect(
      tester
          .widget<FilterChip>(
            find.byKey(
              const ValueKey<String>('publish-target-page-whatsapp-1'),
            ),
          )
          .selected,
      isFalse,
    );
    expect(
      find.byKey(const ValueKey<String>('platform-preview-text-whatsapp')),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Publish'));
    await tester.pumpAndSettle();

    expect(
      find.text('Select at least one page or channel for publishing.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows an error and retry instead of rendering a failed accounts fetch as no usable pages',
    (tester) async {
      await _pump(
        tester,
        accountRepositoryOverride: _FailingAccountRepository(),
        selectDefaultTargets: false,
      );

      expect(find.text('Failed to load connected accounts.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
      expect(
        find.text(
          'No usable pages or channels yet. Connect an account and add/select its pages from Dashboard > Accounts.',
        ),
        findsNothing,
      );
    },
  );
}
