import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/utils/platform_label.dart';

void main() {
  group('isMockBackedPlatform', () {
    test('linkedin and twitter/x are still mock-backed', () {
      expect(isMockBackedPlatform('linkedin'), isTrue);
      expect(isMockBackedPlatform('twitter'), isTrue);
      expect(isMockBackedPlatform('x'), isTrue);
    });

    test(
      'instagram graduated off the mock list (InstagramProvider is real)',
      () {
        expect(isMockBackedPlatform('instagram'), isFalse);
      },
    );

    test('facebook, telegram, whatsapp were never mock-backed', () {
      expect(isMockBackedPlatform('facebook'), isFalse);
      expect(isMockBackedPlatform('telegram'), isFalse);
      expect(isMockBackedPlatform('whatsapp'), isFalse);
    });
  });

  group('isBetaLaunchPlatform', () {
    test('facebook, telegram, and instagram are launched', () {
      expect(isBetaLaunchPlatform('facebook'), isTrue);
      expect(isBetaLaunchPlatform('telegram'), isTrue);
      expect(isBetaLaunchPlatform('instagram'), isTrue);
    });

    test(
      'whatsapp and x/twitter stay gated — real code, not yet approved for the closed beta',
      () {
        expect(isBetaLaunchPlatform('whatsapp'), isFalse);
        expect(isBetaLaunchPlatform('x'), isFalse);
        expect(isBetaLaunchPlatform('twitter'), isFalse);
      },
    );

    test('a fully mock platform is not launched', () {
      expect(isBetaLaunchPlatform('linkedin'), isFalse);
    });
  });

  group('isBetaLaunchPublishingTarget', () {
    test('a Facebook page is a valid target', () {
      expect(
        isBetaLaunchPublishingTarget(platform: 'facebook', pageKind: 'page'),
        isTrue,
      );
    });

    test('a Telegram channel is a valid target', () {
      expect(
        isBetaLaunchPublishingTarget(platform: 'telegram', pageKind: 'channel'),
        isTrue,
      );
    });

    test(
      'an Instagram Business account (discovered through Facebook) is a valid target',
      () {
        expect(
          isBetaLaunchPublishingTarget(
            platform: 'instagram',
            pageKind: 'instagram_business',
          ),
          isTrue,
        );
      },
    );

    test('a WhatsApp number is never a valid target', () {
      expect(
        isBetaLaunchPublishingTarget(
          platform: 'whatsapp',
          pageKind: 'whatsapp_number',
        ),
        isFalse,
      );
    });

    test('a mismatched platform/kind combination fails closed', () {
      expect(
        isBetaLaunchPublishingTarget(platform: 'facebook', pageKind: 'group'),
        isFalse,
      );
      expect(
        isBetaLaunchPublishingTarget(
          platform: 'instagram',
          pageKind: 'page', // instagram never has a plain 'page' kind
        ),
        isFalse,
      );
    });
  });

  group('isBetaLaunchPublishingTargetForDiscoveryMode', () {
    test(
      'auto discovery accepts both a Facebook page and an Instagram Business account',
      () {
        expect(
          isBetaLaunchPublishingTargetForDiscoveryMode(
            discoveryMode: 'auto',
            pageKind: 'page',
          ),
          isTrue,
        );
        expect(
          isBetaLaunchPublishingTargetForDiscoveryMode(
            discoveryMode: 'auto',
            pageKind: 'instagram_business',
          ),
          isTrue,
        );
      },
    );

    test('auto discovery does not accept a Telegram channel kind', () {
      expect(
        isBetaLaunchPublishingTargetForDiscoveryMode(
          discoveryMode: 'auto',
          pageKind: 'channel',
        ),
        isFalse,
      );
    });

    test('manual discovery only accepts a Telegram channel', () {
      expect(
        isBetaLaunchPublishingTargetForDiscoveryMode(
          discoveryMode: 'manual',
          pageKind: 'channel',
        ),
        isTrue,
      );
      expect(
        isBetaLaunchPublishingTargetForDiscoveryMode(
          discoveryMode: 'manual',
          pageKind: 'page',
        ),
        isFalse,
      );
    });

    test('an unknown discovery mode fails closed', () {
      expect(
        isBetaLaunchPublishingTargetForDiscoveryMode(
          discoveryMode: 'unknown',
          pageKind: 'page',
        ),
        isFalse,
      );
    });
  });
}
