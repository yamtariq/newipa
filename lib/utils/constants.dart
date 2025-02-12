import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

class Constants {
  // API Base URLs
  static const bool useNewApi = true; // Feature flag for easy switching
  
  static String get apiBaseUrl => useNewApi
      ? 'https://tmappuat.nayifat.com/api'  //'https://172.22.160.20:5264/api'
      : 'https://icreditdept.com/api';
  static String get authBaseUrl => '$apiBaseUrl/auth';
  static String get masterFetchUrl => '$apiBaseUrl/content/fetch';
  static String get contentTimestampsUrl => '$apiBaseUrl/content/timestamps';
  
  
  
  // proxy link      $apiBaseUrl/proxy/forward?url=
  
  // Used in: ContentUpdateService (content_update_service.dart) - For fetching all dynamic content:
  // - Loan ads: page=loans&key_name=loan_ad
  // - Card ads: page=cards&key_name=card_ad
  // - Slides: page=home&key_name=slideshow_content
  // - Arabic slides: page=home&key_name=slideshow_content_ar
  // - Contact details: page=home&key_name=contact_details
  // - Arabic contact details: page=home&key_name=contact_details_ar

  // Proxy Endpoints
  static const String proxyBaseUrl = 'https://icreditdept.com/api/testasp';
  static String get proxyOtpGenerateUrl => '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:6445/api/otp/GetOtp';
  static String get proxyOtpVerifyUrl => '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:6445/api/otp/GetVerifyOtp';


  // 💡 Add Dakhli salary endpoint
  static const String dakhliBaseUrl = 'https://172.22.226.190:4043/api/Dakhli/GetDakhliPubPriv';
  static String get dakhliSalaryEndpoint => '$apiBaseUrl/proxy/forward?url=$dakhliBaseUrl';

// 💡 Add Dakhli salary endpoint
//   static String get dakhliSalaryEndpoint => '$apiBaseUrl/api/Proxy/dakhli/salary';

  

  // API Key
  static const String apiKey = '7ca7427b418bdbd0b3b23d7debf69bf7';

  // Content Types
  static const String _contentTypeJson = 'application/json';
  static const String _contentTypeForm = 'application/x-www-form-urlencoded';

