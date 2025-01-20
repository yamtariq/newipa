import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_page.dart';
import 'screens/apply_user_details_screen.dart';
import 'screens/apply_loan_calculation.dart';
import 'screens/loans_page.dart';
import 'screens/loans_page_ar.dart';
import 'screens/cards_page.dart';
import 'screens/cards_page_ar.dart';
import 'screens/customer_service_screen.dart';
import 'screens/account_page.dart';
import 'screens/loan_calculator_page.dart';
import 'screens/loan_calculator_page_ar.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../services/theme_service.dart';
import '../screens/main_page_white.dart';
import 'services/content_update_service.dart';
import 'screens/loading_screen.dart';
import 'providers/theme_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  NavigationService().setNavigatorKey(navigatorKey);
  NotificationService().setNavigatorKey(navigatorKey);
  
  // Load saved language preference
  final isArabic = await MainPage.loadSavedLanguage();
  
  // Initialize notifications
  try {
    await NotificationService().initialize();
    debugPrint('Notifications initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
    // Continue app initialization even if notifications fail
  }
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SessionProvider()..initializeSession(),
          ),
          ChangeNotifierProvider(
            create: (_) => ContentUpdateService(),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
        ],
        child: MyApp(initialIsArabic: isArabic),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  final bool initialIsArabic;
  
  const MyApp({super.key, required this.initialIsArabic});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late bool isArabic;
  final ContentUpdateService _contentUpdateService = ContentUpdateService();
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    isArabic = widget.initialIsArabic;
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Setup the repeating animation with pause
    _startRotationAnimation();
  }

  void _startRotationAnimation() {
    _animationController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _startRotationAnimation();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App coming to foreground - check for updates with resume flag
      _contentUpdateService.checkAndUpdateContent(force: false, isResumed: true);
    }
  }

  void _handleLanguageChange(bool newIsArabic) {
    setState(() {
      isArabic = newIsArabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Nayifat',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ar', 'SA'),
          ],
          theme: ThemeData(
            primaryColor: const Color(0xFF1B3E6C), // Nayifat blue
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B3E6C),
              secondary: const Color(0xFF00A650), // Nayifat green
              onPrimary: Colors.white,
              primary: const Color(0xFF1B3E6C),
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1B3E6C),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                // Loading overlay - only show after splash screen
                Consumer<ContentUpdateService>(
                  builder: (context, service, _) {
                    // Don't show overlay if we're on splash screen
                    if (!service.isUpdating || child is SplashScreen) return const SizedBox.shrink();
                    return Container(
                      color: const Color(0xFF1B3E6C).withOpacity(0.8), // 70% opacity primary color
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (_, child) {
                            return Transform.rotate(
                              angle: _animationController.value * 4 * 3.14159265,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/nayifatlogocircle-nobg.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          home: SplashScreen(isDarkMode: themeProvider.isDarkMode),
          routes: {
            '/loading': (context) => LoadingScreen(isArabic: isArabic),
            '/home': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
              return FutureBuilder<bool>(
                future: ThemeService.isDarkMode(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  final isDark = snapshot.data ?? args['isDarkMode'] ?? false;
                  // Update ThemeProvider with the current theme
                  Provider.of<ThemeProvider>(context, listen: false).setDarkMode(isDark);
                  // Return the new MainPage which will handle the theme switching
                  return MainPage(
                    isArabic: isArabic,
                    userData: const {},
                    onLanguageChanged: _handleLanguageChange,
                  );
                },
              );
            },
            '/UserDetailsScreen': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return UserDetailsScreen(
                isArabic: isArabic,
                formData: args,
              );
            },
            '/loanCalculation': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return LoanCalculationScreen(
                formData: args,
                isArabic: isArabic,
              );
            },
            '/loans': (context) => isArabic ? const LoansPageAr() : const LoansPage(),
            '/cards': (context) => isArabic ? const CardsPageAr() : const CardsPage(),
            '/support': (context) => CustomerServiceScreen(isArabic: isArabic),
            '/account': (context) => AccountPage(isArabic: isArabic),
            '/calculator': (context) => isArabic ? const LoanCalculatorPageAr() : const LoanCalculatorPage(),
          },
        );
      },
    );
  }
}
