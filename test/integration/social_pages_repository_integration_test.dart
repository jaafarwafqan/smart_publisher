import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/account_entity.dart';
import 'package:smart_publisher/src/platforms/core/platform_factory.dart';

import '../helpers/fake_network_client.dart';

const _userId = 'user-1';

// A local id distinct from AccountRepositoryImpl's default-seeded platform
// keys (e.g. 'telegram'), so `_localAccounts[account.id]` genuinely misses
// and the repository falls back to this entity's own remoteId, exactly as
// it would for an account already merged in by a prior getAccounts() call.
AccountEntity _telegramAccount() {
  return const AccountEntity(
    id: 'telegram-connected',
    remoteId: '42',
    name: 'smart_publisher_bot',
    platform: 'telegram',
    status: AccountStatus.connected,
    discoveryMode: 'manual',
  );
}

void main() {
  group('Integration - Social Pages (AccountRepositoryImpl)', () {
    test(
      'connectTelegramBot posts the bot token and maps the response',
      () async {
        Map<String, dynamic>? sentPayload;
        String? sentPath;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 201,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '42',
                    'provider': 'telegram',
                    'provider_account_id': '555',
                    'account_name': 'smart_publisher_bot',
                    'account_username': '@smart_publisher_bot',
                    'status': 'connected',
                    'discovery_mode': 'manual',
                  },
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final result = await repository.connectTelegramBot(
          userId: _userId,
          botToken: '123:ABC',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/telegram/connect'));
        expect(sentPayload!['bot_token'], '123:ABC');
        expect(result.data!.platform, 'telegram');
        expect(result.data!.remoteId, '42');
        expect(result.data!.discoveryMode, 'manual');
      },
    );

    test(
      'getPages returns the mapped page list for a synced account',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <dynamic>[
                    <String, dynamic>{
                      'id': '9',
                      'social_account_id': '42',
                      'page_id': '-1001',
                      'kind': 'channel',
                      'name': 'Nursing Channel',
                      'username': '@nursing_kufa',
                      'can_publish': true,
                      'is_selected': false,
                      'status': 'valid',
                    },
                  ],
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final result = await repository.getPages(
          _telegramAccount(),
          userId: _userId,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.single.name, 'Nursing Channel');
        expect(result.data!.single.isUsable, isTrue);
      },
    );

    test(
      'addPage posts the identifier and returns the verified page',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 201,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '9',
                    'social_account_id': '42',
                    'page_id': '-1001',
                    'kind': 'channel',
                    'name': 'Nursing Channel',
                    'can_publish': true,
                    'is_selected': false,
                    'status': 'valid',
                  },
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final result = await repository.addPage(
          _telegramAccount(),
          userId: _userId,
          identifier: '@nursing_kufa',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/42/pages/add'));
        expect(sentPayload!['identifier'], '@nursing_kufa');
        expect(result.data!.pageId, '-1001');
      },
    );

    test(
      'selectPages posts the chosen ids and returns the updated pages',
      () async {
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <dynamic>[
                    <String, dynamic>{
                      'id': '9',
                      'social_account_id': '42',
                      'page_id': '-1001',
                      'name': 'Nursing Channel',
                      'is_selected': true,
                      'status': 'valid',
                    },
                  ],
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final result = await repository.selectPages(
          _telegramAccount(),
          userId: _userId,
          pageIds: <String>['9'],
        );

        expect(result.isSuccess, isTrue);
        expect(sentPayload!['page_ids'], <int>[9]);
        expect(result.data!.single.isSelected, isTrue);
      },
    );

    test(
      'syncPages fails fast for an account that has not been synced yet',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(),
          platformFactory: PlatformFactory(),
        );

        const unsynced = AccountEntity(
          id: 'telegram',
          name: 'Telegram',
          platform: 'telegram',
        );

        final result = await repository.syncPages(unsynced, userId: _userId);

        expect(result.isFailure, isTrue);
      },
    );
  });
}
