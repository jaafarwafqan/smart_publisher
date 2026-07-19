import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  FutureOr<ThemeMode> build() async {
    // لاحقاً: قراءة الحالة المحفوظة من StorageManager
    return ThemeMode.system;
  }

  Future<void> changeTheme(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    // لاحقاً: حفظ الحالة في StorageManager
  }
}

final themeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
