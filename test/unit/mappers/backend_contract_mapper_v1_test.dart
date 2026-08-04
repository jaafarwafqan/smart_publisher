import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/backend_contracts/v1/accounts_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/analytics_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/backend_contract_mapper_v1.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

void main() {
  group('BackendContractMapperV1', () {
    test('maps post entity to request dto', () {
      const post = PostEntity(id: 'p1', title: 'Title', body: 'Body');

      final dto = BackendContractMapperV1.toPostRequest(post);

      expect(dto.title, 'Title');
      expect(dto.content, 'Body');
    });

    test('extracts file name from media url', () {
      const media = MediaEntity(
        id: 'm1',
        postId: 'p1',
        url: 'https://cdn.example.com/folder/photo.png',
        mimeType: 'image/png',
        sizeInBytes: 123,
      );

      final dto = BackendContractMapperV1.toMediaUploadRequest(media);

      expect(dto.fileName, 'photo.png');
      expect(dto.postId, 'p1');
    });

    test('maps analytics dto to map', () {
      const dto = PostAnalyticsResponseDtoV1(
        postId: 'p1',
        impressions: 100,
        clicks: 10,
        shares: 3,
        reactions: 7,
        comments: 2,
        reach: 80,
        available: true,
        status: 'published',
      );

      final map = BackendContractMapperV1.toAnalyticsMap(dto);

      expect(map['post_id'], 'p1');
      expect(map['impressions'], 100);
      expect(map['status'], 'published');
    });

    test(
      'maps token expiry, last synced, and last published through to the entity',
      () {
        final tokenExpiresAt = DateTime.utc(2026, 8, 1);
        final lastSyncedAt = DateTime.utc(2026, 7, 26, 10);
        final lastPublishedAt = DateTime.utc(2026, 7, 25, 9);

        final dto = SocialAccountResponseDtoV1(
          id: '1',
          provider: 'facebook',
          providerAccountId: 'fb-1',
          status: 'connected',
          tokenExpiresAt: tokenExpiresAt,
          lastSyncedAt: lastSyncedAt,
          lastPublishedAt: lastPublishedAt,
        );

        final entity = BackendContractMapperV1.toAccountEntity(dto);

        expect(entity.tokenExpiresAt, tokenExpiresAt);
        expect(entity.lastSyncedAt, lastSyncedAt);
        expect(entity.lastPublishedAt, lastPublishedAt);
      },
    );
  });
}
