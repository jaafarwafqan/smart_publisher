import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

/// Widget tests that pump a screen/dialog directly inside a bare
/// `MaterialApp` (rather than the full `SmartPublisherApp`) need this to
/// provide `AppLocalizations.of(context)` — otherwise any localized widget
/// throws a null-check error the moment it builds. Defaults to English so
/// existing assertions on literal English copy keep working unchanged.
const List<LocalizationsDelegate<dynamic>> testLocalizationsDelegates =
    AppLocalizations.localizationsDelegates;

const List<Locale> testSupportedLocales = AppLocalizations.supportedLocales;
