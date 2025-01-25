import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'is_dark_mode';

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load saved theme preference
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Save theme preference
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Get current theme colors
  Color get primaryColor => _isDarkMode 
      ? Color(Constants.darkPrimaryColor)
      : Color(Constants.lightPrimaryColor);

  Color get backgroundColor => _isDarkMode
      ? Color(Constants.darkBackgroundColor)
      : Color(Constants.lightBackgroundColor);

  Color get surfaceColor => _isDarkMode
      ? Color(Constants.darkSurfaceColor)
      : Color(Constants.lightSurfaceColor);

  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemeToPrefs();
    notifyListeners();
  }

  // Set specific theme
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _saveThemeToPrefs();
    notifyListeners();
  }

  // Get ThemeData
  ThemeData get themeData => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,
    brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      background: backgroundColor,
      surface: surfaceColor,
      secondary: const Color(0xFF00A650), // Nayifat green
      onPrimary: _isDarkMode ? Colors.black : Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: _isDarkMode ? Colors.black : Colors.white,
      elevation: 0,
    ),
  );
} 