import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/content_update_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;

  const SplashScreen({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _startAnimations = false;
  String? _pendingNotificationRoute;
  bool? _pendingNotificationIsArabic;

  @override
  void initState() {
    super.initState();
    // Update theme state immediately
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (themeProvider.isDarkMode != widget.isDarkMode) {
        themeProvider.setDarkMode(widget.isDarkMode);
        await ThemeService.setDarkMode(widget.isDarkMode); // Save to storage
      }
    });
    _checkForPendingNotification();
    _initializeApp();
  }

  Future<void> _checkForPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingNotificationRoute = prefs.getString('pending_notification_route');
      _pendingNotificationIsArabic = prefs.getBool('pending_notification_is_arabic');
      
      // Clear the pending notification data
      if (_pendingNotificationRoute != null) {
        await prefs.remove('pending_notification_route');
        await prefs.remove('pending_notification_is_arabic');
        debugPrint('Found pending notification route: $_pendingNotificationRoute');
      }
    } catch (e) {
      debugPrint('Error checking pending notification: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Start animations after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _startAnimations = true;
      });

      // 💡 Initialize content service and load initial content
      final contentService = Provider.of<ContentUpdateService>(context, listen: false);
      
      // First try to load cached content or default content
      await contentService.initializeContent();
      
      // Wait for minimum animation time
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        // Navigate to main page
        _navigateToMainPage(widget.isDarkMode);
        
        // Start background update after navigation
        Future.microtask(() {
          contentService.checkAndUpdateContent(force: false, isInitialLoad: false, isResumed: true);
        });
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      if (mounted) {
        // Navigate even on error, app will use default content
        _navigateToMainPage(widget.isDarkMode);
      }
    }
  }

  Future<void> _saveLanguagePreference(bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isArabic', isArabic);
  }

  Future<bool> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isArabic') ?? false; // Default to English if not set
  }

  void _navigateToMainPage(bool isDarkMode) async {
    final savedIsArabic = await _loadSavedLanguage();
    
    // If we have a pending notification route, use its language setting
    final isArabic = _pendingNotificationIsArabic ?? savedIsArabic;
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(
            isArabic: isArabic,
            onLanguageChanged: (bool newValue) {
              // Handle language change
            },
            userData: {},
            isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode ? Colors.black : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: _startAnimations
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Text Logo
                    if (_startAnimations) 
                      ClipRRect(
                        child: Image.asset(
                          'assets/images/nayifatlogowords-nobg.png',
                          width: 200,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ).animate()
                      .then(delay: 3000.ms)
                      .moveX(
                        begin: 100,
                        end: -55,
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      )
                      .then(delay: 2000.ms),
                      
                    // Background color overlay box
                    Transform.translate(
                      offset: Offset(87, 0), // Positions the background color overlay box 101 pixels to the right
                      child: Container(
                        width: 210,
                        height: 120,
                        color: backgroundColor,
                      ),
                    ).animate()
                    .then(delay: 3000.ms)
                    .moveX(
                      begin: 0,
                      end: 50,
                      duration: 500.ms,
                      curve: Curves.easeInOut,
                    )
                    .then(delay: 2000.ms),
                    
                    // Circle Logo (original animation)
                    ClipRRect(
                      child: Image.asset(
                        'assets/images/nayifatlogocircle-nobg.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ).animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(6.0, 6.0),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .then(delay: 2000.ms)
                    .rotate(
                      duration: 500.ms,
                      begin: 0,
                      end: 2,
                      curve: Curves.easeInOut,
                    )
                    .moveX(
                      begin: 0,
                      end: 70,
                      duration: 500.ms,
                      curve: Curves.easeInOut,
                    )
                    .then(delay: 2000.ms),
                  ],
                )
              : const SizedBox(),
        ),
      ),
    );
  }
}