import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/app_routes.dart';
import 'package:smart_publisher/src/core/router/route_names.dart';

void main() {
  test('every route belongs to exactly one root or workspace branch', () {
    final assignedPaths = <String>[
      ...rootAppRoutes.map((route) => route.path),
      ...workspaceNavigationBranches.expand(
        (branch) => branch.map((route) => route.path),
      ),
    ];
    final declaredPaths = appRoutes.map((route) => route.path).toSet();

    expect(assignedPaths.length, declaredPaths.length);
    expect(assignedPaths.toSet(), declaredPaths);
    expect(workspaceNavigationBranches, hasLength(9));
    expect(
      rootAppRoutes.map((route) => route.path),
      contains(RouteNames.twoFactorSetupPath),
    );
  });

  test('daily workspace destinations each have an independent branch', () {
    final branchRoots = workspaceNavigationBranches
        .map((branch) => branch.first.path)
        .toSet();

    expect(
      branchRoots,
      containsAll(<String>{
        RouteNames.dashboardPath,
        RouteNames.postsListPath,
        RouteNames.postsCreatePath,
        RouteNames.calendarPath,
        RouteNames.analyticsPath,
        RouteNames.mediaLibraryPath,
        RouteNames.organizationsPath,
        RouteNames.settingsPath,
        RouteNames.helpCenterPath,
      }),
    );
  });
}
