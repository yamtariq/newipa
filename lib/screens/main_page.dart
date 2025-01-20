import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/theme_service.dart';
import 'main_page_dark.dart';
import 'main_page_white.dart';

class MainPage extends StatefulWidget {
  final bool isArabic;
  final Function(bool)? onLanguageChanged;
  final Map<String, dynamic> userData;

  const MainPage({
    Key? key,
    required this.isArabic,
    this.onLanguageChanged,
    required this.userData,
  }) : super(key: key);

  static Future<bool> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isArabic') ?? false; // Default to English if not set
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // If dark mode is enabled, show MainPageDark, otherwise show MainPageWhite
        return themeProvider.isDarkMode
            ? MainPageDark(
                isArabic: widget.isArabic,
                onLanguageChanged: widget.onLanguageChanged,
                userData: widget.userData,
              )
            : MainPageWhite(
                isArabic: widget.isArabic,
                onLanguageChanged: widget.onLanguageChanged,
                userData: widget.userData,
              );
      },
    );
  }
} 