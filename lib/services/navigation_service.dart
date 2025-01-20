import 'package:flutter/material.dart';
import '../screens/loans_page.dart';
import '../screens/loans_page_ar.dart';
import '../screens/cards_page.dart';
import '../screens/cards_page_ar.dart';
import '../screens/customer_service_screen.dart';
import '../screens/account_page.dart';
import '../screens/loan_calculator_page.dart';
import '../screens/loan_calculator_page_ar.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static GlobalKey<NavigatorState>? navigatorKey;

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  Future<void> navigateToPage(String route, {bool? isArabic, Map<String, dynamic>? arguments}) async {
    if (navigatorKey?.currentState == null) return;

    isArabic ??= true; // Default to Arabic if not specified

    switch (route) {
      case '/loans':
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => isArabic! ? const LoansPageAr() : const LoansPage(),
          ),
        );
        break;
      case '/cards':
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => isArabic! ? const CardsPageAr() : const CardsPage(),
          ),
        );
        break;
      case '/calculator':
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => isArabic! ? const LoanCalculatorPageAr() : const LoanCalculatorPage(),
          ),
        );
        break;
      case '/support':
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => CustomerServiceScreen(isArabic: isArabic!),
          ),
        );
        break;
      case '/account':
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => AccountPage(isArabic: isArabic!),
          ),
        );
        break;
      default:
        // For routes that don't need language-specific handling
        navigatorKey!.currentState!.pushNamed(route, arguments: arguments);
    }
  }
} 