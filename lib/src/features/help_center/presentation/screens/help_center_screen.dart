import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../content/faq_and_troubleshooting_content.dart';
import '../widgets/help_faq_list.dart';

/// The `/help` landing hub — a search box plus quick links, distinct from
/// `/help/guide`'s full step-by-step content. Reachable by any
/// authenticated non-platform-admin member regardless of active
/// organization (see `RouteGuards.guardPath`), so a brand-new user with no
/// organization yet can still find their way around.
class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGuide([String? query]) {
    context.push(RouteNames.userGuidePath, extra: query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(currentOrganizationAccessProvider).valueOrNull;
    final faqs = buildGlobalFaqs().take(4).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpCenterAppBarTitle)),
      body: AdaptiveContentWidth(
        maxWidth: 900,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            Text(
              l10n.helpCenterSubtitle(l10n.appName),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _openGuide,
              decoration: InputDecoration(
                hintText: l10n.helpCenterSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: l10n.helpCenterSearchHint,
                  onPressed: () => _openGuide(_searchController.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            if (access != null && !access.hasActiveOrganization) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.helpCenterNoOrganizationNotice,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.helpCenterQuickLinksTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuickLinkCard(
              icon: Icons.menu_book_outlined,
              title: l10n.helpCenterOpenGuideButton,
              subtitle: '',
              onTap: () => _openGuide(),
            ),
            _QuickLinkCard(
              icon: Icons.info_outline,
              title: l10n.helpCenterAboutCardTitle,
              subtitle: l10n.helpCenterAboutCardSubtitle(l10n.appName),
              onTap: () => context.push(RouteNames.aboutPath),
            ),
            _QuickLinkCard(
              icon: Icons.quiz_outlined,
              title: l10n.helpCenterFaqCardTitle,
              subtitle: l10n.helpCenterFaqCardSubtitle,
              onTap: () =>
                  context.push(RouteNames.userGuidePath, extra: '#faq'),
            ),
            _QuickLinkCard(
              icon: Icons.build_outlined,
              title: l10n.helpCenterTroubleshootingCardTitle,
              subtitle: l10n.helpCenterTroubleshootingCardSubtitle,
              onTap: () => context.push(
                RouteNames.userGuidePath,
                extra: '#troubleshooting',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.helpCenterFaqCardTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            HelpFaqList(faqs: faqs),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left
              : Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}
