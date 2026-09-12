import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _restore();
  }

  Future<void> _restore() async {
    final saved = await StorageService.getThemeMode();
    if (saved == 'dark') state = ThemeMode.dark;
    if (saved == 'light') state = ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await StorageService.saveThemeMode(state == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
