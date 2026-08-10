import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/dashboard/application/account_operation_access.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';

import '../../helpers/organization_role_fixtures.dart';

OrganizationAccessState _accessFor(String role) {
  final membership = OrganizationEntity(
    id: 1,
    name: 'Beta organization',
    slug: 'beta-organization',
    role: role,
    isCurrent: true,
    permissions: permissionsForRole(role),
  );

  return OrganizationAccessState.active(
    memberships: <OrganizationEntity>[membership],
    currentOrganization: membership,
  );
}

void main() {
  test(
    'dashboard account actions mirror the active organization permissions',
    () {
      final editor = AccountOperationAccess.fromOrganizationAccess(
        _accessFor('editor'),
      );
      final manager = AccountOperationAccess.fromOrganizationAccess(
        _accessFor('manager'),
      );
      final admin = AccountOperationAccess.fromOrganizationAccess(
        _accessFor('admin'),
      );
      final owner = AccountOperationAccess.fromOrganizationAccess(
        _accessFor('owner'),
      );

      expect(editor.canCreate, isFalse);
      expect(editor.canUpdate, isFalse);
      expect(editor.canConnect, isFalse);
      expect(editor.canDisconnect, isFalse);
      expect(editor.canDelete, isFalse);
      expect(editor.canTest, isFalse);
      expect(editor.canRefresh, isFalse);
      expect(editor.canSyncPages, isFalse);
      expect(editor.canSelectPages, isFalse);

      for (final access in <AccountOperationAccess>[manager, admin, owner]) {
        expect(access.canCreate, isTrue);
        expect(access.canUpdate, isTrue);
        expect(access.canConnect, isTrue);
        expect(access.canDisconnect, isTrue);
        expect(access.canDelete, isTrue);
        expect(access.canTest, isTrue);
        expect(access.canRefresh, isTrue);
        expect(access.canSyncPages, isTrue);
        expect(access.canSelectPages, isTrue);
      }
    },
  );

  test('missing active-organization access fails closed', () {
    const denied = AccountOperationAccess.denied();

    expect(denied.canCreate, isFalse);
    expect(denied.canUpdate, isFalse);
    expect(denied.canConnect, isFalse);
    expect(denied.canDisconnect, isFalse);
    expect(denied.canDelete, isFalse);
    expect(denied.canTest, isFalse);
    expect(denied.canRefresh, isFalse);
    expect(denied.canSyncPages, isFalse);
    expect(denied.canSelectPages, isFalse);
  });
}
