import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('theme_is_dark');
      if (isDark != null) {
        state = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_is_dark', state == ThemeMode.dark);
    } catch (_) {}
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class CustomThemeColorNotifier extends StateNotifier<Color> {
  // Default is 0xFF5B67F1 (Royal Blue)
  CustomThemeColorNotifier() : super(const Color(0xFF5B67F1)) {
    _loadColor();
  }

  Future<void> _loadColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorVal = prefs.getInt('accent_color');
      if (colorVal != null) {
        state = Color(colorVal);
      }
    } catch (_) {}
  }

  Future<void> updateColor(Color color) async {
    state = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accent_color', color.value);
    } catch (_) {}
  }
}

final customThemeColorProvider = StateNotifierProvider<CustomThemeColorNotifier, Color>((ref) {
  return CustomThemeColorNotifier();
});
