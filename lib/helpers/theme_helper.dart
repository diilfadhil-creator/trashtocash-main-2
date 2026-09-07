import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static final ValueNotifier<double> textScaleNotifier =
      ValueNotifier<double>(1.0);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeSelection = prefs.getString('appThemeSelection') ?? 'Terang';
    if (themeSelection == 'Gelap') {
      themeNotifier.value = ThemeMode.dark;
    } else if (themeSelection == 'Sistem') {
      themeNotifier.value = ThemeMode.system;
    } else {
      themeNotifier.value = ThemeMode.light;
    }

    final textSize = prefs.getString('appTextSize') ?? 'Standar (100%)';
    textScaleNotifier.value = getTextScaleFactor(textSize);
  }

  static double getTextScaleFactor(String sizeLabel) {
    if (sizeLabel.contains('Kecil')) {
      return 0.88;
    } else if (sizeLabel.contains('Besar') && !sizeLabel.contains('Ekstra')) {
      return 1.15;
    } else if (sizeLabel.contains('Ekstra') || sizeLabel.contains('Sangat')) {
      return 1.30;
    }
    return 1.0;
  }

  static bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  static Future<void> setThemeSelection(String selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appThemeSelection', selection);
    if (selection == 'Gelap') {
      themeNotifier.value = ThemeMode.dark;
      await prefs.setBool('isDarkMode', true);
    } else if (selection == 'Sistem') {
      themeNotifier.value = ThemeMode.system;
    } else {
      themeNotifier.value = ThemeMode.light;
      await prefs.setBool('isDarkMode', false);
    }
  }

  static Future<void> toggleTheme(bool isDark) async {
    await setThemeSelection(isDark ? 'Gelap' : 'Terang');
  }

  static Future<void> setTextSize(String sizeLabel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTextSize', sizeLabel);
    textScaleNotifier.value = getTextScaleFactor(sizeLabel);
  }

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0D6938),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D6938),
        brightness: Brightness.light,
        primary: const Color(0xFF0D6938),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F8F5),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D6938),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: 'Roboto',
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0D6938),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D6938),
        brightness: Brightness.dark,
        primary: const Color(0xFF1E9B56),
        surface: const Color(0xFF1E2521),
      ),
      scaffoldBackgroundColor: const Color(0xFF121814),
      cardColor: const Color(0xFF1C241E),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E2821),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1C241E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A3E22),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}
