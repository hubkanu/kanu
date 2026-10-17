import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Gestion du thème clair / sombre / système, persistée localement.
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      _fromString(ref.read(preferencesServiceProvider).themeMode);

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(preferencesServiceProvider).setThemeMode(mode.name);
  }

  Future<void> toggle() async {
    await setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  String get label {
    switch (state) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
