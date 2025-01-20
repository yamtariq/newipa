import 'package:flutter/material.dart';
import 'main_page.dart';

class MainPageAr extends StatelessWidget {
  final Function(bool) onLanguageChanged;
  const MainPageAr({super.key, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MainPage(
        isArabic: true,
        onLanguageChanged: onLanguageChanged,
      ),
    );
  }
} 