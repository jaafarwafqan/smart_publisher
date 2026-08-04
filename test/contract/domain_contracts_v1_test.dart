import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/backend_contracts/v1/accounts_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/analytics_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/api_envelope_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/auth_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/backend_contract_mapper_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/media_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/notifications_contract_v1.dart';

void main() {
  group('Contract - Auth v1', () {
    test('parses login envelope and maps user', () {
      final envelope = ApiEnvelopeV1.fromJson(<String, dynamic>{
        'success': true,
        'version': 'v1',
        'data': <String, dynamic>{
          'access_token': 'a1',
          'refresh_token': 'r1',
          'user': <String, dynamic>{
            'id': 'u1',
            'name': 'User One',
            'email': 'u1@example.com',
          },
        },
      });

      final dto = LoginResponseDtoV1.fromJson(
        envelope.data as Map<String, dynamic>,
      );
      final user = BackendContractMapperV1.toUserEntity(dto.user);

      expect(dto.accessToken, 'a1');
      expect(dto.refreshToken, 'r1');
      expect(user.email, 'u1@example.com');
    });
  });

  group('Contract - Media v1', () {
    test('parses media envelope and maps entity', () {
      final envelope = ApiEnvelopeV1.fromJson(<String, dynamic>{
        'success': true,
        'version': 'v1',
        'data': <String, dynamic>{
          'id': 'm1',
          'post_id': 'p1',
          'url': 'https://cdn.example.com/m1.jpg',
          'mime_type': 'image/jpeg',
          'size_in_bytes': 1000,
          'is_compressed': true,
        },
      });

      final dto = MediaResponseDtoV1.fromJson(
        envelope.data as Map<String, dynamic>,
      );
      final entity = BackendContractMapperV1.toMediaEntity(dto);

      expect(entity.id, 'm1');
      expect(entity.postId, 'p1');
      expect(entity.isCompressed, isTrue);
    });

    test(
      'parses the real MediaResource shape (integer ids, size not size_in_bytes, url present)',
      () {
        // Regression test: MediaResource actually sends `id`/`post_id` as
        // JSON integers (not strings) and `size` (not `size_in_bytes`) — a
        // naive `as String`/`as int` cast here previously threw a TypeError
        // on every real upload response, silently masked for a long time
        // because the endpoint that would have exercised it was itself
        // broken (pointed at a route that didn't exist).
        final dto = MediaResponseDtoV1.fromJson(<String, dynamic>{
          'id': 5,
          'post_id': 3,
          'user_id': 1,
          'type': 'document',
          'collection': 'default',
          'disk': 'public',
          'path': 'media/2026/07/report.xlsx',
          'url': 'http://127.0.0.1:8000/storage/media/2026/07/report.xlsx',
          'thumbnail_path': null,
          'mime_type':
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'size': 16384,
          'width': null,
          'height': null,
          'duration_seconds': null,
          'meta': <String, dynamic>{'original_name': 'report.xlsx'},
        });

        expect(dto.id, '5');
        expect(dto.postId, '3');
        expect(
          dto.url,
          'http://127.0.0.1:8000/storage/media/2026/07/report.xlsx',
        );
        expect(dto.sizeInBytes, 16384);
      },
    );
  });

  group('Contract - Analytics v1', () {
    test('parses analytics dto and mapper output', () {
      final dto = PostAnalyticsResponseDtoV1.fromJson(<String, dynamic>{
        'post_id': 'p1',
        'impressions': 250,
        'clicks': 12,
        'shares': 3,
        'reactions': 7,
        'status': 'published',
      });
      final mapped = BackendContractMapperV1.toAnalyticsMap(dto);

      expect(mapped['post_id'], 'p1');
      expect(mapped['impressions'], 250);
      expect(mapped['status'], 'published');
    });
  });

  group('Contract - Notifications v1', () {
    test('parses notification envelope and maps entity', () {
      final envelope = ApiEnvelopeV1.fromJson(<String, dynamic>{
        'success': true,
        'version': 'v1',
        'data': <String, dynamic>{
          'id': 'n1',
          'title': 'New publish result',
          'body': 'Post has been published',
          'is_read': false,
        },
      });

      final dto = NotificationResponseDtoV1.fromJson(
        envelope.data as Map<String, dynamic>,
      );
      final entity = BackendContractMapperV1.toNotificationEntity(dto);

      expect(entity.id, 'n1');
      expect(entity.isRead, isFalse);
    });
  });

  group('Contract - Accounts v1', () {
    test('parses account envelope and maps entity', () {
      final envelope = ApiEnvelopeV1.fromJson(<String, dynamic>{
        'success': true,
        'version': 'v1',
        'data': <String, dynamic>{
          'id': '42',
          'provider': 'facebook',
          'provider_account_id': 'fb-acc-1',
          'account_name': 'Main FB',
          'status': 'connected',
        },
      });

      final dto = SocialAccountResponseDtoV1.fromJson(
        envelope.data as Map<String, dynamic>,
      );
      final entity = BackendContractMapperV1.toAccountEntity(dto);

      expect(entity.id, '42');
      expect(entity.remoteId, '42');
      expect(entity.platform, 'facebook');
      expect(entity.isConnected, isTrue);
    });
  });
}
