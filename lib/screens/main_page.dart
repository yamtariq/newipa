import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
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
import 'loan_application/loan_application_start_screen.dart';
import 'card_application/card_application_start_screen.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:async';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';
import '../services/theme_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
// Arabic versions
import 'registration_page_ar.dart';
import 'auth/sign_in_page_ar.dart';
import 'loan_calculator_page_ar.dart';
import 'cards_page_ar.dart';
import 'loans_page_ar.dart';
import 'account_page.dart';
import 'application_landing_screen.dart';
import 'splash_screen.dart';

class MainPage extends StatefulWidget {
  final bool isArabic;
  final Function(bool)? onLanguageChanged;
  final Map<String, dynamic> userData;
  final String? initialRoute;
  final bool isDarkMode;

  const MainPage({
    Key? key,
    required this.isArabic,
    this.onLanguageChanged,
    required this.userData,
    this.initialRoute,
    required this.isDarkMode,
  }) : super(key: key);

  static Future<bool> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isArabic') ?? false; // Default to English if not set
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
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
    
    // Add storage data logging
    _logStorageData();
    
    WidgetsBinding.instance.addObserver(this);
    _notificationService.setLanguage(widget.isArabic);
    
    // Initialize all required data
    _initializeUserData();  // Move this first
    _initializeApp();
    _loadData();
    _checkDeviceRegistration();
    
    // Initialize notifications and start periodic checks
    _initializeNotifications();

    // Listen to content updates
    _contentUpdateService.addListener(_onContentUpdated);

