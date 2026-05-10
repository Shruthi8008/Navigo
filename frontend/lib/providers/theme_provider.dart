import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme(bool isDarkMode) {
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

final lightThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF9F9F9),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
    ),
  );
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.dark,
    ),
  );
});
