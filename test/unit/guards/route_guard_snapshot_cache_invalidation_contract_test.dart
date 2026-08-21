import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RouteGuardSnapshotCache (route_guard_snapshot_cache.dart) sits in front of
/// currentOrganizationAccessProvider/currentPlatformAdminProvider inside
/// RouteGuards.guardPath and is NOT itself a Riverpod provider — invalidating
/// those two providers does not clear it. Four independent review passes
/// found the same live bug from this: login, register, the 2FA challenge,
/// logout (three separate screens), and switching organizations all called
/// `ref.invalidate(currentOrganizationAccessProvider)` /
/// `ref.invalidate(currentPlatformAdminProvider)` without also calling
/// `ref.read(routeGuardSnapshotCacheProvider).invalidate()` — so on Flutter
/// Web, where the ProviderContainer survives a full logout->login cycle in
/// the same tab, a second account signing in within the cache's 20s TTL
/// could briefly inherit the previous account's cached platform-admin/
/// org-access route-guard decision.
///
/// This is a structural (source-text) check rather than a behavioral one —
/// matching this repo's existing test/quality/accessibility_contract_test.dart
/// convention — because the actual fix is "every file that invalidates one
/// of those two providers must also invalidate the snapshot cache," which is
/// far more reliably enforced by keeping the two greps in lockstep than by
/// mocking through each of the five screens involved.
void main() {
  test(
    'every call site that invalidates currentOrganizationAccessProvider or '
    'currentPlatformAdminProvider also invalidates routeGuardSnapshotCacheProvider',
    () {
      final offenders = <String>[];

      for (final file in _dartSources()) {
        // route_guard_snapshot_cache.dart itself and its own unit test
        // legitimately reference the provider/invalidate() without pairing
        // them with themselves.
        if (file.path
            .replaceAll('\\', '/')
            .contains('route_guard_snapshot_cache')) {
          continue;
        }

        final source = file.readAsStringSync();
        final invalidatesGuardedProvider =
            source.contains(
              'ref.invalidate(currentOrganizationAccessProvider)',
            ) ||
            source.contains('ref.invalidate(currentPlatformAdminProvider)');
        if (!invalidatesGuardedProvider) {
          continue;
        }

        if (!source.contains('routeGuardSnapshotCacheProvider')) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These files invalidate currentOrganizationAccessProvider/'
            'currentPlatformAdminProvider without also invalidating '
            'routeGuardSnapshotCacheProvider, leaving RouteGuards.guardPath '
            'free to keep serving a stale cached decision for up to 20s: '
            '$offenders',
      );
    },
  );
}

List<File> _dartSources() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}
