class AppLocalizations {
  static bool isArabic = false; // Set this to true for Arabic, false for English

  /// Returns the appropriate text based on the current language.
  static String getText(String en, String ar) {
    return isArabic ? ar : en;
  }
}