    // Handle initial route if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialRoute != null && widget.initialRoute!.isNotEmpty) {
        debugPrint('Handling initial route: ${widget.initialRoute}');
        _navigateToPage(widget.initialRoute!);
      }
    });
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

  Future<void> _initializeUserData() async {
    try {
      print('\n=== INITIALIZE USER DATA START ===');
      
      // Function to extract name based on language
      String extractName(Map<String, dynamic> data) {
        print('Extracting name from data: ${json.encode(data)}');
        String? firstName;
        
        if (widget.isArabic) {
          // Try Arabic name fields first
          firstName = data['firstName_ar']?.toString() ??
                     data['first_name_ar']?.toString() ??
                     data['firstNameAr']?.toString() ??
                     
                     data['firstName']?.toString();  // Added for registration data
                     
        } else {
          // Try English name fields first
          firstName = data['firstName_en']?.toString() ??
                     data['first_name_en']?.toString() ??
                     data['firstNameEn']?.toString() ??
                    
                     data['englishFirstName']?.toString();  // Added for registration data
                     
        }
        
        // If still empty, try generic field
        if (firstName == null || firstName.isEmpty) {
          firstName = data['firstName']?.toString();
        }
        
        print('Extracted firstName: $firstName');
        return firstName ?? '';
      }

      // First try widget.userData
      if (widget.userData.isNotEmpty) {
        print('\n1. Checking widget.userData:');
        print('Content: ${json.encode(widget.userData)}');
        
        String firstName = extractName(widget.userData);
        print('Extracted firstName: $firstName');
        
        if (firstName.isNotEmpty && mounted) {
          setState(() {
            userName = firstName;
            print('Set userName from widget.userData: $userName');
          });
          return;
        } else {
          print('widget.userData does not contain a valid name; falling back to secure storage.');
        }
      }
      
      // Then try secure storage
      print('\n2. Checking secure storage:');
      final storage = FlutterSecureStorage();
      final userDataStr = await storage.read(key: 'user_data');
      print('Secure storage data: $userDataStr');
      
      if (userDataStr != null) {
        final storedUserData = json.decode(userDataStr);
        String firstName = extractName(storedUserData);
        print('Extracted firstName from secure storage: $firstName');
        
        if (firstName.isNotEmpty && mounted) {
          setState(() {
            userName = firstName;
            print('Set userName from secure storage: $userName');
          });
          return;
        } else {
          print('Secure storage does not contain a valid name; falling back to SharedPreferences.');
        }
      }
      
      // Finally try SharedPreferences
      print('\n3. Checking SharedPreferences:');
      final prefs = await SharedPreferences.getInstance();
      
      // First check registration data which contains user details
      final registrationDataStr = prefs.getString('registration_data');
      if (registrationDataStr != null) {
        try {
          final registrationData = json.decode(registrationDataStr);
          if (registrationData['userData'] != null) {
            final userData = registrationData['userData'];
            String firstName = widget.isArabic ? 
                userData['firstName']?.toString() ?? '' :
                userData['englishFirstName']?.toString() ?? '';
                
            print('Extracted firstName from registration data: $firstName');
            
            if (firstName.isNotEmpty && mounted) {
              setState(() {
                userName = firstName;
                print('Set userName from registration data: $userName');
              });
              return;
            }
          }
        } catch (e) {
          print('Error parsing registration data: $e');
        }
      }
      
      // Then check regular user_data
      final prefsUserDataStr = prefs.getString('user_data');
      print('SharedPreferences data: $prefsUserDataStr');
      
      if (prefsUserDataStr != null) {
        final storedUserData = json.decode(prefsUserDataStr);
        String firstName = extractName(storedUserData);
        print('Extracted firstName from SharedPreferences: $firstName');
        
        if (firstName.isNotEmpty && mounted) {
          setState(() {
            userName = firstName;
            print('Set userName from SharedPreferences: $userName');
          });
        }
      }
      
      print('=== INITIALIZE USER DATA END ===\n');
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

      // Update the session provider first
      print('2. Calling SessionProvider.signOff()');
      await Provider.of<SessionProvider>(context, listen: false).signOff();
      print('3. SessionProvider.signOff() completed');

      print('4. Sign Off sequence completed successfully');
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
      print('\n=== SIGN OUT SEQUENCE START ===');
      
      // Log storage data before sign out
      print('1. Checking storage data BEFORE sign out:');
      await _logStorageData();

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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isArabic
                      ? 'هل أنت متأكد من تسجيل الخروج؟'
                      : 'Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  widget.isArabic ? 'إلغاء' : 'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  widget.isArabic ? 'تأكيد' : 'Confirm',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        print('\n2. User confirmed sign out - proceeding with sign out sequence');
        
        // Update session provider state first
        if (mounted) {
          print('3. Updating SessionProvider state');
          final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
          sessionProvider.setSignedIn(false);
          sessionProvider.setManualSignOff(true);
        }
        
        // Then sign out completely using auth service
        print('4. Calling AuthService.signOut()');
        await _authService.signOut();
        
        print('\n5. Checking storage data AFTER sign out:');
        await _logStorageData();
        
        // Update local state
        if (mounted) {
          print('6. Updating local state');
          setState(() {
            userName = null;
            isDeviceRegistered = false;
          });

          print('7. Navigating to fresh MainPage');
          // Refresh the main page with empty user data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(
                isArabic: widget.isArabic,
                onLanguageChanged: widget.onLanguageChanged,
                userData: {},
                isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              ),
            ),
          );
        }
        print('=== SIGN OUT SEQUENCE COMPLETE ===\n');
      } else {
        print('Sign out cancelled by user');
      }
    } catch (e, stackTrace) {
      print('ERROR during sign out sequence: $e');
      print('Stack trace:\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ أثناء تسجيل الخروج'
                  : 'Error signing out: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          if (isBiometricEnabled || isMPINSet) {
            startWithPassword = false;
          }
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignInScreen(
                isArabic: widget.isArabic,
                startWithPassword: startWithPassword,
              ),
            ),
          );
        }
        return;
      }

      // Handle other internal routes - using lowercase routes to match API response
      final routeMap = widget.isArabic
          ? {
              '/loans': (BuildContext context) => const LoansPageAr(),
              '/cards': (BuildContext context) => const CardsPageAr(),
              '/support': (BuildContext context) => const CustomerServiceScreen(isArabic: true),
              '/account': (BuildContext context) => const AccountPage(isArabic: true),
              '/calculator': (BuildContext context) => const LoanCalculatorPageAr(),
              '/branches': (BuildContext context) => MapWithBranchesScreen(isArabic: true),
              '/register': (BuildContext context) => RegistrationPageAr(),
              '/offers': (BuildContext context) => const CustomerServiceScreen(isArabic: true),
              '/loan-application': (BuildContext context) => const LoanApplicationStartScreen(),
              '/card-application': (BuildContext context) => const CardApplicationStartScreen(),
            }
          : {
              '/loans': (BuildContext context) => const LoansPage(),
              '/cards': (BuildContext context) => const CardsPage(),
              '/support': (BuildContext context) => const CustomerServiceScreen(isArabic: false),
              '/account': (BuildContext context) => const AccountPage(isArabic: false),
              '/calculator': (BuildContext context) => const LoanCalculatorPage(),
              '/branches': (BuildContext context) => MapWithBranchesScreen(isArabic: false),
              '/register': (BuildContext context) => RegistrationPage(),
              '/offers': (BuildContext context) => const CustomerServiceScreen(isArabic: false),
              '/loan-application': (BuildContext context) => const LoanApplicationStartScreen(),
              '/card-application': (BuildContext context) => const CardApplicationStartScreen(),
            };

      // Convert route to lowercase for case-insensitive matching
      final pageBuilder = routeMap[route.toLowerCase()];
      if (pageBuilder != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: pageBuilder,
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
        builder: (context) => MainPage(
          isArabic: !widget.isArabic,
                onLanguageChanged: widget.onLanguageChanged,
                userData: widget.userData,
                isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
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

  Widget _buildSocialLinks({Color? color}) {
    if (_contactDetails == null) return const SizedBox.shrink();

    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = color ?? Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);

    final Map<String, IconData> socialIcons = {
      'linkedin': FontAwesomeIcons.linkedinIn,
      'instagram': FontAwesomeIcons.instagram,
      'twitter': FontAwesomeIcons.xTwitter,
      'facebook': FontAwesomeIcons.facebookF,
    };

    // Define fixed order for social media links
    final orderedSocialKeys = ['linkedin', 'instagram', 'twitter', 'facebook'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection:
          TextDirection.ltr, // Always keep LTR order for social icons
      children: orderedSocialKeys
          .map((key) {
            final url = _contactDetails!.socialLinks[key] ?? '';
            if (url.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: FaIcon(socialIcons[key] ?? FontAwesomeIcons.link),
                onPressed: () => _launchSocialLink(url),
                color: themeColor,
                iconSize: 20,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            );
          })
          .where((widget) => widget is! SizedBox)
          .toList(),
    );
  }

  Widget _buildWelcomeSection() {
    final isSignedIn = context.watch<SessionProvider>().isSignedIn;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = Color(isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: widget.isArabic ? 'مرحباً ' : 'Welcome ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: textColor,
                  ),
                ),
                if (userName != null)
                  TextSpan(
                    text: userName!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ),
          _buildAuthButtons(),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Update colors to use Constants
    final primaryColor = Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final backgroundColor = Color(isDarkMode 
        ? Constants.darkBackgroundColor 
        : Constants.lightBackgroundColor);
    final surfaceColor = Color(isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintTextColor = Color(isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);
    final borderColor = Color(isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);

    // Update dialog styles
    final dialogBackgroundColor = surfaceColor;
    final dialogTextColor = textColor;

    // Update shadow colors
    final shadowColor = Color(isDarkMode 
        ? Constants.darkNavbarShadowPrimary 
        : Constants.lightNavbarShadowPrimary);
    final navShadowColor = Color(isDarkMode 
        ? Constants.darkNavbarShadowSecondary 
        : Constants.lightNavbarShadowSecondary);

    final content = Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _toggleLanguage,
                                      icon: Icon(Icons.language, color: primaryColor),
                                  label: Text(
                                    widget.isArabic ? 'English' : 'عربي',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                    ),
                                    Consumer<ThemeProvider>(
                                      builder: (context, themeProvider, child) {
                                        return IconButton(
                                          icon: Icon(
                                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                            color: primaryColor,
                                          ),
                                          onPressed: () async {
                                            await themeProvider.toggleTheme();
                                            if (mounted) {
                                              setState(() {});
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/nayifat-logo-no-bg.png',
                                      height: screenHeight * 0.06,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Welcome and Sign In Section
                        _buildWelcomeSection(),

                        Divider(height: 2, color: borderColor),

                        // Carousel Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 180,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              aspectRatio: 16 / 9,
                              autoPlayCurve: Curves.fastOutSlowIn,
                              enableInfiniteScroll: true,
                              autoPlayAnimationDuration: const Duration(milliseconds: 800),
                              viewportFraction: 0.8,
                            ),
                            items: _slides.map((slide) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return GestureDetector(
                                    onTap: () => _navigateToPage(slide.link),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                      decoration: BoxDecoration(
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
                                          if (slide.leftTitle.isNotEmpty || slide.rightTitle.isNotEmpty)
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
                                                      Colors.black.withOpacity(0.7),
                                                    ],
                                                  ),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 16,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    if (slide.leftTitle.isNotEmpty)
                                                      Expanded(
                                                        child: Text(
                                                          slide.leftTitle,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    if (slide.rightTitle.isNotEmpty)
                                                      Text(
                                                        slide.rightTitle,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
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

                        // Apply for Product Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final hasActiveSession = Provider.of<SessionProvider>(context, listen: false).hasActiveSession;
                                    if (hasActiveSession) {
                                      await _handleApplicationStart(isLoanApplication: true);
                                    } else {
                                      // For users without active session, shows dialog with options
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                              decoration: BoxDecoration(
                                                color: Color(isDarkMode 
                                                    ? Constants.darkSurfaceColor 
                                                    : Constants.lightSurfaceColor),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Color(isDarkMode 
                                                      ? Constants.darkFormBorderColor 
                                                      : Constants.lightFormBorderColor),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 15,
                                                    spreadRadius: -8,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Header with Icon
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    margin: const EdgeInsets.only(top: 24, bottom: 16),
                                                    decoration: BoxDecoration(
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkPrimaryColor 
                                                          : Constants.lightPrimaryColor).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.account_circle_outlined,
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkPrimaryColor 
                                                          : Constants.lightPrimaryColor),
                                                      size: 48,
                                                    ),
                                                  ),
                                                  
                                                  // Title
                                                  Text(
                                                    widget.isArabic
                                                        ? 'مرحباً بك في النايفات'
                                                        : 'Welcome to Nayifat',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkLabelTextColor 
                                                          : Constants.lightLabelTextColor),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  
                                                  // Description
                                                  Text(
                                                    widget.isArabic
                                                        ? 'يمكنك التقدم بطلب تمويل مباشرة أو تسجيل الدخول للحصول على تجربة أفضل ومتابعة طلبك بسهولة'
                                                        : 'You can apply for a loan directly or sign in for a better experience and easy application tracking',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkHintTextColor 
                                                          : Constants.lightHintTextColor),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  
                                                  // Buttons Section
                                                  Column(
                                                    children: [
                                                      if (!isDeviceRegistered) ...[
                                                        // Register Button
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            _navigateToPage('/register');
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Color(isDarkMode 
                                                                ? Constants.darkPrimaryColor 
                                                                : Constants.lightPrimaryColor),
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            elevation: 0,
                                                            minimumSize: const Size(double.infinity, 0),
                                                          ),
                                                          child: Text(
                                                            widget.isArabic ? 'تسجيل جديد' : 'Register',
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 12),
                                                      ],
                                                      
                                                      // Sign In Button
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          _navigateToPage('/signin');
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.transparent,
                                                          foregroundColor: Color(isDarkMode 
                                                              ? Constants.darkPrimaryColor 
                                                              : Constants.lightPrimaryColor),
                                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            side: BorderSide(
                                                              color: Color(isDarkMode 
                                                                  ? Constants.darkPrimaryColor 
                                                                  : Constants.lightPrimaryColor),
                                                            ),
                                                          ),
                                                          elevation: 0,
                                                          minimumSize: const Size(double.infinity, 0),
                                                        ),
                                                        child: Text(
                                                          widget.isArabic ? 'تسجيل الدخول' : 'Sign In',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      
                                                      // Apply Without Signing In Button
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => ApplicationLandingScreen(
                                                                isArabic: widget.isArabic,
                                                                isLoanApplication: true,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.transparent,
                                                          foregroundColor: Color(isDarkMode 
                                                              ? Constants.darkPrimaryColor 
                                                              : Constants.lightPrimaryColor),
                                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            side: BorderSide(
                                                              color: Color(isDarkMode 
                                                                  ? Constants.darkPrimaryColor 
                                                                  : Constants.lightPrimaryColor),
                                                            ),
                                                          ),
                                                          elevation: 0,
                                                          minimumSize: const Size(double.infinity, 0),
                                                        ),
                                                        child: Text(
                                                          widget.isArabic 
                                                              ? 'تقديم طلب بدون تسجيل الدخول' 
                                                              : 'Apply Without Signing In',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: surfaceColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: BorderSide(color: primaryColor),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    widget.isArabic
                                        ? 'أحصل على تمويلك الآن'
                                        : 'Apply for Loan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? const Color(0xFF8AA4D0) : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final hasActiveSession = Provider.of<SessionProvider>(context, listen: false).hasActiveSession;
                                    if (hasActiveSession) {
                                      await _handleApplicationStart(isLoanApplication: false);
                                    } else {
                                      // For users without active session, shows dialog with options
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                              decoration: BoxDecoration(
                                                color: Color(isDarkMode 
                                                    ? Constants.darkSurfaceColor 
                                                    : Constants.lightSurfaceColor),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Color(isDarkMode 
                                                      ? Constants.darkFormBorderColor 
                                                      : Constants.lightFormBorderColor),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 15,
                                                    spreadRadius: -8,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Header with Icon
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    margin: const EdgeInsets.only(top: 24, bottom: 16),
                                                    decoration: BoxDecoration(
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkPrimaryColor 
                                                          : Constants.lightPrimaryColor).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.account_circle_outlined,
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkPrimaryColor 
                                                          : Constants.lightPrimaryColor),
                                                      size: 48,
                                                    ),
                                                  ),
                                                  
                                                  // Title
                                                  Text(
                                                    widget.isArabic
                                                        ? 'مرحباً بك في النايفات'
                                                        : 'Welcome to Nayifat',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkLabelTextColor 
                                                          : Constants.lightLabelTextColor),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  
                                                  // Description
                                                  Text(
                                                    widget.isArabic
                                                        ? 'يمكنك التقدم بطلب بطاقة مباشرة أو تسجيل الدخول للحصول على تجربة أفضل ومتابعة طلبك بسهولة'
                                                        : 'You can apply for a card directly or sign in for a better experience and easy application tracking',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Color(isDarkMode 
                                                          ? Constants.darkHintTextColor 
                                                          : Constants.lightHintTextColor),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  
                                                  // Buttons Section
                                                  Column(
                                                    children: [
                                                      if (!isDeviceRegistered) ...[
                                                        // Register Button
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            _navigateToPage('/register');
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Color(isDarkMode 
                                                                ? Constants.darkPrimaryColor 
                                                                : Constants.lightPrimaryColor),
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            elevation: 0,
                                                            minimumSize: const Size(double.infinity, 0),
                                                          ),
                                                          child: Text(
                                                            widget.isArabic ? 'تسجيل جديد' : 'Register',
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 12),
                                                      ],
                                                      
                                                      // Sign In Button
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          _navigateToPage('/signin');
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.transparent,
                                                          foregroundColor: Color(isDarkMode 
                                                              ? Constants.darkPrimaryColor 
                                                              : Constants.lightPrimaryColor),
                                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            side: BorderSide(
                                                              color: Color(isDarkMode 
                                                                  ? Constants.darkPrimaryColor 
                                                                  : Constants.lightPrimaryColor),
                                                            ),
                                                          ),
                                                          elevation: 0,
                                                          minimumSize: const Size(double.infinity, 0),
                                                        ),
                                                        child: Text(
                                                          widget.isArabic ? 'تسجيل الدخول' : 'Sign In',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      
                                                      // Apply Without Signing In Button
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => ApplicationLandingScreen(
                                                                isArabic: widget.isArabic,
                                                                isLoanApplication: false,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.transparent,
                                                          foregroundColor: Color(isDarkMode 
                                                              ? Constants.darkPrimaryColor 
                                                              : Constants.lightPrimaryColor),
                                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                            side: BorderSide(
                                                              color: Color(isDarkMode 
                                                                  ? Constants.darkPrimaryColor 
                                                                  : Constants.lightPrimaryColor),
                                                            ),
                                                          ),
                                                          elevation: 0,
                                                          minimumSize: const Size(double.infinity, 0),
                                                        ),
                                                        child: Text(
                                                          widget.isArabic 
                                                              ? 'تقديم طلب بدون تسجيل الدخول' 
                                                              : 'Apply Without Signing In',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: surfaceColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: BorderSide(color: primaryColor),
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
                                      color: isDarkMode ? const Color(0xFF8AA4D0) : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Loan Calculator Container
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
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                children: <Widget>[
                                  Container(
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.horizontal(
                                        left: widget.isArabic ? Radius.zero : const Radius.circular(8),
                                        right: widget.isArabic ? const Radius.circular(8) : Radius.zero,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.calculate,
                                        color: primaryColor,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        widget.isArabic ? 'حاسبة التمويل' : 'Loan Calculator',
                                        style: TextStyle(
                                          color: Color(isDarkMode 
                                              ? Constants.darkLabelTextColor 
                                              : Constants.lightLabelTextColor),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Icon(
                                      widget.isArabic ? Icons.chevron_left : Icons.chevron_right,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Contact Section
                        if (_contactDetails != null) ...[
                          Directionality(
                            textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Text(
                                      widget.isArabic ? 'اتصل بنا' : 'Contact Us',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                        fontSize: 16,
                                      ),
                                      textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildContactItem(
                                                Icons.phone,
                                                _contactDetails!.phone,
                                                fontSize: 13,
                                                isLink: true,
                                                color: primaryColor,
                                              ),
                                  const SizedBox(height: 8),
                                  _buildContactItem(
                                                Icons.email,
                                                _contactDetails!.email,
                                                fontSize: 13,
                                                isLink: true,
                                                color: primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapWithBranchesScreen(isArabic: widget.isArabic),
                                        ),
                                      );
                                    },
                                    child: _buildContactItem(
                                      Icons.location_on,
                                      widget.isArabic ? 'ابحث عن أقرب فرع' : 'Find Nearest Branch',
                                      fontSize: 14,
                                      isLink: true,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSocialLinks(color: primaryColor),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isOffline)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        color: Color(isDarkMode 
                            ? Constants.darkFormBackgroundColor 
                            : Constants.lightFormBackgroundColor),
                        child: InkWell(
                          onTap: _loadData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  color: Color(isDarkMode 
                                      ? Constants.darkLabelTextColor 
                                      : Constants.lightLabelTextColor),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isArabic
                                      ? 'أنت غير متصل بالانترنت - اضغط هنا للتحديث'
                                      : 'You are offline - Tap to refresh',
                                  style: TextStyle(
                                    color: Color(isDarkMode 
                                        ? Constants.darkLabelTextColor 
                                        : Constants.lightLabelTextColor),
                                    fontSize: 14,
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
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(isDarkMode 
              ? Constants.darkNavbarBackground 
              : Constants.lightNavbarBackground),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(isDarkMode 
                  ? Constants.darkNavbarGradientStart
                  : Constants.lightNavbarGradientStart),
              Color(isDarkMode 
                  ? Constants.darkNavbarGradientEnd
                  : Constants.lightNavbarGradientEnd),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(isDarkMode 
                  ? Constants.darkNavbarShadowPrimary
                  : Constants.lightNavbarShadowPrimary),
              offset: const Offset(0, -2),
              blurRadius: 6,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Color(isDarkMode 
                  ? Constants.darkNavbarShadowSecondary
                  : Constants.lightNavbarShadowSecondary),
              offset: const Offset(0, -1),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: CircleNavBar(
          activeIcons: [
            Icon(Icons.headset_mic, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarActiveIcon
                    : Constants.lightNavbarActiveIcon)),
            Icon(Icons.credit_card, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarActiveIcon
                    : Constants.lightNavbarActiveIcon)),
            Icon(Icons.home, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarActiveIcon
                    : Constants.lightNavbarActiveIcon)),
            Icon(Icons.account_balance, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarActiveIcon
                    : Constants.lightNavbarActiveIcon)),
            Icon(Icons.settings, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarActiveIcon
                    : Constants.lightNavbarActiveIcon)),
          ],
          inactiveIcons: [
            Icon(Icons.headset_mic, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarInactiveIcon
                    : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.credit_card, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarInactiveIcon
                    : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.home, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarInactiveIcon
                    : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.account_balance, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarInactiveIcon
                    : Constants.lightNavbarInactiveIcon)),
            Icon(Icons.settings, 
                color: Color(isDarkMode 
                    ? Constants.darkNavbarInactiveIcon
                    : Constants.lightNavbarInactiveIcon)),
          ],
          levels: widget.isArabic
              ? const ["الدعم", "البطاقات", "الرئيسية", "التمويل", "حسابي"]
              : const ["Support", "Cards", "Home", "Loans", "Account"],
          activeLevelsStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(isDarkMode 
                ? Constants.darkNavbarActiveText
                : Constants.lightNavbarActiveText),
          ),
          inactiveLevelsStyle: TextStyle(
            fontSize: 14,
            color: Color(isDarkMode 
                ? Constants.darkNavbarInactiveText
                : Constants.lightNavbarInactiveText),
          ),
          color: Color(isDarkMode 
              ? Constants.darkNavbarBackground 
              : Constants.lightNavbarBackground),
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
          shadowColor: shadowColor,
          elevation: 20,
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
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final textColor = Color(isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    // 💡 Determine if this is a phone or email item
    bool isPhone = icon == Icons.phone;
    bool isEmail = icon == Icons.email;

    Widget content = Row(
      children: [
        Icon(
          icon,
          color: color ?? themeColor,
          size: 20,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: isLink ? (color ?? themeColor) : textColor,
              decoration: isLink ? TextDecoration.underline : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // 💡 Wrap with GestureDetector for phone and email
    if (isPhone || isEmail) {
      return GestureDetector(
        onTap: () {
          if (isPhone) {
            _launchUrl('tel:${text.replaceAll(' ', '')}');
          } else if (isEmail) {
            _launchUrl('mailto:$text');
          }
        },
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: content,
    );
  }

  Widget _buildAuthButtons() {
    final isSignedIn = context.watch<SessionProvider>().isSignedIn;
    final hasActiveSession = context.watch<SessionProvider>().hasActiveSession;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final errorColor = Colors.red;
    final errorSurfaceColor = Color(isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);

    // Show only Sign Off when session is active
    if (hasActiveSession) {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        child: TextButton(
          onPressed: _handleSignOff,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            backgroundColor: errorSurfaceColor,
            side: BorderSide(color: errorColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            widget.isArabic ? 'تسجيل خروج' : 'Sign Off',
            style: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // Show Sign Out when signed in but no active session
    if (isSignedIn && !hasActiveSession) {
      return Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () => _navigateToPage('/signin'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                backgroundColor: surfaceColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                widget.isArabic ? 'دخول' : 'Sign In',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: _handleSignOutDevice,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                backgroundColor: errorSurfaceColor,
                side: BorderSide(color: errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                widget.isArabic ? 'خروج تام' : 'Sign Out',
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show Register and Sign In when not signed in
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: TextButton(
            onPressed: () => _navigateToPage('/signin'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: surfaceColor,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              widget.isArabic ? 'دخول' : 'Sign In',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: TextButton(
            onPressed: () => _navigateToPage('/register'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              widget.isArabic ? 'تسجيل' : 'Register',
              style: TextStyle(
                color: surfaceColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Add the logging function
  Future<void> _logStorageData() async {
    try {
      // Get SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('-----STORAGE DATA----- SharedPreferences Data:');
      for (String key in keys) {
        print('-----STORAGE DATA----- $key: ${prefs.get(key)}');
      }

      // Get Secure Storage data
      print('-----STORAGE DATA----- Secure Storage Data:');
      final secureUserDataStr = await _authService.getSecureUserData();
      print('-----STORAGE DATA----- Secure user data: $secureUserDataStr');

    } catch (e) {
      print('-----STORAGE DATA----- Error logging storage data: $e');
    }
  }

  // 💡 Add new function to get salary data
  Future<Map<String, dynamic>?> _getSavedSalaryData() async {
    final prefs = await SharedPreferences.getInstance();
    final salaryDataStr = prefs.getString('dakhli_salary_data');
    if (salaryDataStr != null) {
      return json.decode(salaryDataStr) as Map<String, dynamic>;
    }
    return null;
  }

  // 💡 Add new function to save salary data
  Future<void> _saveSalaryData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dakhli_salary_data', json.encode({
      'last_updated': DateTime.now().toIso8601String(),
      'employments': data['result']['employmentStatusInfo'],
    }));
  }

  // 💡 Add new function to get Dakhli salary
  Future<Map<String, dynamic>> _getDakhliSalary({
    required String? nationalId,
    required String? dob,
    required String reason,
  }) async {
    // Validate parameters
    if (nationalId == null || dob == null) {
      throw Exception('National ID and Date of Birth are required');
    }

    // 💡 Use test data if flag is true
    if (Constants.useTestData) {
      return Constants.testDakhliResponse;
    }

    final response = await http.get(
      Uri.parse('${Constants.dakhliSalaryEndpoint}?customerId=$nationalId&dob=$dob&reason=$reason'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch salary data');
  }

  // 💡 Add new function to handle application start
  Future<void> _handleApplicationStart({required bool isLoanApplication}) async {
    try {
      setState(() => _isLoading = true);
      
      // Check local storage first for existing salary data
      final salaryData = await _getSavedSalaryData();
      
      if (salaryData == null) {
        String? nationalId;
        String? dob;
        
        // 💡 Use test data if flag is true
        if (Constants.useTestData) {
          nationalId = Constants.testUserData['nationalId'];
          dob = Constants.testUserData['dateOfBirth'];
        } else {
          // First try to get data from widget.userData
          if (widget.userData.isNotEmpty) {
            print('DEBUG: Checking widget.userData: ${widget.userData}');
            nationalId = widget.userData['national_id']?.toString();
            dob = widget.userData['date_of_birth']?.toString();
            
            // If there's a nested user object
            if (widget.userData['user'] != null) {
              nationalId ??= widget.userData['user']['national_id']?.toString();
              dob ??= widget.userData['user']['date_of_birth']?.toString();
            }
          }
          
          // If not found in widget.userData, try secure storage
          if (nationalId == null || dob == null) {
            print('DEBUG: Checking secure storage');
            final storage = const FlutterSecureStorage();
            final userDataStr = await storage.read(key: 'user_data');
            nationalId ??= await storage.read(key: 'national_id');
            
            if (userDataStr != null) {
              final userData = json.decode(userDataStr) as Map<String, dynamic>;
              print('DEBUG: Secure storage data: $userData');
              
              // Try to get DOB from user object if it exists
              if (userData['user'] != null) {
                dob ??= userData['user']['date_of_birth']?.toString();
              }
              
              // If not found in user object, try the root level
              dob ??= userData['date_of_birth']?.toString() ?? 
                     userData['dateOfBirth']?.toString() ?? 
                     userData['dob']?.toString();
            }
          }
          
          print('DEBUG: Final values - NationalID: $nationalId, DOB: $dob');
          
          if (nationalId == null) {
            throw Exception('User data not found');
          }
          
          if (dob == null) {
            throw Exception('Date of birth not found');
          }
        }
        
        // Call proxy endpoint
        final response = await _getDakhliSalary(
          nationalId: nationalId,
          dob: dob,
          reason: isLoanApplication ? 'LOAN' : 'CARD'
        );
        
        // Save to local storage
        await _saveSalaryData(response);
      }
      
      // Navigate to appropriate screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isLoanApplication 
            ? LoanApplicationStartScreen(isArabic: widget.isArabic)
            : CardApplicationStartScreen(isArabic: widget.isArabic),
        ),
      );
    } catch (e) {
      print('DEBUG: Application Start Error: $e'); // Debug print
      _showErrorDialog(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 💡 Add new function to show error dialog
  void _showErrorDialog(dynamic error) {
    String message;
    
    if (error.toString().contains('User data not found')) {
      message = widget.isArabic 
        ? 'يرجى تسجيل الدخول أولاً'
        : 'Please sign in first';
    } else if (error.toString().contains('Date of birth not found')) {
      message = widget.isArabic
        ? 'معلومات تاريخ الميلاد غير متوفرة'
        : 'Date of birth information not available';
    } else {
      message = widget.isArabic
        ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى'
        : 'An unexpected error occurred. Please try again';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isArabic ? 'تنبيه' : 'Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }
}
