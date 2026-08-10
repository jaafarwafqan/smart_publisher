import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../application/help_content_access.dart';
import '../../content/faq_and_troubleshooting_content.dart';
import '../../content/user_guide_content.dart';
import '../../domain/models/help_content_models.dart';
import '../widgets/help_faq_list.dart';
import '../widgets/help_section_accordion.dart';
import '../widgets/help_troubleshooting_list.dart';
import '../widgets/role_permission_table.dart';

/// `/help/guide` — the full "دليل استخدام Smart Publisher". `extra` (see
/// `HelpCenterScreen`) is either an initial search string, `'#faq'`, or
/// `'#troubleshooting'` to land directly on that tab.
class UserGuideScreen extends ConsumerStatefulWidget {
  const UserGuideScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends ConsumerState<UserGuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? '';
    final initialTab = switch (initial) {
      '#faq' => 1,
      '#troubleshooting' => 2,
      _ => 0,
    };
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTab,
    );
    _searchController = TextEditingController(
      text: initialTab == 0 ? initial : '',
    );
    _query = _searchController.text;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(currentOrganizationAccessProvider).valueOrNull;

    final allSections = buildUserGuideSections();
    final visibleSections = HelpContentFilter.visibleTo(allSections, access);
    final filteredSections = HelpContentFilter.search(visibleSections, _query);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userGuideAppBarTitle(l10n.appName)),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: l10n.userGuideTocTitle),
            Tab(text: l10n.userGuideFaqSectionTitle),
            Tab(text: l10n.userGuideTroubleshootingSectionTitle),
          ],
        ),
      ),
      body: AdaptiveContentWidth(
        maxWidth: 1000,
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _GuideTab(
              searchController: _searchController,
              onQueryChanged: (value) => setState(() => _query = value),
              sections: filteredSections,
              access: access,
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: <Widget>[HelpFaqList(faqs: buildGlobalFaqs())],
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: <Widget>[
                HelpTroubleshootingList(items: buildTroubleshootingItems()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTab extends StatelessWidget {
  const _GuideTab({
    required this.searchController,
    required this.onQueryChanged,
    required this.sections,
    required this.access,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final List<HelpSection> sections;
  final OrganizationAccessState? access;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        TextField(
          controller: searchController,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: l10n.userGuideSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.userGuideClearSearchButton,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      onQueryChanged('');
                    },
                  ),
          ),
        ),
        if (access != null && !access!.hasActiveOrganization) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.userGuideNoOrganizationNotice,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (sections.isEmpty)
          AppEmptyState(
            icon: Icons.search_off,
            title: l10n.userGuideNoResultsTitle,
            message: l10n.userGuideNoResultsMessage,
          )
        else ...<Widget>[
          RolePermissionTable(rows: buildRolePermissionRows()),
          const SizedBox(height: AppSpacing.md),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: HelpSectionAccordion(section: section),
            ),
          ),
        ],
      ],
    );
  }
}
