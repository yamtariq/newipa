import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/slide.dart';
import '../models/contact_details.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/content_update_service.dart';
import '../widgets/slide_media.dart';
import 'registration_page.dart';
import 'auth/sign_in_page.dart';
import 'auth/sign_in_screen.dart';
import 'loan_calculator_page.dart';
import 'map_with_branches.dart';
import 'customer_service_screen.dart';
import 'cards_page.dart';
import 'loans_page.dart';
import 'account_page.dart';
import 'apply_now_loans.dart';
import 'loan_application/loan_application_start_screen.dart';
import 'card_application/card_application_start_screen.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:async';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../services/theme_service.dart';
// Arabic versions
import 'registration_page_ar.dart';
import 'auth/sign_in_page_ar.dart';
import 'loan_calculator_page_ar.dart';
import 'cards_page_ar.dart';
import 'loans_page_ar.dart';
import 'account_page_ar.dart';
import 'application_landing_screen.dart';
import '../providers/theme_provider.dart';
import 'main_page_white.dart';
import 'splash_screen.dart';

class MainPageDark extends StatefulWidget {
  final bool isArabic;
  final Function(bool)? onLanguageChanged;
  final Map<String, dynamic> userData;

  const MainPageDark({
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
  State<MainPageDark> createState() => _MainPageDarkState();
}

class _MainPageDarkState extends State<MainPageDark> with WidgetsBindingObserver {
  final ContentUpdateService _contentUpdateService = ContentUpdateService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final List<Future<void>> _mediaPreloadFutures = [];
  Timer? _notificationTimer;
  bool _isLoading = true;
  bool _isOffline = false;
  List<Slide> _slides = [];
  ContactDetails? _contactDetails;
  
  // Add back missing properties
  String? userName;
  bool isDeviceRegistered = false;
  int _tabIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationService.setLanguage(widget.isArabic);
    _initializeApp();
    _loadData();
    _initializeUserData();
    _checkDeviceRegistration();
    
    // Initialize notifications and start periodic checks
    _initializeNotifications();

    // Listen to content updates
    _contentUpdateService.addListener(_onContentUpdated);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    _contentUpdateService.removeListener(_onContentUpdated);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only handle notifications here, content updates are managed in main.dart
    if (state == AppLifecycleState.resumed) {
      _checkDeviceRegistration();
    }
  }

  // Add content update listener callback
  void _onContentUpdated() {
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      debugPrint('\n=== Initializing Notifications ===');
      
      // First check if notifications are allowed
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('Notification permissions status: ${isAllowed ? 'GRANTED' : 'NOT GRANTED'}');
      
      if (!isAllowed) {
        debugPrint('Requesting notification permissions...');
        final userAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
        debugPrint('User ${userAllowed ? 'GRANTED' : 'DENIED'} notification permissions');
        
        if (!userAllowed) {
          debugPrint('Notification permissions denied');
          return;
        }
      }

      // Check for notifications immediately
      await _checkForNotifications();
      
      // Set up periodic checks every 5 minutes
      _notificationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
        await _checkForNotifications();
      });
      
