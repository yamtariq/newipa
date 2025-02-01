class Constants {
  // API Base URLs
  static const String apiBaseUrl = 'https://icreditdept.com/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';
  static const String masterFetchUrl = '$apiBaseUrl/master_fetch.php';
  // Used in: ContentUpdateService (content_update_service.dart) - For fetching all dynamic content:
  // - Loan ads: page=loans&key_name=loan_ad
  // - Card ads: page=cards&key_name=card_ad
  // - Slides: page=home&key_name=slideshow_content
  // - Arabic slides: page=home&key_name=slideshow_content_ar
  // - Contact details: page=home&key_name=contact_details
  // - Arabic contact details: page=home&key_name=contact_details_ar

  // API Key
  static const String apiKey = '7ca7427b418bdbd0b3b23d7debf69bf7';

  // Content Types
  static const String _contentTypeJson = 'application/json';
  static const String _contentTypeForm = 'application/x-www-form-urlencoded';

  // Base headers without content type
  static Map<String, String> get _baseHeaders => {
    'Accept': 'application/json',
    'api-key': apiKey,
  };

  // Default headers (JSON)
  static Map<String, String> get defaultHeaders => {
    ..._baseHeaders,
    'Content-Type': _contentTypeJson,
  };

  // Auth headers
  static Map<String, String> get authHeaders => {
    ...defaultHeaders,
    'X-Feature': 'auth',
  };

  // Form data headers
  static Map<String, String> get authFormHeaders => {
    ..._baseHeaders,
    'Content-Type': _contentTypeForm,
    'X-Feature': 'auth',
  };

  // Device headers
  static Map<String, String> get deviceHeaders => {
    ...defaultHeaders,
    'X-Feature': 'device',
  };

  // User headers
  static Map<String, String> get userHeaders => {
    ...defaultHeaders,
    'X-Feature': 'user',
  };

  // API Endpoints
  // Remove content_updates.php since we're using master_fetch.php
  // static const String endpointContentUpdates = '/content_updates.php';

  // API Endpoints
  static const String endpointSignIn = '/signin.php';
  // Used in: AuthService (auth_service.dart) - signIn(), login(), getUserData()

  static const String endpointRefreshToken = '/refresh_token.php';
  // Used in: AuthService (auth_service.dart) - _refreshToken()

  static const String endpointVerifyCredentials = '/verify_credentials.php';
  // Used in: AuthService (auth_service.dart) - initiateDeviceTransition()

  static const String endpointOTPGenerate = '/otp_generate.php';
  // Used in: AuthService (auth_service.dart) - generateOTP()
  // Used in: RegistrationService (registration_service.dart) - generateOTP()

  static const String endpointOTPVerification = '/otp_verification.php';
  // Used in: AuthService (auth_service.dart) - verifyOTP()
  // Used in: RegistrationService (registration_service.dart) - verifyOTP()

  static const String endpointPasswordChange = '/password_change.php';
  // Used in: AuthService (auth_service.dart) - changePassword()

  static const String endpointCheckDeviceRegistration = '/check_device_registration.php';
  // Used in: AuthService (auth_service.dart) - checkDeviceRegistration(), validateDeviceRegistration()

  static const String endpointRegisterDevice = '/register_device.php';
  // Used in: AuthService (auth_service.dart) - registerDevice(), initiateDeviceTransition()
  // Used in: NotificationService (notification_service.dart) - registerDevice()

  static const String endpointUnregisterDevice = '/unregister_device.php';
  // Used in: AuthService (auth_service.dart) - signOutDevice(), unregisterCurrentDevice()

  static const String endpointReplaceDevice = '/replace_device.php';
  // Used in: AuthService (auth_service.dart) - replaceDevice()

  static const String endpointUserRegistration = '/user_registration.php';
  // Used in: AuthService (auth_service.dart) - registerUser(), checkRegistrationStatus(), checkIdExists()
  // Used in: RegistrationService (registration_service.dart) - checkRegistration(), completeRegistration()

  static const String endpointGetGovernmentData = '/get_gov_services.php';
  // Used in: AuthService (auth_service.dart) - getGovernmentData(), getGovernmentServices()
  // Used in: RegistrationService (registration_service.dart) - getGovernmentData()

  // Loan Endpoints
  static const String endpointLoanDecision = '/api/v1/Finnone/GetCustomerCreate';
  // Used in: LoanService (loan_service.dart) - getLoanDecision()

  static const String endpointUpdateLoanApplication = '/update_loan_application.php';
  // Used in: LoanService (loan_service.dart) - updateLoanApplication()

  // Card Endpoints
  static const String endpointCardDecision = '/cards_decision.php';
  // Used in: CardService (card_service.dart) - getCardDecision()

  static const String endpointUpdateCardApplication = '/update_cards_application.php';
  // Used in: CardService (card_service.dart) - updateCardApplication()

  // Notification Endpoints
  static const String endpointGetNotifications = '/get_notifications.php';
  // Used in: NotificationService (notification_service.dart) - fetchNotifications()

  static const String endpointSendNotification = '/send_notification.php';
  // Used in: NotificationService (notification_service.dart) - sendNotification()

  // Auth Endpoints
  static const String endpointValidateIdentity = '/validate-identity';
  // Used in: ApiService (api_service.dart) - validateUserIdentity()
  // Used in: RegistrationService (registration_service.dart) - validateIdentity()

  static const String endpointSetPassword = '/set-password';
  // Used in: ApiService (api_service.dart) - setPassword()
  // Used in: RegistrationService (registration_service.dart) - setPassword()

  static const String endpointSetQuickAccessPin = '/set-quick-access-pin';
  // Used in: ApiService (api_service.dart) - setQuickAccessPin()
  // Used in: RegistrationService (registration_service.dart) - setMPIN()

  static const String endpointVerifyOtp = '/verify-otp';
  // Used in: ApiService (api_service.dart) - verifyOtp()

  static const String endpointResendOtp = '/resend-otp';
  // Used in: ApiService (api_service.dart) - resendOtp()

  // Colors
  static const int primaryColorValue = 0xFF0077B6;
  
  // Theme Base Colors
  // Light Theme
  static const int lightPrimaryColor = 0xFF0077B6;    // Primary blue 
  static const int lightBackgroundColor = 0xFFE3F2FD; // Light baby blue background
  static const int lightSurfaceColor = 0xFFFFFFFF;    // Pure white surface

  // Dark Theme
  static const int darkPrimaryColor = 0xFF0099E6;     // Lighter blue for dark mode
  static const int darkBackgroundColor = 0xFF121212;  // Dark gray/black
  static const int darkSurfaceColor = 0xFF242424;     // Slightly lighter dark gray

  // Form and UI Colors with Opacity
  // Light Theme Form Colors
  static const int lightFormBackgroundColor = 0xFFFFFFFF;  // Pure white for forms
  static const int lightFormBorderColor = 0x330077B6;      // Primary blue with 20% opacity
  static const int lightFormFocusedBorderColor = 0x800077B6; // Primary blue with 50% opacity
  static const int lightLabelTextColor = 0xFF0077B6;       // Primary blue (full opacity)
  static const int lightHintTextColor = 0x800077B6;        // Primary blue with 50% opacity
  static const int lightIconColor = 0xFF0077B6;            // Primary blue (full opacity)

  // Dark Theme Form Colors
  static const int darkFormBackgroundColor = 0x140099E6;   // Dark blue with 8% opacity
  static const int darkFormBorderColor = 0x330099E6;       // Dark blue with 20% opacity
  static const int darkFormFocusedBorderColor = 0x800099E6; // Dark blue with 50% opacity
  static const int darkLabelTextColor = 0xCC0099E6;        // Dark blue with 80% opacity
  static const int darkHintTextColor = 0x800099E6;         // Dark blue with 50% opacity
  static const int darkIconColor = 0xCC0099E6;             // Dark blue with 80% opacity

  // Switch Colors
  static const int lightSwitchTrackColor = 0x4D0077B6;     // Primary blue with 30% opacity
  static const int lightSwitchInactiveTrackColor = 0x1A0077B6; // Primary blue with 10% opacity
  static const int lightSwitchInactiveThumbColor = primaryColorValue; // the circle in the toggle button Primary blue with 70% opacity
  static const int lightSwitchTrackOutlineColor = 0x1A0077B6; // Primary blue with 10% opacity (matching track)
  
  static const int darkSwitchTrackColor = 0x4D0099E6;      // Dark blue with 30% opacity
  static const int darkSwitchInactiveTrackColor = 0x1A0099E6; // Dark blue with 10% opacity
  static const int darkSwitchInactiveThumbColor = 0xB30099E6; // Dark blue with 70% opacity
  static const int darkSwitchTrackOutlineColor = 0x1A0099E6; // Dark blue with 10% opacity (matching track)

  // Gradient Colors
  static const int lightGradientStartColor = 0x1A0077B6;   // Primary blue with 10% opacity
  static const int lightGradientEndColor = 0x0D0077B6;     // Primary blue with 5% opacity
  
  static const int darkGradientStartColor = 0x1A0099E6;    // Dark blue with 10% opacity
  static const int darkGradientEndColor = 0x0D0099E6;      // Dark blue with 5% opacity

  // Shadow Colors
  static const int lightPrimaryShadowColor = 0x330077B6;   // Primary blue with 20% opacity
  static const int lightSecondaryShadowColor = 0x1A0077B6; // Primary blue with 10% opacity
  
  static const int darkPrimaryShadowColor = 0x330099E6;    // Dark blue with 20% opacity
  static const int darkSecondaryShadowColor = 0x1A0099E6;  // Dark blue with 10% opacity

  // Navigation Bar Colors
  // Light Theme Navbar
  static const int lightNavbarBackground = 0xFFFFFFFF;     // White background
  static const int lightNavbarPageBackground = 0xFFFFFFFF;  // White page background
  static const int lightNavbarGradientStart = lightBackgroundColor;  // Primary blue with 10% opacity
  static const int lightNavbarGradientEnd = lightBackgroundColor;    // Primary blue with 5% opacity
  static const int lightNavbarShadowPrimary = lightBackgroundColor;  // Primary blue with 20% opacity
  static const int lightNavbarShadowSecondary = lightBackgroundColor;// Primary blue with 10% opacity
  static const int lightNavbarActiveIcon = 0xFF0077B6;     // Primary blue (full opacity)
  static const int lightNavbarInactiveIcon = 0xFF0077B6;   // Primary blue with 50% opacity
  static const int lightNavbarActiveText = 0xFF0077B6;     // Primary blue (full opacity)
  static const int lightNavbarInactiveText = 0xFF0077B6;   // Primary blue with 50% opacity

  // Dark Theme Navbar
  static const int darkNavbarBackground = darkBackgroundColor;      // Dark surface color
  static const int darkNavbarGradientStart = 0x1A0099E6;   // Dark blue with 10% opacity
  static const int darkNavbarGradientEnd = 0x0D0099E6;     // Dark blue with 5% opacity
  static const int darkNavbarShadowPrimary = 0x330099E6;   // Dark blue with 20% opacity
  static const int darkNavbarShadowSecondary = 0x1A0099E6; // Dark blue with 10% opacity
  static const int darkNavbarActiveIcon = 0xFF0099E6;      // Dark blue (full opacity)
  static const int darkNavbarInactiveIcon = 0x800099E6;    // Dark blue with 50% opacity
  static const int darkNavbarActiveText = 0xFF0099E6;      // Dark blue (full opacity)
  static const int darkNavbarInactiveText = 0x800099E6;    // Dark blue with 50% opacity

  // Border Radii
  static const double containerBorderRadius = 12.0;
  static const double formBorderRadius = 8.0;
  static const double buttonBorderRadius = 15.0;

  // Form and UI Element Constants
  // Background Opacities
  static const double formBackgroundOpacityDark = 0.08;  // For dark mode form backgrounds
  static const double formBackgroundOpacityLight = 0.04; // For light mode form backgrounds
  
  // Border Opacities
  static const double formBorderOpacity = 0.2;          // For form borders
  static const double formFocusedBorderOpacity = 0.5;   // For focused form borders
  
  // Text Opacities
  static const double labelTextOpacity = 0.8;           // For form labels
  static const double hintTextOpacity = 0.5;            // For hint text
  
  // Switch and Interactive Elements
  static const double activeTrackOpacity = 0.3;         // For switch tracks when active
  static const double inactiveTrackOpacity = 0.1;       // For switch tracks when inactive
  static const double inactiveThumbOpacity = 0.7;       // For switch thumbs when inactive
  
  // Gradient Opacities
  static const double gradientStartOpacity = 0.1;       // For gradient start color
  static const double gradientEndOpacity = 0.05;        // For gradient end color
  
  // Shadow Opacities
  static const double primaryShadowOpacity = 0.2;       // For primary shadows
  static const double secondaryShadowOpacity = 0.1;     // For secondary shadows

  // Asset paths
  static const String termsAndConditionsPath = 'assets/docs/terms.pdf';
  static const String privacyPolicyPath = 'assets/docs/privacy.pdf';
  static const String companyLogoPath = 'assets/images/nayifat-logo.svg';
  
  // Loan calculation constants
  static const double maxLoanAmount = 300000;
  static const double minLoanAmount = 10000;
  static const int maxTenure = 60;
  static const int minTenure = 12;
  static const double flatRate = 0.16; // 16%
  static const double dbrRate = 0.15; // 15%

  // Loan Ad Constants
  static Map<String, dynamic> get loanAd => {
    'en': {
      'image_url': 'assets/images/loans_ad.JPG',
      'title': 'Personal Finance Solutions',
      'description': 'Get instant financing up to 500,000 SAR',
    },
    'ar': {
      'image_url': 'assets/images/loans_ad_ar.JPG',
      'title': 'حلول التمويل الشخصي',
      'description': 'احصل على تمويل فوري يصل إلى 500,000 ريال',
    },
    'is_asset': true,
    'last_updated': null,
    'remote_url': '$apiBaseUrl/ads/loan_ad.php',
  };

  // Card Ad Constants
  static Map<String, dynamic> get cardAd => {
    'en': {
      'image_url': 'assets/images/cards_ad.JPG',
      'title': 'Credit Card Solutions',
      'description': 'Get a credit card with limit up to 50,000 SAR',
    },
    'ar': {
      'image_url': 'assets/images/cards_ad_ar.JPG',
      'title': 'حلول البطاقات الائتمانية',
      'description': 'احصل على بطاقة ائتمانية بحد يصل إلى 50,000 ريال',
    },
    'is_asset': true,
    'last_updated': null,
    'remote_url': '$apiBaseUrl/ads/card_ad.php',
  };

  // Static Slides
  static List<Map<String, String>> get staticSlides => [
    {
      'id': '1',
      'imageUrl': 'assets/images/slide1.jpg',
      'leftTitleEn': 'Personal Finance',
      'leftTitleAr': 'التمويل الشخصي',
      'rightTitleEn': 'Apply Now',
      'rightTitleAr': 'اطلب الآن',
      'link': '/loans',
    },
    {
      'id': '2',
      'imageUrl': 'assets/images/slide2.jpg',
      'leftTitleEn': 'Nayifat Cards',
      'leftTitleAr': 'بطاقات النايفات',
      'rightTitleEn': 'Apply Now',
      'rightTitleAr': 'اطلبها الان',
      'link': '/cards',
    },
    {
      'id': '3',
      'imageUrl': 'assets/images/slide3.jpg',
      'leftTitleEn': 'with Nayifat',
      'leftTitleAr': 'مع النايفات',
      'rightTitleEn': 'Details',
      'rightTitleAr': 'للتفاصيل',
      'link': 'https://nayifat.com/برنامج-تخير/',
    },
  ];

  // Static Contact Details
  static Map<String, dynamic> get staticContactDetails => {
    'phone': '8001000088',
    'email': 'CustomerCare@nayifat.com',
    'workHours': 'Sun-Thu: 8:00-17:00',
    'socialLinks': {
      'linkedin': 'https://www.linkedin.com/company/nayifat-instalment-company/',
      'twitter': 'https://twitter.com/nayifatco?lang=ar',
      'facebook': 'https://www.facebook.com/nayifatcompany',
      'instagram': 'https://www.instagram.com/nayifatcompany/',
    },
  };

  // Error Colors
  static const int darkErrorColor = 0xFFFF5252;  // Red shade for dark theme
  static const int lightErrorColor = 0xFFD32F2F;  // Darker red for light theme
} 