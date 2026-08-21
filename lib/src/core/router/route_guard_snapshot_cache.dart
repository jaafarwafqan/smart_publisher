import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/organizations/application/current_organization_access.dart';

/// A short-lived navigation snapshot prevents every click from issuing the
/// same `/me` and `/organizations` calls. It is deliberately memory-only and
/// expires after 20 seconds; [invalidate] is called immediately on a real
/// 403, so server-side membership/role revocation remains authoritative.
class RouteGuardSnapshotCache {
  static const _ttl = Duration(seconds: 20);

  final _CachedValue<bool> _platformAdmin = _CachedValue<bool>();
  final _CachedValue<OrganizationAccessState> _organizationAccess =
      _CachedValue<OrganizationAccessState>();

  Future<bool> platformAdmin(Future<bool> Function() loader) {
    return _platformAdmin.resolve(loader, _ttl);
  }

  Future<OrganizationAccessState> organizationAccess(
    Future<OrganizationAccessState> Function() loader,
  ) {
    return _organizationAccess.resolve(loader, _ttl);
  }

  void invalidate() {
    _platformAdmin.clear();
    _organizationAccess.clear();
  }
}

/// TTL + in-flight-dedup memoization for a single value. Was hand-copied
/// once per cached field (platformAdmin/organizationAccess) with identical
/// freshness-check/in-flight-dedupe/populate-on-success logic differing only
/// by field name and type — any future fix to the caching strategy (TTL,
/// dedupe race, ...) had to be applied twice by hand. Generic so a third
/// guard decision needing the same treatment is just another field, not
/// another copy of this logic.
class _CachedValue<T> {
  T? _value;
  DateTime? _expiresAt;
  Future<T>? _inFlight;

  Future<T> resolve(Future<T> Function() loader, Duration ttl) {
    if (_isFresh() && _value != null) {
      return Future<T>.value(_value as T);
    }
    if (_inFlight != null) {
      return _inFlight!;
    }

    final future = loader();
    _inFlight = future;
    return future
        .then((value) {
          _value = value;
          _expiresAt = DateTime.now().add(ttl);
          return value;
        })
        .whenComplete(() => _inFlight = null);
  }

  void clear() {
    _value = null;
    _expiresAt = null;
  }

  bool _isFresh() {
    final expiresAt = _expiresAt;
    return expiresAt != null && DateTime.now().isBefore(expiresAt);
  }
}

final routeGuardSnapshotCacheProvider = Provider<RouteGuardSnapshotCache>((
  ref,
) {
  return RouteGuardSnapshotCache();
});
