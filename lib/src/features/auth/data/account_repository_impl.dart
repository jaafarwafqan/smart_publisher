import '../../../backend_contracts/v1/accounts_contract_v1.dart';
import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../backend_contracts/v1/social_pages_contract_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../../../platforms/core/platform_factory.dart';
import '../../../platforms/core/social_platform.dart';
import '../domain/entities/account_entity.dart';
import '../domain/entities/account_health_check_entity.dart';
import '../domain/entities/social_page_entity.dart';
import '../domain/repositories/account_repository.dart';

class AccountRepositoryImpl extends AccountRepository {
  AccountRepositoryImpl({this.networkClient, required this.platformFactory})
    : _localAccounts = _defaultAccounts(platformFactory);

  final NetworkClient? networkClient;
  final PlatformFactory platformFactory;
  final Map<String, AccountEntity> _localAccounts;

  @override
  Future<AppResult<List<AccountEntity>>> getAccounts({
    required String userId,
  }) async {
    if (networkClient == null) {
      return Success<List<AccountEntity>>(
        _sortedAccounts(),
        message: 'Accounts loaded locally',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.socialAccountsList(userId),
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        final remoteAccounts = rawItems
            .whereType<Map<String, dynamic>>()
            .map((json) => _toEntity(SocialAccountResponseDtoV1.fromJson(json)))
            .toList(growable: false);

        final withPages = await Future.wait(
          remoteAccounts.map((account) async {
            if (account.remoteId == null) {
              return account;
            }
            final pages = await _fetchPages(userId, account.remoteId!);
            return account.copyWith(pages: pages);
          }),
        );

        _mergeRemoteAccounts(withPages);
        return _sortedAccounts();
      },
      operation: 'accounts.list.remote',
      fallbackMessage: 'Failed to load accounts',
    );
  }

