import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readProjectFile(String relativePath) {
  final file = File(relativePath);
  expect(file.existsSync(), isTrue, reason: 'Expected $relativePath to exist.');
  return file.readAsStringSync();
}

String _androidSourceSetXml(String sourceSet) {
  final directory = Directory('android/app/src/$sourceSet');
  if (!directory.existsSync()) {
    return '';
  }

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.xml'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}

void main() {
  const productionApplicationId = 'com.smartpublisher.app';

  group('Android release configuration', () {
    test('main manifest grants INTERNET and release sources reject cleartext', () {
      final mainManifest = _readProjectFile(
        'android/app/src/main/AndroidManifest.xml',
      );
      final releaseSources =
          '${_androidSourceSetXml('main')}\n${_androidSourceSetXml('release')}';

      expect(
        mainManifest,
        contains(
          '<uses-permission android:name="android.permission.INTERNET"/>',
        ),
        reason:
            'Release builds merge the main manifest and require API access.',
      );
      expect(
        mainManifest,
        contains('android:usesCleartextTraffic="false"'),
        reason: 'Release traffic must use TLS.',
      );
      expect(releaseSources, isNot(contains('usesCleartextTraffic="true"')));
      expect(
        releaseSources,
        isNot(contains('cleartextTrafficPermitted="true"')),
        reason:
            'Release source sets must not opt a network security config into HTTP.',
      );

      final debugManifest = _readProjectFile(
        'android/app/src/debug/AndroidManifest.xml',
      );
      expect(debugManifest, contains('android:usesCleartextTraffic="true"'));
      expect(
        debugManifest,
        contains('tools:replace="android:usesCleartextTraffic"'),
        reason:
            'The local HTTP exception must remain an explicit debug override.',
      );
    });

    test('launcher metadata and OAuth callback are production-specific', () {
      final mainManifest = _readProjectFile(
        'android/app/src/main/AndroidManifest.xml',
      );

      expect(mainManifest, contains('android:label="Smart Publisher"'));
      expect(
        mainManifest,
        contains('android:icon="@mipmap/ic_launcher_smart_publisher"'),
      );
      expect(mainManifest, contains('android:scheme="smartpublisher"'));
      expect(mainManifest, contains('android:host="oauth"'));
      expect(mainManifest, contains('android:pathPrefix="/callback"'));
    });

    test(
      'application identity and MainActivity package are production-consistent',
      () {
        final gradle = _readProjectFile('android/app/build.gradle.kts');
        final namespace = RegExp(
          r'namespace\s*=\s*"([^"]+)"',
        ).firstMatch(gradle)?.group(1);
        final applicationId = RegExp(
          r'applicationId\s*=\s*"([^"]+)"',
        ).firstMatch(gradle)?.group(1);
        final activity = _readProjectFile(
          'android/app/src/main/kotlin/com/smartpublisher/app/MainActivity.kt',
        );

        expect(namespace, productionApplicationId);
        expect(applicationId, productionApplicationId);
        expect(applicationId, isNot(startsWith('com.example.')));
        expect(activity, contains('package $productionApplicationId'));
        expect(
          File(
            'android/app/src/main/kotlin/com/example/smart_publisher/MainActivity.kt',
          ).existsSync(),
          isFalse,
          reason:
              'The default Android package must not remain in the source tree.',
        );
      },
    );

    test('release signing has no debug-key fallback', () {
      final gradle = _readProjectFile('android/app/build.gradle.kts');

      expect(gradle, contains('ANDROID_RELEASE_STORE_FILE'));
      expect(gradle, contains('ANDROID_RELEASE_STORE_PASSWORD'));
      expect(gradle, contains('ANDROID_RELEASE_KEY_ALIAS'));
      expect(gradle, contains('ANDROID_RELEASE_KEY_PASSWORD'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
      expect(gradle, contains('verifyReleaseSigning'));
      expect(
        gradle,
        contains(
          'name in setOf("assembleRelease", "bundleRelease", "packageRelease")',
        ),
      );
    });
  });
}
