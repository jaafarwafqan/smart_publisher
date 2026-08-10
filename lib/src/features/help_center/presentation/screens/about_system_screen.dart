import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/release/release_config.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../content/about_content.dart';
import '../../domain/models/platform_help_status.dart';
import '../widgets/legal_document_dialog.dart';
import '../widgets/platform_status_card.dart';

/// Sprint (Help Center, 2026-08-10): publicly reachable both before and
/// after login (see `RouteGuards.guardPath` — `/about` is special-cased at
/// the very top, unconditionally allowed), so this screen must never
/// assume an authenticated session or an active organization.
class AboutSystemScreen extends ConsumerWidget {
  const AboutSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // Scaffold's default already shows a back button only when there's
      // something to pop (via the ambient Navigator, not GoRouter
      // specifically) — no custom canPop() check needed, and calling
      // GoRouter.of(context) unconditionally would throw wherever this
      // screen is hosted without a GoRouter ancestor.
      appBar: AppBar(title: Text(l10n.aboutAppBarTitle(l10n.appName))),
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
            _SectionCard(
              title: l10n.aboutSectionDefinitionTitle(l10n.appName),
              child: Text(AboutContent.systemDefinition),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionGoalsTitle,
              child: _BulletList(items: AboutContent.goals),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionFeaturesTitle,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: AboutContent.realFeatures
                    .map((feature) => Chip(label: Text(feature)))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionPlatformsTitle,
              child: Column(
                children: platformHelpStatuses()
                    .map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PlatformStatusCard(status: status),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionRolesTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _RoleLine(
                    role: 'Viewer',
                    description:
                        'مشاهدة المنشورات والحسابات والتحليلات فقط، دون أي إجراء تعديل.',
                  ),
                  const _RoleLine(
                    role: 'Editor',
                    description:
                        'إنشاء منشوراته الخاصة وإرسالها لطلب موافقة قبل النشر.',
                  ),
                  const _RoleLine(
                    role: 'Manager',
                    description:
                        'إدارة الحسابات الاجتماعية والمحتوى، والموافقة على المنشورات ونشرها مباشرة.',
                  ),
                  const _RoleLine(
                    role: 'Admin',
                    description:
                        'كل صلاحيات Manager، بالإضافة إلى إدارة أعضاء المؤسسة وإعداداتها.',
                  ),
                  const _RoleLine(
                    role: 'Owner',
                    description:
                        'الملكية الكاملة للمؤسسة، بما فيها نقل الملكية أو حذف المؤسسة.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.aboutSuperAdminRoleNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionSecurityTitle,
              child: _BulletList(items: AboutContent.security),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionAppInfoTitle,
              child: _AppInfoBody(),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.aboutSectionTeamTitle,
              child: Text(AboutContent.copyrightHolder),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: FilledButton.icon(
                onPressed: () => context.push(RouteNames.helpCenterPath),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.aboutOpenHelpGuideButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final packageInfo = ref.watch(packageInfoProvider);
    final environment =
        '${const ReleaseConfig().wireValue} '
        '(${kReleaseMode
            ? 'release'
            : kProfileMode
            ? 'profile'
            : 'debug'})';
    final year = DateTime.now().year.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        packageInfo.when(
          data: (info) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InfoRow(label: l10n.aboutAppVersionLabel, value: info.version),
              _InfoRow(label: l10n.aboutAppBuildLabel, value: info.buildNumber),
              _InfoRow(
                label: l10n.aboutAppPackageLabel,
                value: info.packageName,
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Text(l10n.aboutLoadErrorMessage),
        ),
        _InfoRow(label: l10n.aboutAppEnvironmentLabel, value: environment),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.aboutCopyrightLabel(year, AboutContent.copyrightHolder)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            TextButton(
              onPressed: () => showLegalDocumentDialog(
                context,
                title: l10n.aboutPrivacyPolicyLink,
                assetPath: 'docs/legal/privacy_policy.md',
              ),
              child: Text(l10n.aboutPrivacyPolicyLink),
            ),
            TextButton(
              onPressed: () => showLegalDocumentDialog(
                context,
                title: l10n.aboutTermsOfServiceLink,
                assetPath: 'docs/legal/terms_of_service.md',
              ),
              child: Text(l10n.aboutTermsOfServiceLink),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.accountDataDeletionPath),
              child: Text(l10n.aboutDataDeletionLink),
            ),
            TextButton(
              onPressed: () => showLegalDocumentDialog(
                context,
                title: l10n.aboutSupportLink,
                assetPath: 'docs/legal/support.md',
              ),
              child: Text(l10n.aboutSupportLink),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _RoleLine extends StatelessWidget {
  const _RoleLine({required this.role, required this.description});

  final String role;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <InlineSpan>[
            TextSpan(
              text: '$role: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 6, right: 6),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
