import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
ThemeMode theme(ThemeRef ref) {
  // لاحقاً: ربطها بتخزين دائم عبر Notifier عند إضافة persistence.
  return ThemeMode.system;
}
