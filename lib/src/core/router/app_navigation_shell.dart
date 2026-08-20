import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_publisher/l10n/app_localizations.dart';

import 'route_names.dart';

/// Persistent workspace navigation for wide Flutter Web layouts. Authentication
/// and public-information pages intentionally remain distraction-free; every
/// signed-in workspace page shares this responsive shell instead of relying on
/// a browser's back button as its only cross-feature navigation.
class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const _unframedPaths = <String>{
    RouteNames.splashPath,
    RouteNames.welcomePath,
    RouteNames.loginPath,
    RouteNames.registerPath,
    RouteNames.forgotPasswordPath,
    RouteNames.resetPasswordPath,
    RouteNames.twoFactorChallengePath,
    RouteNames.aboutPath,
  };

  @override
  Widget build(BuildContext context) {
    if (_unframedPaths.contains(location)) {
      return child;
    }

    final l10n = AppLocalizations.of(context)!;
    final destinations = <_Destination>[
      _Destination(
        RouteNames.dashboardPath,
        Icons.space_dashboard_outlined,
        l10n.dashboardTitle,
      ),
      _Destination(
        RouteNames.postsListPath,
        Icons.article_outlined,
        l10n.dashboardPostsButton,
      ),
      _Destination(
        RouteNames.postsCreatePath,
        Icons.add_box_outlined,
        l10n.dashboardCreatePostButton,
      ),
      _Destination(
        RouteNames.calendarPath,
        Icons.calendar_month_outlined,
        l10n.calendarAppBarTitle,
      ),
      _Destination(
        RouteNames.analyticsPath,
        Icons.insights_outlined,
        l10n.analyticsAppBarTitle,
      ),
      _Destination(
        RouteNames.mediaLibraryPath,
        Icons.perm_media_outlined,
        l10n.mediaAppBarTitle,
      ),
      _Destination(
        RouteNames.organizationsPath,
        Icons.business_outlined,
        l10n.settingsOrganizationsTitle,
      ),
      _Destination(
        RouteNames.settingsPath,
        Icons.settings_outlined,
        l10n.settingsScreenTitle,
      ),
      _Destination(
        RouteNames.helpCenterPath,
        Icons.help_outline,
        l10n.helpCenterAppBarTitle,
      ),
    ];
    final selectedIndex = _selectedIndex(destinations);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (index) =>
                    context.go(destinations[index].path),
                destinations: destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.icon, fill: 1),
                        label: Text(destination.label),
                      ),
                    )
                    .toList(growable: false),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          );
        }

        // Compact navigation prioritizes the five daily workflow surfaces;
        // the desktop rail exposes the complete workspace without forcing a
        // cramped, overflowing bottom bar on phones/tablets.
        final compactDestinations = destinations
            .take(5)
            .toList(growable: false);
        final compactIndex = selectedIndex >= compactDestinations.length
            ? 0
            : selectedIndex;
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: compactIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (index) =>
                context.go(compactDestinations[index].path),
            destinations: compactDestinations
                .map(
                  (destination) => NavigationDestination(
                    icon: Tooltip(
                      message: destination.label,
                      child: Icon(destination.icon),
                    ),
                    selectedIcon: Tooltip(
                      message: destination.label,
                      child: Icon(destination.icon, fill: 1),
                    ),
                    // Tooltips retain an accessible name without duplicating
                    // each screen's visible title in a compact layout.
                    label: '',
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }

  int _selectedIndex(List<_Destination> destinations) {
    final exactIndex = destinations.indexWhere(
      (destination) => location == destination.path,
    );
    if (exactIndex >= 0) {
      return exactIndex;
    }

    final nestedIndex = destinations.indexWhere(
      (destination) =>
          destination.path != RouteNames.dashboardPath &&
          location.startsWith('${destination.path}/'),
    );
    return nestedIndex >= 0 ? nestedIndex : 0;
  }
}

class _Destination {
  const _Destination(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}