  Future<List<SocialPageEntity>> _fetchPages(
    String userId,
    String socialAccountId,
  ) async {
    try {
      final response = await networkClient!.get(
        LaravelEndpoints.socialPages(userId, socialAccountId),
      );
      final payload = _unwrapPayload(response.data);
      final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => BackendContractMapperV1.toSocialPageEntity(
              SocialPageResponseDtoV1.fromJson(json),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <SocialPageEntity>[];
    }
  }

  @override
  Future<AppResult<AccountEntity>> connectAccount(
    AccountEntity account, {
    required String userId,
  }) async {
    return execute(
      () async {
        final platform = platformFactory.createById(
          _platformIdFor(account.platform),
        );
        final auth = await platform.connect();
        if (!auth.success) {
          throw StateError(auth.message);
        }

        final permissions = auth.permissions.isNotEmpty
            ? auth.permissions
            : _permissionsFor(platform);

        if (networkClient != null &&
            auth.token != null &&
            auth.token!.isNotEmpty) {
          final response = await networkClient!.post(
            LaravelEndpoints.socialAccountsStore(userId),
            data: ConnectSocialAccountRequestDtoV1(
              provider: _backendProviderFor(account.platform),
              // The native SDK layer used here doesn't return a stable
              // provider-side account id, so the token itself (unique per
              // connection) stands in as the provider_account_id.
              providerAccountId: auth.token!,
              accountName: account.name,
              accessToken: auth.token,
              refreshToken: auth.refreshToken,
              tokenExpiresAt: auth.expiresAt,
              scopes: permissions,
            ).toJson(),
          );
          final payload = _unwrapPayload(response.data);
          if (payload is Map<String, dynamic>) {
            final linked = _toEntity(
              SocialAccountResponseDtoV1.fromJson(payload),
            );
            final updated = linked.copyWith(id: account.id);
            _localAccounts[account.id] = updated;
            return updated;
          }
        }

        final updated = account.copyWith(
          status: AccountStatus.connected,
          permissions: permissions,
        );
        _localAccounts[updated.id] = updated;
        return updated;
      },
      operation: 'accounts.connect',
      fallbackMessage: 'Failed to connect account',
    );
  }

  @override
  Future<AppResult<void>> disconnectAccount(
    AccountEntity account, {
    required String userId,
  }) async {
    return execute(
      () async {
        final local = _localAccounts[account.id];
        if (local == null) {
          throw StateError('Account not found');
        }
        final platform = platformFactory.createById(
          _platformIdFor(local.platform),
        );
        await platform.disconnect();

        _localAccounts[account.id] = local.copyWith(
          status: AccountStatus.disconnected,
        );

        if (networkClient != null && local.remoteId != null) {
          await networkClient!.delete(
            LaravelEndpoints.socialAccountById(userId, local.remoteId!),
          );
        }
      },
      operation: 'accounts.disconnect',
      fallbackMessage: 'Failed to disconnect account',
    );
  }

  @override
  Future<AppResult<AccountEntity>> refreshToken(
    AccountEntity account, {
    required String userId,
  }) async {
    final local = _localAccounts[account.id] ?? account;

    if (local.remoteId == null || local.remoteId!.isEmpty) {
      return Failure<AccountEntity>(
        '${local.name} has not been synced with the server yet.',
      );
    }
    if (!local.hasRefreshToken) {
      return Failure<AccountEntity>(
        'Refresh token is not available for ${local.name}.',
      );
    }
    if (networkClient == null) {
      return Failure<AccountEntity>('Refresh token requires a connection.');
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialAccountRefreshToken(userId, local.remoteId!),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is Map<String, dynamic>) {
          final updated = _toEntity(
            SocialAccountResponseDtoV1.fromJson(payload),
          ).copyWith(id: local.id);
          _localAccounts[local.id] = updated;
          return updated;
        }
        return local.copyWith(status: AccountStatus.pending);
      },
      operation: 'accounts.refresh_token',
      fallbackMessage: 'Failed to refresh account token',
    );
  }

  @override
  Future<AppResult<AccountHealthCheckEntity>> testConnection(
    AccountEntity account, {
    required String userId,
  }) async {
    final local = _localAccounts[account.id] ?? account;

    if (local.remoteId == null || local.remoteId!.isEmpty) {
      return Failure<AccountHealthCheckEntity>(
        '${local.name} has not been synced with the server yet.',
      );
    }
    if (networkClient == null) {
      return Failure<AccountHealthCheckEntity>(
        'Testing the connection requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialAccountTestConnection(userId, local.remoteId!),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid test connection response.');
        }
        return AccountHealthCheckEntity(
          available: (payload['available'] ?? false) as bool,
          healthy: (payload['healthy'] ?? false) as bool,
          message: (payload['message'] ?? '').toString(),
        );
      },
      operation: 'accounts.test_connection',
      fallbackMessage: 'Failed to test the connection',
    );
  }

  void _mergeRemoteAccounts(List<AccountEntity> remoteAccounts) {
    for (final remote in remoteAccounts) {
      final existing = _localAccounts.values
          .where((a) => a.platform == remote.platform)
          .firstOrNull;
      final accountId = existing?.id ?? remote.id;
      _localAccounts[accountId] = remote.copyWith(
        id: accountId,
        remoteId: remote.remoteId,
        discoveryMode: remote.discoveryMode,
        pages: remote.pages,
        permissions: remote.permissions.isNotEmpty
            ? remote.permissions
            : existing?.permissions ?? const <String>[],
      );
    }
  }

  @override
  Future<AppResult<AccountEntity>> connectTelegramBot({
    required String userId,
    required String botToken,
  }) async {
    if (networkClient == null) {
      return Failure<AccountEntity>(
        'Connecting Telegram requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.telegramConnect(userId),
          data: ConnectTelegramBotRequestDtoV1(botToken: botToken).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid Telegram connect response.');
        }
        final linked = _toEntity(SocialAccountResponseDtoV1.fromJson(payload));
        final existing = _localAccounts.values
            .where((a) => a.platform == linked.platform)
            .firstOrNull;
        final accountId = existing?.id ?? linked.id;
        final updated = linked.copyWith(id: accountId);
        _localAccounts[accountId] = updated;
        return updated;
      },
      operation: 'accounts.telegram.connect',
      fallbackMessage: 'Failed to connect Telegram bot',
    );
  }

  static const List<String> _facebookOAuthScopes = <String>[
    'pages_show_list',
    'pages_read_engagement',
    'pages_manage_posts',
  ];

  @override
  Future<AppResult<String>> beginFacebookOAuth({
    required String userId,
    required String redirectUri,
  }) async {
    if (networkClient == null) {
      return Failure<String>('Connecting Facebook requires a connection.');
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialAccountsAuthorize(userId),
          data: BeginOAuthAuthorizationRequestDtoV1(
            provider: 'facebook',
            redirectUri: redirectUri,
            scopes: _facebookOAuthScopes,
          ).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid OAuth authorize response.');
        }
        final dto = BeginOAuthAuthorizationResponseDtoV1.fromJson(payload);
        if (dto.authorizeUrl.isEmpty) {
          throw StateError('Facebook did not return an authorize URL.');
        }
        return dto.authorizeUrl;
      },
      operation: 'accounts.facebook.oauth.begin',
      fallbackMessage: 'Failed to start Facebook connection',
    );
  }

  @override
  Future<AppResult<AccountEntity>> completeFacebookOAuth({
    required String userId,
    required String code,
    required String state,
  }) async {
    if (networkClient == null) {
      return Failure<AccountEntity>(
        'Connecting Facebook requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialAccountsCallback(userId),
          data: OAuthCallbackRequestDtoV1(
            provider: 'facebook',
            code: code,
            state: state,
            scopes: _facebookOAuthScopes,
          ).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid Facebook OAuth callback response.');
        }
        final linked = _toEntity(SocialAccountResponseDtoV1.fromJson(payload));
        final existing = _localAccounts.values
            .where((a) => a.platform == linked.platform)
            .firstOrNull;
        final accountId = existing?.id ?? linked.id;
        final updated = linked.copyWith(id: accountId);
        _localAccounts[accountId] = updated;
        return updated;
      },
      operation: 'accounts.facebook.oauth.complete',
      fallbackMessage: 'Failed to complete Facebook connection',
    );
  }

  static const List<String> _whatsappOAuthScopes = <String>[
    'whatsapp_business_messaging',
    'whatsapp_business_management',
  ];

  @override
  Future<AppResult<String>> beginWhatsAppOAuth({
    required String userId,
    required String redirectUri,
  }) async {
    if (networkClient == null) {
      return Failure<String>('Connecting WhatsApp requires a connection.');
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialAccountsAuthorize(userId),
          data: BeginOAuthAuthorizationRequestDtoV1(
            provider: 'whatsapp',
            redirectUri: redirectUri,
            scopes: _whatsappOAuthScopes,
          ).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid OAuth authorize response.');
        }
        final dto = BeginOAuthAuthorizationResponseDtoV1.fromJson(payload);
        if (dto.authorizeUrl.isEmpty) {
          throw StateError('WhatsApp did not return an authorize URL.');
        }
        return dto.authorizeUrl;
      },
      operation: 'accounts.whatsapp.oauth.begin',
      fallbackMessage: 'Failed to start WhatsApp connection',
    );
  }

  @override
  Future<AppResult<AccountEntity>> completeWhatsAppOAuth({
    required String userId,
    required String code,
    required String state,
  }) async {
    if (networkClient == null) {
      return Failure<AccountEntity>(
        'Connecting WhatsApp requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialAccountsCallback(userId),
          data: OAuthCallbackRequestDtoV1(
            provider: 'whatsapp',
            code: code,
            state: state,
            scopes: _whatsappOAuthScopes,
          ).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid WhatsApp OAuth callback response.');
        }
        final linked = _toEntity(SocialAccountResponseDtoV1.fromJson(payload));
        final existing = _localAccounts.values
            .where((a) => a.platform == linked.platform)
            .firstOrNull;
        final accountId = existing?.id ?? linked.id;
        final updated = linked.copyWith(id: accountId);
        _localAccounts[accountId] = updated;
        return updated;
      },
      operation: 'accounts.whatsapp.oauth.complete',
      fallbackMessage: 'Failed to complete WhatsApp connection',
    );
  }

  @override
  Future<AppResult<AccountEntity>> setWhatsAppBusinessId({
    required String userId,
    required String socialAccountId,
    required String businessId,
  }) async {
    if (networkClient == null) {
      return Failure<AccountEntity>(
        'Saving the Business ID requires a connection.',
      );
    }

    return execute(
      () async {
        final existing = _localAccounts.values
            .where((a) => a.remoteId == socialAccountId)
            .firstOrNull;
        final mergedMetadata = <String, dynamic>{
          ...existing?.metadata ?? const <String, dynamic>{},
          'business_id': businessId,
        };

        final response = await networkClient!.put(
          LaravelEndpoints.socialAccountById(userId, socialAccountId),
          data: <String, dynamic>{'metadata': mergedMetadata},
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid social account update response.');
        }
        final updated = _toEntity(SocialAccountResponseDtoV1.fromJson(payload));
        final accountId = existing?.id ?? updated.id;
        final merged = updated.copyWith(id: accountId);
        _localAccounts[accountId] = merged;
        return merged;
      },
      operation: 'accounts.whatsapp.business_id.set',
      fallbackMessage: 'Failed to save the WhatsApp Business ID',
    );
  }

  @override
  Future<AppResult<List<SocialPageEntity>>> getPages(
    AccountEntity account, {
    required String userId,
  }) async {
    final local = _localAccounts[account.id] ?? account;
    if (local.remoteId == null) {
      return Success<List<SocialPageEntity>>(
        const <SocialPageEntity>[],
        message: 'Account has not been synced with the server yet.',
      );
    }
    if (networkClient == null) {
      return Failure<List<SocialPageEntity>>(
        'Listing pages requires a connection.',
      );
    }

    return executeList(
      () => _fetchPages(userId, local.remoteId!),
      operation: 'accounts.pages.list',
      fallbackMessage: 'Failed to load pages',
    );
  }

  @override
  Future<AppResult<List<SocialPageEntity>>> syncPages(
    AccountEntity account, {
    required String userId,
  }) async {
    final local = _localAccounts[account.id] ?? account;
    if (local.remoteId == null) {
      return Failure<List<SocialPageEntity>>(
        '${local.name} has not been synced with the server yet.',
      );
    }
    if (networkClient == null) {
      return Failure<List<SocialPageEntity>>(
        'Syncing pages requires a connection.',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialPagesSync(userId, local.remoteId!),
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        final pages = rawItems
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => BackendContractMapperV1.toSocialPageEntity(
                SocialPageResponseDtoV1.fromJson(json),
              ),
            )
            .toList(growable: false);
        _localAccounts[local.id] = local.copyWith(pages: pages);
        return pages;
      },
      operation: 'accounts.pages.sync',
      fallbackMessage: 'Failed to sync pages',
    );
  }

  @override
  Future<AppResult<SocialPageEntity>> addPage(
    AccountEntity account, {
    required String userId,
    required String identifier,
  }) async {
    final local = _localAccounts[account.id] ?? account;
    if (local.remoteId == null) {
      return Failure<SocialPageEntity>(
        '${local.name} has not been synced with the server yet.',
      );
    }
    if (networkClient == null) {
      return Failure<SocialPageEntity>(
        'Adding a channel requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialPagesAdd(userId, local.remoteId!),
          data: AddPageRequestDtoV1(identifier: identifier).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid add-page response.');
        }
        final page = BackendContractMapperV1.toSocialPageEntity(
          SocialPageResponseDtoV1.fromJson(payload),
        );
        _localAccounts[local.id] = local.copyWith(
          pages: <SocialPageEntity>[
            ...local.pages.where((p) => p.id != page.id),
            page,
          ],
        );
        return page;
      },
      operation: 'accounts.pages.add',
      fallbackMessage: 'Failed to add channel',
    );
  }

  @override
  Future<AppResult<List<SocialPageEntity>>> selectPages(
    AccountEntity account, {
    required String userId,
    required List<String> pageIds,
  }) async {
    final local = _localAccounts[account.id] ?? account;
    if (local.remoteId == null) {
      return Failure<List<SocialPageEntity>>(
        '${local.name} has not been synced with the server yet.',
      );
    }
    if (networkClient == null) {
      return Failure<List<SocialPageEntity>>(
        'Selecting pages requires a connection.',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.socialPagesSelect(userId, local.remoteId!),
          data: SelectPagesRequestDtoV1(pageIds: pageIds).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        final pages = rawItems
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => BackendContractMapperV1.toSocialPageEntity(
                SocialPageResponseDtoV1.fromJson(json),
              ),
            )
            .toList(growable: false);
        _localAccounts[local.id] = local.copyWith(pages: pages);
        return pages;
      },
      operation: 'accounts.pages.select',
      fallbackMessage: 'Failed to update selected pages',
    );
  }

  @override
  Future<AppResult<void>> deletePage(
    AccountEntity account, {
    required String userId,
    required String pageId,
  }) async {
    final local = _localAccounts[account.id] ?? account;
    if (local.remoteId == null) {
      return Failure<void>(
        '${local.name} has not been synced with the server yet.',
      );
    }
    if (networkClient == null) {
      return Failure<void>('Removing a page requires a connection.');
    }

    return execute<void>(
      () async {
        await networkClient!.delete(
          LaravelEndpoints.socialPageById(userId, local.remoteId!, pageId),
        );
        _localAccounts[local.id] = local.copyWith(
          pages: local.pages
              .where((page) => page.id != pageId)
              .toList(growable: false),
        );
      },
      operation: 'accounts.pages.delete',
      fallbackMessage: 'Failed to remove page',
    );
  }

  List<AccountEntity> _sortedAccounts() {
    final items = _localAccounts.values.toList(growable: false);
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }

  static Map<String, AccountEntity> _defaultAccounts(PlatformFactory factory) {
    const platformOrder = <String>[
      'facebook',
      'instagram',
      'telegram',
      'whatsapp',
      'linkedin',
      'twitter',
    ];

    return <String, AccountEntity>{
      for (final platformId in platformOrder)
        platformId: _accountForPlatform(factory.createById(platformId)),
    };
  }

  static AccountEntity _accountForPlatform(SocialPlatform platform) {
    final name = _displayName(platform.platformId);
    return AccountEntity(
      id: platform.platformId,
      name: name,
      platform: platform.platformId,
      avatarUrl: null,
      status: AccountStatus.disconnected,
      permissions: _permissionsFor(platform),
    );
  }

  static List<String> _permissionsFor(SocialPlatform platform) {
    final capability = platform.capability();
    final permissions = <String>['publish'];
    if (capability.supportsScheduling) {
      permissions.add('schedule');
    }
    if (capability.supportsHashtags) {
      permissions.add('hashtags');
    }
    if (capability.supportsMentions) {
      permissions.add('mentions');
    }
    if (capability.supportsDocuments) {
      permissions.add('documents');
    }
    if (capability.supportsPolls) {
      permissions.add('polls');
    }
    return permissions;
  }

  static String _displayName(String platformId) {
    switch (platformId) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'telegram':
        return 'Telegram';
      case 'whatsapp':
        return 'WhatsApp';
      case 'linkedin':
        return 'LinkedIn';
      case 'twitter':
        return 'X';
      default:
        return platformId;
    }
  }

  static String _platformIdFor(String platform) {
    if (platform == 'x') {
      return 'twitter';
    }
    return platform;
  }

  /// Maps this app's internal platform key to the exact `provider` string
  /// the backend's `SocialAccountController::PROVIDERS` whitelist accepts.
  /// Everything matches 1:1 except X/Twitter: the internal key is
  /// `'twitter'` (see [XPlatform.platformId]) but the backend only
  /// recognizes `'x'`.
  static String _backendProviderFor(String platform) {
    if (platform == 'twitter') {
      return 'x';
    }
    return platform;
  }

  /// Inverse of [_backendProviderFor] — used when mapping a fetched
  /// `SocialAccountResponseDtoV1` back to an [AccountEntity], so a
  /// server-known "x" account matches this app's locally-seeded "twitter"
  /// placeholder in [_mergeRemoteAccounts] instead of creating a duplicate.
  static String _platformFromBackendProvider(String provider) {
    if (provider == 'x') {
      return 'twitter';
    }
    return provider;
  }

  AccountEntity _toEntity(SocialAccountResponseDtoV1 dto) {
    final entity = BackendContractMapperV1.toAccountEntity(dto);
    return entity.copyWith(
      platform: _platformFromBackendProvider(entity.platform),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
