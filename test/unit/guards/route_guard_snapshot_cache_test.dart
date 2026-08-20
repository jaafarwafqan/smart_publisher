import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/route_guard_snapshot_cache.dart';

void main() {
  group('RouteGuardSnapshotCache', () {
    test('reuses a platform decision within its short TTL', () async {
      final cache = RouteGuardSnapshotCache();
      var calls = 0;

      Future<bool> load() async {
        calls += 1;
        return true;
      }

      expect(await cache.platformAdmin(load), isTrue);
      expect(await cache.platformAdmin(load), isTrue);
      expect(calls, 1);
    });

    test('invalidates a cached platform decision immediately', () async {
      final cache = RouteGuardSnapshotCache();
      var calls = 0;

      Future<bool> load() async {
        calls += 1;
        return calls.isOdd;
      }

      expect(await cache.platformAdmin(load), isTrue);
      cache.invalidate();
      expect(await cache.platformAdmin(load), isFalse);
      expect(calls, 2);
    });
  });
}
