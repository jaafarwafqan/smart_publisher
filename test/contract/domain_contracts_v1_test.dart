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
          'id': 'acc1',
          'name': 'Main FB',
          'platform': 'facebook',
          'is_connected': true,
        },
      });

      final dto = AccountResponseDtoV1.fromJson(
        envelope.data as Map<String, dynamic>,
      );
      final entity = BackendContractMapperV1.toAccountEntity(dto);

      expect(entity.id, 'acc1');
      expect(entity.platform, 'facebook');
      expect(entity.isConnected, isTrue);
    });
  });
}
