import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_provider.dart';

const _preferredThemeStorageKey = 'settings.preferred_theme';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    unawaited(_loadPersisted());
    return ThemeMode.system;
  }

  Future<void> _loadPersisted() async {
    final stored = await ref
        .read(storageServiceProvider)
        .readString(_preferredThemeStorageKey);
    state = _parse(stored);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await ref
        .read(storageServiceProvider)
        .writeString(_preferredThemeStorageKey, _serialize(mode));
  }

  ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
