import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/organizations/application/current_organization_access.dart';

/// A short-lived navigation snapshot prevents every click from issuing the
/// same `/me` and `/organizations` calls. It is deliberately memory-only and
/// expires after 20 seconds; [invalidate] is called immediately on a real
/// 403, so server-side membership/role revocation remains authoritative.
class RouteGuardSnapshotCache {
  static const _ttl = Duration(seconds: 20);

  bool? _platformAdmin;
  DateTime? _platformAdminExpiresAt;
  Future<bool>? _platformAdminInFlight;

  OrganizationAccessState? _organizationAccess;
  DateTime? _organizationAccessExpiresAt;
  Future<OrganizationAccessState>? _organizationAccessInFlight;

  Future<bool> platformAdmin(Future<bool> Function() loader) {
    if (_isFresh(_platformAdminExpiresAt) && _platformAdmin != null) {
      return Future<bool>.value(_platformAdmin);
    }
    if (_platformAdminInFlight != null) {
      return _platformAdminInFlight!;
    }

    final future = loader();
    _platformAdminInFlight = future;
    return future
        .then((value) {
          _platformAdmin = value;
          _platformAdminExpiresAt = DateTime.now().add(_ttl);
          return value;
        })
        .whenComplete(() => _platformAdminInFlight = null);
  }

  Future<OrganizationAccessState> organizationAccess(
    Future<OrganizationAccessState> Function() loader,
  ) {
    if (_isFresh(_organizationAccessExpiresAt) && _organizationAccess != null) {
      return Future<OrganizationAccessState>.value(_organizationAccess!);
    }
    if (_organizationAccessInFlight != null) {
      return _organizationAccessInFlight!;
    }

    final future = loader();
    _organizationAccessInFlight = future;
    return future
        .then((value) {
          _organizationAccess = value;
          _organizationAccessExpiresAt = DateTime.now().add(_ttl);
          return value;
        })
        .whenComplete(() => _organizationAccessInFlight = null);
  }

  void invalidate() {
    _platformAdmin = null;
    _platformAdminExpiresAt = null;
    _organizationAccess = null;
    _organizationAccessExpiresAt = null;
  }

  bool _isFresh(DateTime? expiresAt) {
    return expiresAt != null && DateTime.now().isBefore(expiresAt);
  }
}

final routeGuardSnapshotCacheProvider = Provider<RouteGuardSnapshotCache>((
  ref,
) {
  return RouteGuardSnapshotCache();
});
