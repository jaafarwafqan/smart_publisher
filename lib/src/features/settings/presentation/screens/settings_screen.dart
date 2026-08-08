import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/locale/locale_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/storage_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/widgets/email_verification_banner.dart';

ThemeMode _themeModeFromKey(String key) {
  switch (key) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _keyPreferredTheme = 'settings.preferred_theme';

  String _preferredTheme = 'system';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);

    final theme = await storage.readString(_keyPreferredTheme);

    if (!mounted) {
      return;
    }

    setState(() {
      _preferredTheme = theme ?? 'system';
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final storage = ref.read(storageServiceProvider);

    await storage.writeString(_keyPreferredTheme, _preferredTheme);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.settingsSavedSuccess),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    const sectionGap = SizedBox(height: AppSpacing.sm);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: <Widget>[
          const EmailVerificationBanner(),
          sectionGap,
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: Text(l10n.settingsOrganizationsTitle),
              subtitle: Text(l10n.settingsOrganizationsSubtitle),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onTap: () => context.push(RouteNames.organizationsPath),
            ),
          ),
          sectionGap,
          Card(
            child: ListTile(
              leading: const Icon(Icons.group_outlined),
              title: Text(l10n.settingsMembersTitle),
              subtitle: Text(l10n.settingsMembersSubtitle),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onTap: () => context.push(RouteNames.organizationMembersPath),
            ),
          ),
          sectionGap,
          Card(
            child: ListTile(
              leading: const Icon(Icons.security_outlined),
              title: Text(l10n.settingsTwoFactorTitle),
              subtitle: Text(l10n.settingsTwoFactorSubtitle),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onTap: () => context.push(RouteNames.twoFactorSetupPath),
            ),
          ),
          sectionGap,
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.settingsDataExportTitle),
              subtitle: Text(l10n.settingsDataExportSubtitle),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onTap: () => context.push(RouteNames.accountDataExportPath),
            ),
          ),
          sectionGap,
          Card(
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.settingsDataDeletionTitle,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: Text(l10n.settingsDataDeletionSubtitle),
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onTap: () => context.push(RouteNames.accountDataDeletionPath),
            ),
          ),
          sectionGap,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.settingsLanguageTitle),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'ar',
                        label: Text(l10n.settingsLanguageArabic),
                      ),
                      ButtonSegment<String>(
                        value: 'en',
                        label: Text(l10n.settingsLanguageEnglish),
                      ),
                    ],
                    selected: <String>{currentLocale.languageCode},
                    onSelectionChanged: (value) {
                      unawaited(
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(value.first)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          sectionGap,
          // These three are deliberately fixed off and non-interactive:
          // none of push notifications, auto-schedule, or canary releases
          // have any real backend/behavioral integration in this build yet
          // (confirmed via audit — flipping them previously wrote to local
          // storage that nothing else in the app ever read). Showing a live
          // toggle with no effect misleads the user into thinking the
          // feature is active; disabling with an explicit "not available
          // yet" subtitle is the honest state until real integration ships.
          Card(
            child: SwitchListTile(
              title: Text(l10n.settingsPushNotificationsTitle),
              subtitle: Text(l10n.settingsPushNotificationsSubtitle),
              value: false,
              onChanged: null,
            ),
          ),
          sectionGap,
          Card(
            child: SwitchListTile(
              title: Text(l10n.settingsAutoScheduleTitle),
              subtitle: Text(l10n.settingsAutoScheduleSubtitle),
              value: false,
              onChanged: null,
            ),
          ),
          sectionGap,
          Card(
            child: SwitchListTile(
              title: Text(l10n.settingsCanaryReleaseTitle),
              subtitle: Text(l10n.settingsCanaryReleaseSubtitle),
              value: false,
              onChanged: null,
            ),
          ),
          sectionGap,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.settingsPreferredTheme),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'system',
                        label: Text(l10n.settingsThemeSystem),
                      ),
                      ButtonSegment<String>(
                        value: 'light',
                        label: Text(l10n.settingsThemeLight),
                      ),
                      ButtonSegment<String>(
                        value: 'dark',
                        label: Text(l10n.settingsThemeDark),
                      ),
                    ],
                    selected: <String>{_preferredTheme},
                    onSelectionChanged: (value) {
                      final selected = value.first;
                      setState(() {
                        _preferredTheme = selected;
                      });
                      unawaited(
                        ref
                            .read(themeProvider.notifier)
                            .setTheme(_themeModeFromKey(selected)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _persist,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.settingsSaveButton),
          ),
        ],
      ),
    );
  }
}