  // Base headers without content type
  static Map<String, String> get _baseHeaders => {
        'Accept': 'application/json',
        'x-api-key': apiKey, // Using x-api-key header
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

  // User Registration Endpoints
  static const String endpointRegistration =
      '/Registration/register'; // New endpoint
  static const String endpointUserRegistration =
      endpointRegistration; // Alias for backward compatibility
      
  static String endpointGetGovernmentData = 
      '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:663/api/Yakeen/getCitizenInfo/json';
  static String endpointGetGovernmentAddress = 
      '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:663/api/Yakeen/getCitizenAddressInfo/json';

  
  
  // 💡 Yakeen API Endpoints
  static String endpointGetAlienInfo = 
      '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:663/api/Yakeen/getAlienInfoByIqama/json';
  static String endpointGetAlienAddress = 
      '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:663/api/Yakeen/getAlienAddressInfoByIqama/json';


/* ==========================================
   * OLD PHP ENDPOINTS (FOR REFERENCE/FALLBACK)
   * ==========================================
   static const String endpointSignIn = '/signin.php';
   static const String endpointRefreshToken = '/refresh_token.php';
   static const String endpointVerifyCredentials = '/verify_credentials.php';
   static const String endpointOTPGenerate = '/otp_generate.php';
   static const String endpointOTPVerification = '/otp_verification.php';
   static const String endpointPasswordChange = '/password_change.php';
   static const String endpointCheckDeviceRegistration = '/check_device_registration.php';
   static const String endpointRegisterDevice = '/register_device.php';
   static const String endpointUnregisterDevice = '/unregister_device.php';
   static const String endpointReplaceDevice = '/replace_device.php';
   static const String endpointUserRegistration = '/user_registration.php';
   static const String endpointGetGovernmentData = '/get_gov_services.php';
   static const String endpointValidateIdentity = '/validate_identity.php';
   static const String endpointSetPassword = '/set_password.php';
   static const String endpointVerifyOtp = '/verify_otp.php';
   static const String endpointResendOtp = '/resend_otp.php';
   static const String endpointLoanDecision = '/api/v1/Finnone/GetCustomerCreate';
   static const String endpointUpdateLoanApplication = '/update_loan_application.php';
   static const String endpointCardDecision = '/cards_decision.php';
   static const String endpointUpdateCardApplication = '/update_cards_application.php';
   static const String endpointGetNotifications = '/get_notifications.php';
   static const String endpointSendNotification = '/send_notification.php';
   */

  // Authentication Endpoints
  // Old: static const String endpointSignIn = '/signin.php';
  static const String endpointSignIn = '/auth/signin';
  // Used in: AuthService (auth_service.dart) - signIn(), login(), getUserData()

  // Old: static const String endpointVerifyCredentials = '/verify_credentials.php';
  static const String endpointVerifyCredentials = '/auth/verify-credentials';
  // Used in: AuthService (auth_service.dart) - initiateDeviceTransition()

  // Old: static const String endpointRefreshToken = '/refresh_token.php';
  static const String endpointRefreshToken = '/auth/refresh';
  // Used in: AuthService (auth_service.dart) - _refreshToken()

  // Old: static const String endpointOTPGenerate = '/otp_generate.php';
  static String get endpointOTPGenerate => proxyOtpGenerateUrl;
  // Used in: AuthService (auth_service.dart) - generateOTP()
  // Used in: RegistrationService (registration_service.dart) - generateOTP()

  // Old: static const String endpointOTPVerification = '/otp_verification.php';
  static String get endpointOTPVerification => proxyOtpVerifyUrl;
  // Used in: AuthService (auth_service.dart) - verifyOTP()
  // Used in: RegistrationService (registration_service.dart) - verifyOTP()

  // Old: static const String endpointPasswordChange = '/password_change.php';
  static const String endpointPasswordChange = '/auth/password';
  // Used in: AuthService (auth_service.dart) - changePassword()

  // Device Management
  // Old: static const String endpointCheckDeviceRegistration = '/check_device_registration.php';
  static const String endpointCheckDeviceRegistration = '/device/check';
  // Used in: AuthService (auth_service.dart) - checkDeviceRegistration(), validateDeviceRegistration()

  // Old: static const String endpointRegisterDevice = '/register_device.php';
  static const String endpointRegisterDevice = '/device';
  // Used in: AuthService (auth_service.dart) - registerDevice(), initiateDeviceTransition()
  // Used in: NotificationService (notification_service.dart) - registerDevice()

  // Old: static const String endpointUnregisterDevice = '/unregister_device.php';
  static const String endpointUnregisterDevice = '/device/unregister';
  // Used in: AuthService (auth_service.dart) - signOutDevice(), unregisterCurrentDevice()

  // Old: static const String endpointReplaceDevice = '/replace_device.php';
  static const String endpointReplaceDevice = '/device/replace';
  // Used in: AuthService (auth_service.dart) - replaceDevice()

  // Lead Application Endpoints
  static const String endpointCreateCardLead = '/lead/card/create';
  // Used in: LeadApplicationService - createCardLead()

  static const String endpointCreateLoanLead = '/lead/loan/create';
  // Used in: LeadApplicationService - createLoanLead()

  // User Registration
  // Old: static const String endpointUserRegistration = '/user_registration.php';
  // static const String endpointRegistration = '/registration/register';  // Base endpoint for registration
  // Used in: AuthService (auth_service.dart) - registerUser(), checkRegistrationStatus(), checkIdExists()
  // Used in: RegistrationService (registration_service.dart) - checkRegistration(), completeRegistration()

  // Old: static const String endpointGetGovernmentData = '/get_gov_services.php';
  // Used in: AuthService (auth_service.dart) - getGovernmentData(), getGovernmentServices()
  // Used in: RegistrationService (registration_service.dart) - getGovernmentData()

  // Old: static const String endpointValidateIdentity = '/validate_identity.php';
  static const String endpointValidateIdentity = '/auth/validate-identity';
  // Used in: ApiService (api_service.dart) - validateUserIdentity()
  // Used in: RegistrationService (registration_service.dart) - validateIdentity()

  // Old: static const String endpointSetPassword = '/set_password.php';
  static const String endpointSetPassword = '/auth/set-password';
  // Used in: ApiService (api_service.dart) - setPassword()
  // Used in: RegistrationService (registration_service.dart) - setPassword()

  // Old: static const String endpointVerifyOtp = '/verify_otp.php';
  static const String endpointVerifyOtp = '/auth/verify-otp';
  // Used in: ApiService (api_service.dart) - verifyOtp()

  // Old: static const String endpointResendOtp = '/resend_otp.php';
  static const String endpointResendOtp = '/auth/resend-otp';
  // Used in: ApiService (api_service.dart) - resendOtp()

  // Loan Management
  // Old: static const String endpointLoanDecision = '/api/v1/Finnone/GetCustomerCreate';
  static const String endpointLoanDecision = '/loan/decision';
  // Used in: LoanService (loan_service.dart) - getLoanDecision()
  
  // 💡 Bank API Endpoints
  static String endpointCreateCustomer = 
      '$apiBaseUrl/proxy/forward?url=https://172.22.226.203:9443/api/Bank/CreateCustomer';

  // Old: static const String endpointUpdateLoanApplication = '/update_loan_application.php';
  static const String endpointUpdateLoanApplication = '/loan/update';
  // Used in: LoanService (loan_service.dart) - updateLoanApplication()

  // Card Management
  // Old: static const String endpointCardDecision = '/cards_decision.php';
  static const String endpointCardDecision = '/card/decision';
  // Used in: CardService (card_service.dart) - getCardDecision()

  // Old: static const String endpointUpdateCardApplication = '/update_cards_application.php';
  static const String endpointUpdateCardApplication = '/card/update';
  // Used in: CardService (card_service.dart) - updateCardApplication()

  // Notification Management
  // Old: static const String endpointGetNotifications = '/get_notifications.php';
  static const String endpointGetNotifications = '/notifications/list';
  // Used in: NotificationService (notification_service.dart) - fetchNotifications()

  // Old: static const String endpointSendNotification = '/send_notification.php';
  static const String endpointSendNotification = '/notifications/send';
  // Used in: NotificationService (notification_service.dart) - sendNotification()

  // Colors
  static const int primaryColorValue = 0xFF0077B6;

  // Theme Base Colors
  // Light Theme
  static const int lightPrimaryColor = 0xFF0077B6; // Primary blue
  static const int lightBackgroundColor =
      0xFFE3F2FD; // Light baby blue background
  static const int lightSurfaceColor = 0xFFFFFFFF; // Pure white surface

  // Dark Theme
  static const int darkPrimaryColor = 0xFF0099E6; // Lighter blue for dark mode
  static const int darkBackgroundColor = 0xFF121212; // Dark gray/black
  static const int darkSurfaceColor = 0xFF242424; // Slightly lighter dark gray

  // Form and UI Colors with Opacity
  // Light Theme Form Colors
  static const int lightFormBackgroundColor =
      0xFFFFFFFF; // Pure white for forms
  static const int lightFormBorderColor =
      0x330077B6; // Primary blue with 20% opacity
  static const int lightFormFocusedBorderColor =
      0x800077B6; // Primary blue with 50% opacity
  static const int lightLabelTextColor =
      0xFF0077B6; // Primary blue (full opacity)
  static const int lightHintTextColor =
      0x800077B6; // Primary blue with 50% opacity
  static const int lightIconColor = 0xFF0077B6; // Primary blue (full opacity)

  // Dark Theme Form Colors
  static const int darkFormBackgroundColor =
      0x140099E6; // Dark blue with 8% opacity
  static const int darkFormBorderColor =
      0x330099E6; // Dark blue with 20% opacity
  static const int darkFormFocusedBorderColor =
      0x800099E6; // Dark blue with 50% opacity
  static const int darkLabelTextColor =
      0xCC0099E6; // Dark blue with 80% opacity
  static const int darkHintTextColor = 0x800099E6; // Dark blue with 50% opacity
  static const int darkIconColor = 0xCC0099E6; // Dark blue with 80% opacity

  // Switch Colors
  static const int lightSwitchTrackColor =
      0x4D0077B6; // Primary blue with 30% opacity
  static const int lightSwitchInactiveTrackColor =
      0x1A0077B6; // Primary blue with 10% opacity
  static const int lightSwitchInactiveThumbColor =
      primaryColorValue; // the circle in the toggle button Primary blue with 70% opacity
  static const int lightSwitchTrackOutlineColor =
      0x1A0077B6; // Primary blue with 10% opacity (matching track)

  static const int darkSwitchTrackColor =
      0x4D0099E6; // Dark blue with 30% opacity
  static const int darkSwitchInactiveTrackColor =
      0x1A0099E6; // Dark blue with 10% opacity
  static const int darkSwitchInactiveThumbColor =
      0xB30099E6; // Dark blue with 70% opacity
  static const int darkSwitchTrackOutlineColor =
      0x1A0099E6; // Dark blue with 10% opacity (matching track)

  // Gradient Colors
  static const int lightGradientStartColor =
      0x1A0077B6; // Primary blue with 10% opacity
  static const int lightGradientEndColor =
      0x0D0077B6; // Primary blue with 5% opacity

  static const int darkGradientStartColor =
      0x1A0099E6; // Dark blue with 10% opacity
  static const int darkGradientEndColor =
      0x0D0099E6; // Dark blue with 5% opacity

  // Shadow Colors
  static const int lightPrimaryShadowColor =
      0x330077B6; // Primary blue with 20% opacity
  static const int lightSecondaryShadowColor =
      0x1A0077B6; // Primary blue with 10% opacity

  static const int darkPrimaryShadowColor =
      0x330099E6; // Dark blue with 20% opacity
  static const int darkSecondaryShadowColor =
      0x1A0099E6; // Dark blue with 10% opacity

  // Navigation Bar Colors
  // Light Theme Navbar
  static const int lightNavbarBackground = 0xFFFFFFFF; // White background
  static const int lightNavbarPageBackground =
      0xFFFFFFFF; // White page background
  static const int lightNavbarGradientStart =
      lightBackgroundColor; // Primary blue with 10% opacity
  static const int lightNavbarGradientEnd =
      lightBackgroundColor; // Primary blue with 5% opacity
  static const int lightNavbarShadowPrimary =
      lightBackgroundColor; // Primary blue with 20% opacity
  static const int lightNavbarShadowSecondary =
      lightBackgroundColor; // Primary blue with 10% opacity
  static const int lightNavbarActiveIcon =
      0xFF0077B6; // Primary blue (full opacity)
  static const int lightNavbarInactiveIcon =
      0xFF0077B6; // Primary blue with 50% opacity
  static const int lightNavbarActiveText =
      0xFF0077B6; // Primary blue (full opacity)
  static const int lightNavbarInactiveText =
      0xFF0077B6; // Primary blue with 50% opacity

  // Dark Theme Navbar
  static const int darkNavbarBackground =
      darkBackgroundColor; // Dark surface color
  static const int darkNavbarGradientStart =
      0x1A0099E6; // Dark blue with 10% opacity
  static const int darkNavbarGradientEnd =
      0x0D0099E6; // Dark blue with 5% opacity
  static const int darkNavbarShadowPrimary =
      0x330099E6; // Dark blue with 20% opacity
  static const int darkNavbarShadowSecondary =
      0x1A0099E6; // Dark blue with 10% opacity
  static const int darkNavbarActiveIcon =
      0xFF0099E6; // Dark blue (full opacity)
  static const int darkNavbarInactiveIcon =
      0x800099E6; // Dark blue with 50% opacity
  static const int darkNavbarActiveText =
      0xFF0099E6; // Dark blue (full opacity)
  static const int darkNavbarInactiveText =
      0x800099E6; // Dark blue with 50% opacity

  // Border Radii
  static const double containerBorderRadius = 12.0;
  static const double formBorderRadius = 8.0;
  static const double buttonBorderRadius = 15.0;

  // Form and UI Element Constants
  // Background Opacities
  static const double formBackgroundOpacityDark =
      0.08; // For dark mode form backgrounds
  static const double formBackgroundOpacityLight =
      0.04; // For light mode form backgrounds

  // Border Opacities
  static const double formBorderOpacity = 0.2; // For form borders
  static const double formFocusedBorderOpacity =
      0.5; // For focused form borders

  // Text Opacities
  static const double labelTextOpacity = 0.8; // For form labels
  static const double hintTextOpacity = 0.5; // For hint text

  // Switch and Interactive Elements
  static const double activeTrackOpacity = 0.3; // For switch tracks when active
  static const double inactiveTrackOpacity =
      0.1; // For switch tracks when inactive
  static const double inactiveThumbOpacity =
      0.7; // For switch thumbs when inactive

  // Gradient Opacities
  static const double gradientStartOpacity = 0.1; // For gradient start color
  static const double gradientEndOpacity = 0.05; // For gradient end color

  // Shadow Opacities
  static const double primaryShadowOpacity = 0.2; // For primary shadows
  static const double secondaryShadowOpacity = 0.1; // For secondary shadows

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
          'linkedin':
              'https://www.linkedin.com/company/nayifat-instalment-company/',
          'twitter': 'https://twitter.com/nayifatco?lang=ar',
          'facebook': 'https://www.facebook.com/nayifatcompany',
          'instagram': 'https://www.instagram.com/nayifatcompany/',
        },
      };

  // Error Colors
  static const int darkErrorColor = 0xFFFF5252; // Red shade for dark theme
  static const int lightErrorColor = 0xFFD32F2F; // Darker red for light theme

  // OTP Request Format
  static Map<String, dynamic> otpGenerateRequestBody(
          String nationalId, String mobileNo, {String purpose = 'Login'}) =>
      {
        'nationalId': nationalId,
        'mobileNo': mobileNo,
        'purpose': purpose,
        'userId': '1'
      };

  static Map<String, dynamic> otpVerifyRequestBody(
          String nationalId, String otp) =>
      {
        'nationalId': nationalId.trim(),
        'otp': otp.trim(),
        'userId': '1',
      };

  // 💡 Bank API Configuration
  static const String bankApiUsername = 'Nayifat'; // Change in production
  static const String bankApiPassword = 'Nayifat@123'; // Change in production
  static const String bankApiAppId = '3162C93C-3C9E-4613-A4D9-53BF99BB9CB1'; // Change in production
  static const String bankApiKey = 'A624BA39-BFDA-4F09-829C-9F6294D6DF23'; // Change in production
  static const String bankApiOrgNo = 'Nayifat'; // Change in production

  // 💡 Bank API Headers
  static Map<String, String> get bankApiHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Basic TmF5aWZhdDpOYXlpZmF0QDEyMw==',
    'X-APP-ID': bankApiAppId,
    'X-API-KEY': bankApiKey,
    'X-Organization-No': bankApiOrgNo,
  };

  // 💡 HTTP Client for development (bypasses SSL verification)
  static http.Client createHttpClient({bool validateCertificate = false}) {
    if (!validateCertificate) {
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return IOClient(httpClient);
    }
    return http.Client();
  }

  static const String endpointSubmitCustomerCare = '/api/CustomerCare/Submit';

  // Notification Configuration
  static const notificationConfig = NotificationConfig(
    maxRetries: 3,
    retryDelay: Duration(seconds: 2),
    maxStored: 100,
    fetchInterval: Duration(minutes: 15),
    minFetchInterval: Duration(minutes: 13),
  );
}

class NotificationConfig {
  final int maxRetries;
  final Duration retryDelay;
  final int maxStored;
  final Duration fetchInterval;
  final Duration minFetchInterval;

  const NotificationConfig({
    required this.maxRetries,
    required this.retryDelay,
    required this.maxStored,
    required this.fetchInterval,
    required this.minFetchInterval,
  });
}
