import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/storage_provider.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: AdaptiveContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: <Widget>[
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
                    const SizedBox(height: AppSpacing.md),
                    AnimatedContainer(
                      duration: AppDuration.slow,
                      curve: AppCurves.standard,
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: AnimatedSwitcher(
                        duration: AppDuration.normal,
                        switchInCurve: AppCurves.standard,
                        switchOutCurve: AppCurves.standard,
                        child: Directionality(
                          textDirection: currentLocale.languageCode == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Text(
                            currentLocale.languageCode == 'ar'
                                ? l10n.settingsLanguageArabic
                                : l10n.settingsLanguageEnglish,
                            key: ValueKey<String>(currentLocale.languageCode),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            Card(
              child: SwitchListTile(
                title: Text(l10n.settingsAutoScheduleTitle),
                subtitle: Text(l10n.settingsAutoScheduleSubtitle),
                value: false,
                onChanged: null,
              ),
            ),
            Card(
              child: SwitchListTile(
                title: Text(l10n.settingsCanaryReleaseTitle),
                subtitle: Text(l10n.settingsCanaryReleaseSubtitle),
                value: false,
                onChanged: null,
              ),
            ),
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
      ),
    );
  }
}
