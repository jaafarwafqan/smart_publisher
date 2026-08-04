import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_provider.dart';

const _preferredLocaleStorageKey = 'settings.preferred_locale';

/// Arabic is this app's primary language (its main audience), English is
/// the switchable secondary — mirrors ThemeModeNotifier's persisted-Notifier
/// pattern exactly.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    unawaited(_loadPersisted());
    return const Locale('ar');
  }

  Future<void> _loadPersisted() async {
    final stored = await ref
        .read(storageServiceProvider)
        .readString(_preferredLocaleStorageKey);
    if (stored == 'en') {
      state = const Locale('en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref
        .read(storageServiceProvider)
        .writeString(_preferredLocaleStorageKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
