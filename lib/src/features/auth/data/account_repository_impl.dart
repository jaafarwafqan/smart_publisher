import '../../../backend_contracts/v1/accounts_contract_v1.dart';
import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../../../platforms/core/platform_factory.dart';
import '../../../platforms/core/social_platform.dart';
import '../domain/entities/account_entity.dart';
import '../domain/repositories/account_repository.dart';

class AccountRepositoryImpl extends AccountRepository {
  AccountRepositoryImpl({this.networkClient, required this.platformFactory})
    : _localAccounts = _defaultAccounts(platformFactory);

  final NetworkClient? networkClient;
  final PlatformFactory platformFactory;
  final Map<String, AccountEntity> _localAccounts;

  @override
  Future<AppResult<List<AccountEntity>>> getAccounts() async {
    if (networkClient == null) {
      return Success<List<AccountEntity>>(
        _sortedAccounts(),
        message: 'Accounts loaded locally',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(LaravelEndpoints.accounts);
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        final remoteAccounts = rawItems
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => BackendContractMapperV1.toAccountEntity(
                AccountResponseDtoV1.fromJson(json),
              ),
            )
            .toList(growable: false);

        _mergeRemoteAccounts(remoteAccounts);
        return _sortedAccounts();
      },
      operation: 'accounts.list.remote',
      fallbackMessage: 'Failed to load accounts',
    );
  }

  @override
  Future<AppResult<AccountEntity>> connectAccount(AccountEntity account) async {
    return execute(
      () async {
        final platform = platformFactory.createById(
          _platformIdFor(account.platform),
        );
        final auth = await platform.connect();
        if (!auth.success) {
          throw StateError(auth.message);
        }

        final updated = account.copyWith(
          isConnected: true,
          status: 'Connected',
          permissions: auth.permissions.isNotEmpty
              ? auth.permissions
              : _permissionsFor(platform),
        );
        _localAccounts[updated.id] = updated;

        if (networkClient != null &&
            auth.token != null &&
            auth.token!.isNotEmpty) {
          await networkClient!.post(
            LaravelEndpoints.accountsConnect,
            data: ConnectAccountRequestDtoV1(
              platform: updated.platform,
              accessToken: auth.token!,
              refreshToken: auth.refreshToken,
              expiresAt: auth.expiresAt,
              permissions: updated.permissions,
            ).toJson(),
          );
        }

        return updated;
      },
      operation: 'accounts.connect',
      fallbackMessage: 'Failed to connect account',
    );
  }

  @override
  Future<AppResult<void>> disconnectAccount(String id) async {
    return execute(
      () async {
        final account = _localAccounts[id];
        if (account == null) {
          throw StateError('Account not found');
        }
        final platform = platformFactory.createById(
          _platformIdFor(account.platform),
        );
        await platform.disconnect();

        _localAccounts[id] = account.copyWith(
          isConnected: false,
          status: 'Disconnected',
        );

        if (networkClient != null) {
          await networkClient!.delete(LaravelEndpoints.accountById(id));
        }
      },
      operation: 'accounts.disconnect',
      fallbackMessage: 'Failed to disconnect account',
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
        permissions: remote.permissions.isNotEmpty
            ? remote.permissions
            : existing?.permissions ?? const <String>[],
        status: remote.isConnected ? 'Connected' : 'Disconnected',
      );
    }
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
      isConnected: false,
      status: 'Disconnected',
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
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
