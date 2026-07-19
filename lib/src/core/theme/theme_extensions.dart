import 'package:flutter/material.dart';
import 'app_extensions.dart';

extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
}