      debugPrint('=== Notification Initialization Complete ===\n');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _checkForNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id');
      if (nationalId != null) {
        debugPrint('Checking notifications for ID: $nationalId');
        final notifications = await _notificationService.fetchNotifications(nationalId);
        
        if (notifications.isNotEmpty) {
          for (final notification in notifications) {
            String title;
            String body;
            
            if (widget.isArabic) {
              title = notification['title_ar'] ?? notification['title'] ?? 'إشعار من النايفات';
              body = notification['body_ar'] ?? notification['body'] ?? '';
            } else {
              title = notification['title_en'] ?? notification['title'] ?? 'Nayifat Notification';
              body = notification['body_en'] ?? notification['body'] ?? '';
            }

            await _notificationService.showNotification(
              title: title,
              body: body,
              payload: jsonEncode({
                'route': notification['route'],
                'data': {
                  'isArabic': widget.isArabic,
                  ...notification['additionalData'] ?? {},
                },
              }),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check session when dependencies change or when mounted
    Provider.of<SessionProvider>(context, listen: false).checkSession();
  }

  Future<void> _initializeApp() async {
    // Remove redundant content check since it's handled elsewhere
    
    // Continue with other initializations
    // ... existing code ...
  }

  void _initializeUserData() async {
    try {
      final storedUserData = await _authService.getUserData();

      if (storedUserData != null) {
        setState(() {
          String fullName = widget.isArabic
              ? (storedUserData['arabic_name'] ??
                  storedUserData['full_name'] ??
                  storedUserData['name'] ??
                  '')
              : (storedUserData['full_name'] ??
                  storedUserData['name'] ??
                  storedUserData['arabic_name'] ??
                  '');
          // Get first name and ensure it uses Roboto font
          userName = fullName.split(' ')[0];
        });
      }
    } catch (e) {
      print('Error initializing user data: $e');
    }
  }

  Future<void> _checkDeviceRegistration() async {
    try {
      final isDeviceReg = await _authService.isDeviceRegistered();
      setState(() {
        isDeviceRegistered = isDeviceReg;
      });
    } catch (e) {
      print('Error checking device registration: $e');
    }
  }

  Future<void> _handleSignOff() async {
    try {
      print('\n=== SIGN OFF SEQUENCE START ===');
      print('1. Sign Off button clicked');

      // First clear auth service data
      print('2. Calling AuthService.signOff()');
      await _authService.signOff();
      print('3. AuthService.signOff() completed');

      // Then update the session provider
      print('4. Calling SessionProvider.signOff()');
      await Provider.of<SessionProvider>(context, listen: false).signOff();
      print('5. SessionProvider.signOff() completed');

      print('6. Sign Off sequence completed successfully');
      print('=== SIGN OFF SEQUENCE END ===\n');
    } catch (e) {
      print('ERROR in Sign Off sequence: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ أثناء تسجيل الخروج'
                  : 'Error signing off: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOutDevice() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red[700],
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isArabic ? 'تأكيد تسجيل الخروج' : 'Confirm Sign Out',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  widget.isArabic
                      ? 'هل أنت متأكد أنك تريد تسجيل الخروج من هذا الجهاز؟'
                      : 'Are you sure you want to sign out this device?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isArabic
                      ? 'سيؤدي هذا إلى إزالة جميع بيانات المصادقة.'
                      : 'This will remove all authentication data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: Text(
                        widget.isArabic ? 'تسجيل الخروج' : 'Sign Out',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: Text(
                        widget.isArabic ? 'إلغاء' : 'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await _authService.signOutDevice();
        await Provider.of<SessionProvider>(context, listen: false).signOff();
        setState(() {
          userName = null;
          isDeviceRegistered = false;
        });

        // Refresh the page to show non-authenticated state
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPageDark(
                isArabic: widget.isArabic,
                onLanguageChanged: widget.onLanguageChanged,
                userData: {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic
                ? 'حدث خطأ أثناء تسجيل الخروج'
                : 'Error signing out device: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _preloadMedia(List<Slide> slides) async {
    for (var slide in slides) {
      _mediaPreloadFutures
          .add(precacheImage(NetworkImage(slide.imageUrl), context));
    }
    await Future.wait(_mediaPreloadFutures);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Get slides and contact details from content service
      _slides = _contentUpdateService.getSlides(isArabic: widget.isArabic);
      _contactDetails = _contentUpdateService.getContactDetails(isArabic: widget.isArabic);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOffline = true;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _launchEmail() {
    _launchUrl('mailto:CustomerCare@nayifat.com');
  }

  void _launchPhone() {
    _launchUrl('tel:8001000088');
  }

  void _navigateToPage(String route) async {
    if (route.isEmpty) return;

    if (route.startsWith('http://') || route.startsWith('https://')) {
      // Handle external URLs
      _launchUrl(route);
    } else {
      // Special handling for sign-in route
      if (route.toLowerCase() == '/signin') {
        bool startWithPassword = true; // Default to password screen

        if (isDeviceRegistered) {
          // Check biometric and MPIN settings
          final isBiometricEnabled = await _authService.isBiometricEnabled();
          final isMPINSet = await _authService.isMPINSet();

          // If either biometric or MPIN is set up, don't start with password screen
          startWithPassword = !(isBiometricEnabled || isMPINSet);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => widget.isArabic
                ? SignInPageAr(startWithPassword: startWithPassword)
                : SignInPage(startWithPassword: startWithPassword),
          ),
        );
        return;
      }

      // Handle other internal routes - using lowercase routes to match API response
      final routeMap = widget.isArabic
          ? {
              '/loans': const LoansPageAr(),
              '/cards': const CardsPageAr(),
              '/support': const CustomerServiceScreen(isArabic: true),
              '/account': const AccountPage(),
              '/calculator': const LoanCalculatorPageAr(),
              '/branches': MapWithBranchesScreen(isArabic: true),
              '/register': RegistrationPageAr(),
              '/offers': const CustomerServiceScreen(isArabic: true),
              '/apply': NationalIdScreen(),
            }
          : {
              '/loans': const LoansPage(),
              '/cards': const CardsPage(),
              '/support': const CustomerServiceScreen(isArabic: false),
              '/account': const AccountPage(),
              '/calculator': const LoanCalculatorPage(),
              '/branches': MapWithBranchesScreen(isArabic: false),
              '/register': RegistrationPage(),
              '/offers': const CustomerServiceScreen(isArabic: false),
              '/apply': NationalIdScreen(),
            };

      // Convert route to lowercase for case-insensitive matching
      final page = routeMap[route.toLowerCase()];
      if (page != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      } else {
        // Show a snackbar for unhandled routes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route not found: $route')),
        );
      }
    }
  }

  Future<void> _saveLanguagePreference(bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isArabic', isArabic);
  }

  void _toggleLanguage() async {
    // Save the new language preference
    await _saveLanguagePreference(!widget.isArabic);
    
    widget.onLanguageChanged?.call(!widget.isArabic);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainPageDark(
          isArabic: !widget.isArabic,
          onLanguageChanged: widget.onLanguageChanged,
          userData: widget.userData,
        ),
      ),
    );
  }

  Future<void> _launchSocialLink(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      // Handle error, maybe show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  Widget _buildSocialLinks({Color? color, double iconSize = 20}) {
    if (_contactDetails == null) return const SizedBox.shrink();

    final Map<String, IconData> socialIcons = {
      'linkedin': FontAwesomeIcons.linkedinIn,
      'instagram': FontAwesomeIcons.instagram,
      'twitter': FontAwesomeIcons.xTwitter,
      'facebook': FontAwesomeIcons.facebookF,
    };

    // Define fixed order for social media links
    final orderedSocialKeys = ['linkedin', 'instagram', 'twitter', 'facebook'];

    return Directionality(
      // Force LTR for social icons regardless of app language
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: orderedSocialKeys.asMap().entries.map((entry) {
          final key = entry.value;
          final isLast = entry.key == orderedSocialKeys.length - 1;
          final url = _contactDetails!.socialLinks[key] ?? '';
          if (url.isEmpty) return const SizedBox.shrink();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: FaIcon(socialIcons[key] ?? FontAwesomeIcons.link),
                onPressed: () => _launchSocialLink(url),
                color: color ?? Theme.of(context).primaryColor,
                iconSize: iconSize,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              // Add separator if not the last item and next item exists
              if (!isLast && _contactDetails!.socialLinks[orderedSocialKeys[entry.key + 1]]?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '|',
                    style: TextStyle(
                      color: color ?? Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        }).where((widget) => widget is! SizedBox).toList(),
      ),
    );
  }

  Widget _buildAuthButtons() {
    final isSignedIn = context.watch<SessionProvider>().isSignedIn;

    if (isSignedIn) {
      // Only show Sign Off button when session is active
      return TextButton(
        onPressed: _handleSignOff,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          widget.isArabic ? 'تسجيل خروج' : 'Sign Off',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      );
    } else if (isDeviceRegistered) {
      // Show both Sign In and Sign Out Device buttons when device is registered but session is inactive
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _navigateToPage('/signin'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              widget.isArabic ? 'دخول' : 'SignIn',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _handleSignOutDevice,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              widget.isArabic ? 'خروج' : 'SignOut',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    } else {
      // Show both Sign In and Register buttons when device is not registered
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _navigateToPage('/signin'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              widget.isArabic ? 'دخول' : 'Sign In',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _navigateToPage('/register'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              widget.isArabic ? 'تسجيل' : 'Register',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: widget.isArabic ? 'مرحباً ' : 'Welcome ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
                if (userName != null)
                  TextSpan(
                    text: userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    debugPrint('\n=== Checking Server Notifications ===');
    
    try {
      // Get user ID
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id');
      
      if (nationalId == null) {
        debugPrint('No national ID found in preferences');
        return;
      }

      debugPrint('Checking notifications for ID: $nationalId');
      final NotificationService notificationService = NotificationService();
      final notifications = await notificationService.fetchNotifications(nationalId);

      debugPrint('Found ${notifications.length} notifications');
      if (notifications.isEmpty) {
        debugPrint('No notifications found');
        return;
      }

      // Display each notification
      for (final notification in notifications) {
        debugPrint('Displaying notification: ${notification['title']}');
        
        // Get the appropriate title and body based on language
        String title;
        String body;
        
        if (widget.isArabic) {
          title = notification['title_ar'] ?? notification['title'] ?? 'إشعار من النايفات';
          body = notification['body_ar'] ?? notification['body'] ?? '';
        } else {
          title = notification['title_en'] ?? notification['title'] ?? 'Nayifat Notification';
          body = notification['body_en'] ?? notification['body'] ?? '';
        }

        debugPrint('Using localized content:');
        debugPrint('Title: $title');
        debugPrint('Body: $body');

        await _notificationService.showNotification(
          title: title,
          body: body,
          payload: jsonEncode({
            'route': notification['route'],
            'data': {
              'isArabic': widget.isArabic,
              ...notification['additionalData'] ?? {},
            },
          }),
        );
      }
      
    } catch (e, stackTrace) {
      debugPrint('ERROR: Failed to check notifications');
      debugPrint('Error details: $e');
      debugPrint('Stack trace:\n$stackTrace');
    }
    debugPrint('=== Notification Check Complete ===\n');
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar and navigation bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      // Status bar (top)
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      // Navigation bar (bottom)
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final primaryColor = const Color(0xFF0077B6);
    final secondaryColor = const Color(0xFF00B4D8);

    final content = Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top Card Section
                      Material(
                        elevation: 8,
                        color: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Logo
                                Positioned(
                                  top: -30,
                                  left: -50,
                                  child: Image.asset(
                                    'assets/images/nayifat-circle-grey.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                ),
                                // Language toggle - separate from logo
                                Positioned(
                                  top: 16,
                                  left: 45,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    child: TextButton(
                                      onPressed: _toggleLanguage,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        widget.isArabic ? 'EN' : 'عربي',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Main content
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 1),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Top row with auth buttons
                                      Directionality(
                                        textDirection: TextDirection.ltr,  // Force LTR for this row
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Empty space for logo alignment
                                            const SizedBox(width: 10),
                                            // Centered username
                                            if (userName != null)
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => widget.isArabic
                                                          ? const AccountPage(isArabic: true)
                                                          : const AccountPage(isArabic: false),
                                                    ),
                                                  );
                                                },
                                                child: RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: widget.isArabic ? 'مرحباً ' : 'Welcome ',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontFamily: 'Roboto',
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: userName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'Roboto',
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            // Auth buttons
                                            Container(
                                              margin: EdgeInsets.zero,
                                              padding: EdgeInsets.zero,
                                              child: Directionality(
                                                textDirection: TextDirection.ltr,
                                                child: _buildAuthButtons(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Centered company logo
                                      Center(
                                        child: Image.asset(
                                          'assets/images/nayifat-logo-no-bg.png',
                                          height: screenHeight * 0.08,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Contact Info
                                      if (_contactDetails != null)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Phone and Email in one line
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Phone
                                                GestureDetector(
                                                  onTap: _launchPhone,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.phone, color: Colors.grey[400], size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _contactDetails!.phone,
                                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Separator
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    '|',
                                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                  ),
                                                ),
                                                // Email
                                                GestureDetector(
                                                  onTap: _launchEmail,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.email, color: Colors.grey[400], size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _contactDetails!.email,
                                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Social Media Links with smaller icons
                                            _buildSocialLinks(color: Colors.grey, iconSize: 16),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Rest of the content remains unchanged
                      const SizedBox(height: 48),

                      

                      // Apply for Product Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final isSignedIn =
                                      Provider.of<SessionProvider>(context,
                                              listen: false)
                                          .isSignedIn;
                                  if (isSignedIn) {
                                    // For signed-in users, navigate to the original application screens
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LoanApplicationStartScreen(
                                              isArabic: widget.isArabic,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // For non-signed-in users, show dialog and navigate to landing page
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  24, 0, 24, 24),
                                          title: Column(
                                            children: [
                                              const SizedBox(height: 16),
                                              Icon(
                                                Icons.account_circle_outlined,
                                                color: primaryColor,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                widget.isArabic
                                                    ? 'مرحباً بك في النايفات'
                                                    : 'Welcome to Nayifat',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: widget.isArabic
                                                    ? TextAlign.center
                                                    : TextAlign.center,
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            widget.isArabic
                                                ? 'للحصول على تجربة أفضل وتتبع طلبك بسهولة، نوصي بالتسجيل أو تسجيل الدخول. هل تريد المتابعة؟'
                                                : 'For a better experience and easy tracking of your application, we recommend registering or signing in. Would you like to proceed?',
                                            textAlign: widget.isArabic
                                                ? TextAlign.center
                                                : TextAlign.center,
                                          ),
                                          actionsAlignment:
                                              MainAxisAlignment.center,
                                          actions: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ApplicationLandingScreen(
                                                        isArabic: widget.isArabic,
                                                        isLoanApplication: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'المتابعة بدون تسجيل'
                                                      : 'Continue Without Signing In',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SignInScreen(
                                                        isArabic: widget.isArabic,
                                                        startWithPassword: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                    side: BorderSide(
                                                        color: primaryColor),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'تسجيل الدخول'
                                                      : 'Sign In',
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          widget.isArabic
                                                              ? RegistrationPageAr()
                                                              : RegistrationPage(),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'تسجيل'
                                                      : 'Register',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'إلغاء'
                                                      : 'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: const BorderSide(color: Colors.black),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  widget.isArabic
                                      ? 'أحصل على تمويلك الآن'
                                      : 'Apply for Loan',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final isSignedIn =
                                      Provider.of<SessionProvider>(context,
                                              listen: false)
                                          .isSignedIn;
                                  if (isSignedIn) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CardApplicationStartScreen(
                                              isArabic: widget.isArabic,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // For non-signed-in users, show dialog and navigate to landing page
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  24, 0, 24, 24),
                                          title: Column(
                                            children: [
                                              const SizedBox(height: 16),
                                              Icon(
                                                Icons.account_circle_outlined,
                                                color: primaryColor,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                widget.isArabic
                                                    ? 'مرحباً بك في النايفات'
                                                    : 'Welcome to Nayifat',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: widget.isArabic
                                                    ? TextAlign.center
                                                    : TextAlign.center,
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            widget.isArabic
                                                ? 'للحصول على تجربة أفضل وتتبع طلبك بسهولة، نوصي بالتسجيل أو تسجيل الدخول. هل تريد المتابعة؟'
                                                : 'For a better experience and easy tracking of your application, we recommend registering or signing in. Would you like to proceed?',
                                            textAlign: widget.isArabic
                                                ? TextAlign.center
                                                : TextAlign.center,
                                          ),
                                          actionsAlignment:
                                              MainAxisAlignment.center,
                                          actions: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ApplicationLandingScreen(
                                                        isArabic: widget.isArabic,
                                                        isLoanApplication: false,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'المتابعة بدون تسجيل'
                                                      : 'Continue Without Signing In',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SignInScreen(
                                                        isArabic: widget.isArabic,
                                                        startWithPassword: true,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                    side: BorderSide(
                                                        color: primaryColor),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'تسجيل الدخول'
                                                      : 'Sign In',
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          widget.isArabic
                                                              ? RegistrationPageAr()
                                                              : RegistrationPage(),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'تسجيل'
                                                      : 'Register',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                ),
                                                child: Text(
                                                  widget.isArabic
                                                      ? 'إلغاء'
                                                      : 'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800]!.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(color: Colors.grey[800]!),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  widget.isArabic
                                      ? 'أحصل على بطاقتك الآن'
                                      : 'Apply for Card',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Loan Calculator Container (Smaller version)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => widget.isArabic
                                    ? const LoanCalculatorPageAr()
                                    : const LoanCalculatorPage(),
                              ),
                            );
                          },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey[800]!.withOpacity(0.3)),
                            ),
                            child: Row(
                              textDirection: widget.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              children: [
                                Container(
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800]!.withOpacity(0.1),
                                    borderRadius: BorderRadius.horizontal(
                                      left: widget.isArabic
                                          ? Radius.zero
                                          : const Radius.circular(8),
                                      right: widget.isArabic
                                          ? const Radius.circular(8)
                                          : Radius.zero,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.calculate,
                                      color: Colors.grey[800],
                                      size: 36,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      widget.isArabic
                                          ? 'حاسبة التمويل'
                                          : 'Loan Calculator',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(
                                    widget.isArabic
                                        ? Icons.chevron_right
                                        : Icons.chevron_right,
                                    color: Colors.grey[800],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 170,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 16/9,
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 800),
                            viewportFraction: 0.8,
                          ),
                          items: _slides.map((slide) {
                            return Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () => _navigateToPage(slide.link),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        SlideMedia(
                                          slide: slide,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black
                                                      .withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    slide.leftTitle,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    slide.rightTitle,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (_isOffline)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      color: Colors.orange,
                      child: InkWell(
                        onTap: _loadData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isArabic
                                    ? 'أنت غير متصل بالانترنت - اضغط هنا للتحديث'
                                    : 'You are offline - Tap to refresh',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[700]!,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[900]!,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CircleNavBar(
          activeIcons: [
            Icon(Icons.headset_mic, color: Colors.grey[400]!),
            Icon(Icons.credit_card, color: Colors.grey[400]!),
            Icon(Icons.home, color: Colors.grey[400]!),
            Icon(Icons.account_balance, color: Colors.grey[400]!),
            Icon(Icons.settings, color: Colors.grey[400]!),
          ],
          inactiveIcons: [
            Icon(Icons.headset_mic, color: Colors.grey[400]!),
            Icon(Icons.credit_card, color: Colors.grey[400]!),
            Icon(Icons.home, color: Colors.grey[400]!),
            Icon(Icons.account_balance, color: Colors.grey[400]!),
            Icon(Icons.settings, color: Colors.grey[400]!),
          ],
          levels: widget.isArabic
              ? const ["الدعم", "البطاقات", "الرئيسية", "التمويل", "حسابي"]
              : const ["Support", "Cards", "Home", "Loans", "Account"],
          activeLevelsStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400]!,
          ),
          inactiveLevelsStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[400]!,
          ),
          color: Colors.black,
          height: 70,
          circleWidth: 60,
          activeIndex: _tabIndex,
          onTap: (index) {
            if (index == 2) {
              // Home tab
              setState(() {
                _tabIndex = index;
              });
              return; // Don't navigate if we're already home
            }

            // For other tabs, navigate and update index only if navigation succeeds
            Widget page;
            switch (index) {
              case 0:
                page = widget.isArabic
                    ? const CustomerServiceScreen(isArabic: true)
                    : const CustomerServiceScreen(isArabic: false);
                break;
              case 1:
                page =
                    widget.isArabic ? const CardsPageAr() : const CardsPage();
                break;
              case 3:
                page =
                    widget.isArabic ? const LoansPageAr() : const LoansPage();
                break;
              case 4:
                page = widget.isArabic
                    ? const AccountPage(isArabic: true)
                    : const AccountPage(isArabic: false);
                break;
              default:
                return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => page,
              ),
            ).then((_) {
              // When returning from other pages, set tab index back to home
              setState(() {
                _tabIndex = 2;
              });
            });
          },
          cornerRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
            bottomLeft: Radius.circular(0),
          ),
          shadowColor: Colors.transparent,
          elevation: 20,
          // gradient: LinearGradient(
          //   begin: Alignment.topRight,
          //   end: Alignment.bottomLeft,
          //   colors: [primaryColor, secondaryColor],
          // ),
        ),
      ),
    );

    return widget.isArabic
        ? Directionality(
            textDirection: TextDirection.rtl,
            child: content,
          )
        : content;
  }

  Widget _buildContactItem(
    IconData icon,
    String text, {
    double fontSize = 16,
    bool isLink = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color:
                    isLink ? (color ?? Theme.of(context).primaryColor) : null,
                decoration: isLink ? TextDecoration.underline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
