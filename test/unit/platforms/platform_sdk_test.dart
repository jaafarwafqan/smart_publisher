import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/platforms/core/platform_error_mapping.dart';
import 'package:smart_publisher/src/platforms/core/platform_exception.dart';
import 'package:smart_publisher/src/platforms/core/platform_sdk.dart';
import 'package:smart_publisher/src/platforms/sdk/facebook_sdk/facebook_sdk.dart';
import 'package:smart_publisher/src/platforms/sdk/x_sdk/x_sdk.dart';

void main() {
  group('Platform SDK', () {
    test('FacebookSdk publish succeeds with valid input', () async {
      const sdk = FacebookSdk();
      const post = PostEntity(id: '1', title: 't', body: 'b');

      final result = await sdk.publish(post);

      expect(result.success, isTrue);
      expect(result.externalId, contains('facebook-'));
    });

    test('FacebookSdk mapError maps validation code', () {
      const sdk = FacebookSdk();
      const mapped = PlatformException('bad', code: 'FB001');

      final error = sdk.mapError(mapped);

      expect(error.type, PlatformErrorType.validation);
      expect(error.code, 'FB001');
    });

    test('XSdk upload and analytics paths work', () async {
      const sdk = XSdk();

      final mediaId = await sdk.uploadMedia(
        const UploadMediaRequest(
          postId: 'p1',
          mediaUrl: 'https://cdn/image.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      final analytics = await sdk.analytics('x-post-id');

      expect(mediaId, contains('x-media-'));
      expect(analytics.metrics.containsKey('likes'), isTrue);
    });
  });
}
