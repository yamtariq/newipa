import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import '../../services/auth_service.dart';
import '../../widgets/device_dialogs.dart';
import '../main_page.dart';
import '../registration/biometric_setup_screen.dart';
import '../registration/device_replacement_mpin_screen.dart';
import '../registration/device_replacement_biometric_screen.dart';
import 'mpin_setup_screen.dart';
import '../registration/initial_registration_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/otp_dialog.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'forget_password_screen.dart';
import 'forget_mpin_screen.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class SignInScreen extends StatefulWidget {
  final bool isArabic;
  final bool startWithPassword;
  final String? nationalId;
  final bool startWithBiometric;

  const SignInScreen({
    Key? key,
    this.isArabic = false,
    this.startWithPassword = false,
    this.nationalId,
    this.startWithBiometric = false,
  }) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final List<String> _mpinDigits = List.filled(6, '');

  bool _isLoading = false;
  bool _isBiometricsAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isMPINSet = false;
  bool _isPasswordMode = false;
  String? _lastUsedNationalId;
  bool _isTimerActive = false;

  final _formKey = GlobalKey<FormState>();

  Widget _buildCustomDialog({
    required String title,
    required String message,
    required List<Widget> actions,
    IconData? icon,
    Color? iconColor,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? Color(Constants.darkSurfaceColor) 
              : Color(Constants.lightSurfaceColor),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Color(Constants.darkPrimaryShadowColor)
                  : Color(Constants.lightPrimaryShadowColor),
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (iconColor ?? themeColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.info_outline_rounded,
                size: 40,
                color: iconColor ?? themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode 
                    ? Color(Constants.darkLabelTextColor)
                    : Color(Constants.lightLabelTextColor),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: actions.map((action) {
                final isLastAction = action == actions.last;
                if (isLastAction) {
                  return Expanded(child: action);
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: action,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorBanner(String message) {
    if (!mounted) return;
    
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isArabic ? 'تنبيه' : 'Error',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isDarkMode 
            ? Color(Constants.darkSurfaceColor)
            : Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.nationalId != null) {
      _nationalIdController.text = widget.nationalId!;
    }
    _checkAuthenticationStatus();

    // If startWithBiometric is true, trigger biometric authentication after a short delay
    if (widget.startWithBiometric && widget.nationalId != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _authenticateWithBiometrics();
      });
    }
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Check biometric availability
      _isBiometricsAvailable = await _authService.checkBiometricsAvailable();
      if (_isBiometricsAvailable) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }

      // Check if MPIN is set
      _isMPINSet = await _authService.isMPINSet();

      // Check if biometrics are enabled
      final isBiometricEnabled = await _authService.isBiometricEnabled();

      // Get last used national ID if device is registered
      final isDeviceRegistered = await _authService.isDeviceRegistered();
      if (isDeviceRegistered) {
        final prefs = await SharedPreferences.getInstance();
        _lastUsedNationalId = prefs.getString('device_user_id');
        if (_lastUsedNationalId != null) {
          _nationalIdController.text = _lastUsedNationalId!;
        }
      }

      // Check if this device is registered for the current user
      bool isDeviceRegisteredForUser = false;
      if (_lastUsedNationalId != null) {
        isDeviceRegisteredForUser =
            await _authService.isDeviceRegisteredToUser(_lastUsedNationalId!);
      }

      setState(() {
        // If device is registered for this user, never use password mode
        if (isDeviceRegisteredForUser) {
          _isPasswordMode = false;
        } else {
          // If not registered, respect startWithPassword parameter or fallback to quick sign-in if available
          _isPasswordMode =
              widget.startWithPassword || !(isBiometricEnabled || _isMPINSet);
        }
      });

      // If biometric is enabled and we have the user ID, trigger biometric auth
      if (isBiometricEnabled &&
          _lastUsedNationalId != null &&
          !_isPasswordMode &&
          _isBiometricsAvailable) {
        // Add slight delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _authenticateWithBiometrics();
        });
      }

      print('Auth Status Check:');
      print('- Biometrics Available: $_isBiometricsAvailable');
      print('- MPIN Set: $_isMPINSet');
      print('- Device Registered: $isDeviceRegistered');
      print('- Device Registered For User: $isDeviceRegisteredForUser');
      print('- Last Used ID: $_lastUsedNationalId');
      print('- Password Mode: $_isPasswordMode');
    } catch (e) {
      print('Error checking authentication status: $e');
    }
  }

  Future<void> _handleSignInResponse(Map<String, dynamic> response) async {
    print('\n=== HANDLE SIGN IN RESPONSE START ===');
    print('Response data: ${json.encode(response)}');

    if (response['status'] == 'success') {
      // Reset manual sign off flag in session provider
      Provider.of<SessionProvider>(context, listen: false).resetManualSignOff();

      try {
        // For quick sign-in (MPIN/biometric), go directly to main page
        if (!_isPasswordMode) {
          print('Quick sign-in successful, navigating to main page');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  isArabic: widget.isArabic,
                  onLanguageChanged: (bool newIsArabic) {
                    // Handle language change if needed
                  },
                  userData: response['user'] ?? {},
                  isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                ),
              ),
            );
          }
          return;
        }

        // For password sign-in, always register this device
        print('Registering current device...');
        final registerResponse = await _authService.registerDevice(
          nationalId: _nationalIdController.text,
        );

        if (registerResponse['status'] == 'success') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MPINSetupScreen(
                  isArabic: widget.isArabic,
                  nationalId: _nationalIdController.text,
                  password: _passwordController.text,
                  user: response['user'] ?? {},
                  showSteps: false,
                ),
              ),
            );
          }
        } else {
          throw Exception(registerResponse['message'] ?? 'Failed to register device');
        }
      } catch (e, stackTrace) {
        print('Error during sign in process: $e\n$stackTrace');
        if (mounted) {
          _showErrorBanner(
            widget.isArabic
                ? 'حدث خطأ أثناء تسجيل الدخول'
                : 'Error during sign in process'
          );
        }
      }
    } else {
      print('Sign in failed with code: ${response['code']}');

      switch (response['code']) {
        case 'CUSTOMER_NOT_FOUND':
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildCustomDialog(
                title: widget.isArabic ? 'مستخدم جديد' : 'New User',
                message: widget.isArabic
                    ? 'لم يتم العثور على حسابك. هل تريد إنشاء حساب جديد؟'
                    : 'Your account was not found. Would you like to create a new account?',
                icon: Icons.person_add_rounded,
                iconColor: Colors.red[700],
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'إلغاء' : 'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _initiateUserRegistration();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'تسجيل' : 'Register',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          break;

        case 'INVALID_PASSWORD':
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildCustomDialog(
                title: widget.isArabic ? 'تنبيه' : 'Alert',
                message: widget.isArabic
                    ? 'كلمة المرور غير صحيحة. الرجاء المحاولة مرة أخرى.'
                    : 'Invalid password. Please try again.',
                icon: Icons.lock_outline,
                iconColor: Colors.red[700],
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Clear password field
                      _passwordController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'موافق' : 'OK',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          break;

        case 'INVALID_MPIN':
        case 'BIOMETRIC_VERIFICATION_FAILED':
          // These cases are handled locally, just show error message
          _showErrorBanner(
            widget.isArabic ? 'فشل التحقق' : 'Verification failed'
          );
          break;

        default:
          if (mounted) {
            _showErrorBanner(
              widget.isArabic
                  ? response['message_ar'] ?? 'حدث خطأ أثناء تسجيل الدخول'
                  : response['message'] ?? 'Error during sign in process'
            );
          }
      }
    }
    print('=== HANDLE SIGN IN RESPONSE END ===\n');
  }

  Future<void> _authenticateWithBiometrics() async {
    print('=== BIOMETRIC AUTHENTICATION START ===');
    if (_nationalIdController.text.isEmpty) {
      print('National ID is empty, showing error');
      _showErrorBanner(
        widget.isArabic
            ? 'يرجى إدخال رقم الهوية أولاً'
            : 'Please enter your National ID first'
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isPasswordMode = false; // Ensure we're in quick sign-in mode
    });

    try {
      print('Requesting biometric authentication...');
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: widget.isArabic
            ? 'قم بتسجيل السمات الحيوية للمتابعة'
            : 'Authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
      print('Biometric authentication result: $didAuthenticate');

      if (mounted && didAuthenticate) {
        print('Verifying biometric with backend...');
        final result = await _authService.verifyBiometric(
          nationalId: _nationalIdController.text,
        );
        print('Backend verification result: ${json.encode(result)}');

        await _handleSignInResponse(result);
      }
    } catch (e, stackTrace) {
      print('Error during biometric authentication:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorBanner(
          widget.isArabic
              ? 'حدث خطأ أثناء التحقق'
              : 'Authentication error occurred'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== BIOMETRIC AUTHENTICATION END ===');
    }
  }

  Future<void> _authenticateWithMPIN() async {
    print('=== MPIN AUTHENTICATION START ===');
    if (_mpinDigits.contains('')) {
      print('MPIN is incomplete');
      return;
    }

    setState(() {
      _isLoading = true;
      _isPasswordMode = false; // Ensure we're in quick sign-in mode
    });

    try {
      final mpin = _mpinDigits.join();
      print('Verifying MPIN locally...');
      // First verify MPIN locally
      final isValid = await _authService.verifyMPIN(mpin);
      print('Local MPIN verification result: $isValid');

      if (!isValid) {
        print('Invalid MPIN, showing error');
        _showErrorBanner(
          widget.isArabic ? 'رمز الدخول غير صحيح' : 'Invalid MPIN'
        );
        // Clear MPIN on error
        setState(() {
          _mpinDigits.fillRange(0, _mpinDigits.length, '');
        });
        return;
      }

      print('Verifying device and getting token...');
      final result = await _authService.signIn(
        nationalId: _nationalIdController.text,
      );
      print('Device verification result: ${json.encode(result)}');

      await _handleSignInResponse(result);
    } catch (e, stackTrace) {
      print('Error during MPIN authentication:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorBanner(
          widget.isArabic
              ? 'حدث خطأ أثناء التحقق'
              : 'Authentication error occurred'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== MPIN AUTHENTICATION END ===');
    }
  }

  Future<void> _authenticateWithPassword() async {
    print('\n=== PASSWORD AUTHENTICATION START ===');
    if (_nationalIdController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorBanner(
        widget.isArabic
            ? 'يرجى إدخال رقم الهوية وكلمة المرور'
            : 'Please enter both National ID and password'
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Attempting login with:');
      print('- National ID: ${_nationalIdController.text}');

      final result = await _authService.signIn(
        nationalId: _nationalIdController.text,
        password: _passwordController.text,
      );

      print('Login API Response:');
      print(json.encode(result));

      await _handleSignInResponse(result);
    } catch (e, stackTrace) {
      print('Error during password authentication:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorBanner(
          widget.isArabic
              ? 'حدث خطأ أثناء تسجيل الدخول'
              : 'An error occurred during sign in'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== PASSWORD AUTHENTICATION END ===\n');
    }
  }

  void _onNextPressed() async {
    if (_nationalIdController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorBanner(
        widget.isArabic
            ? 'يرجى إدخال رقم الهوية وكلمة المرور'
            : 'Please enter both National ID and password'
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isTimerActive = true;
    });

    // Start 10-second timer
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isTimerActive = false;
        });
      }
    });

    try {
      // Step 1 & 2: Check user exists and verify password
      print('\n=== STARTING SIGN IN PROCESS ===');
      final signInResult = await _authService.signIn(
        nationalId: _nationalIdController.text,
        password: _passwordController.text,
      );

      if (signInResult['status'] != 'success') {
        print('Sign in failed: ${signInResult['code']}');
      await _handleSignInResponse(signInResult);
        return;
      }

      // Step 3: Generate OTP
      print('\n=== GENERATING OTP ===');
      final otpGenResult = await _authService.generateOTP(_nationalIdController.text);
      if (otpGenResult['status'] != 'success') {
        throw Exception(widget.isArabic 
          ? (otpGenResult['message_ar'] ?? 'فشل في إرسال رمز التحقق')
          : (otpGenResult['message'] ?? 'Failed to send OTP'));
      }

      // Step 4: Show OTP dialog and verify
      final otpVerified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OTPDialog(
          nationalId: _nationalIdController.text,
          isArabic: widget.isArabic,
          onResendOTP: _resendOTP,
          onVerifyOTP: _verifyOTPCode,
        ),
      );

      if (otpVerified == true) {
        // Step 5: Register device and proceed with sign in
        final deviceRegistration = await _authService.registerDevice(
          nationalId: _nationalIdController.text,
        );

        if (deviceRegistration['status'] != 'success') {
          throw Exception(deviceRegistration['message'] ?? 'Failed to register device');
        }

        // Step 6: Complete sign in process
        await _handleSignInResponse({
          ...signInResult,
          'device_registered': true
        });
      }
    } catch (e) {
      print('Error during sign in process: $e');
      if (mounted) {
        _showErrorBanner(
          widget.isArabic
              ? 'حدث خطأ أثناء تسجيل الدخول'
              : e.toString()
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initiateUserRegistration() async {
    // Navigate to registration screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => InitialRegistrationScreen(
          isArabic: widget.isArabic,
        ),
      ),
    );
  }

  Future<void> _generateOTP(String nationalId) async {
    try {
      print('Generating OTP for ID: $nationalId');
      final response = await _authService.generateOTP(nationalId);
      print('OTP Generation Response: ${json.encode(response)}');

      if (response['status'] != 'success') {
        print('OTP Generation failed with status: ${response['status']}');
        print('Error message: ${response['message']}');
        print('Arabic message: ${response['message_ar']}');
        
        throw Exception(widget.isArabic 
          ? (response['message_ar'] ?? 'فشل في إرسال رمز التحقق')
          : (response['message'] ?? 'Failed to send OTP'));
      }
      
      print('OTP Generated successfully');
    } catch (e) {
      print('Error in _generateOTP: $e');
      if (e is Exception) {
        _showErrorBanner(e.toString().replaceAll('Exception: ', ''));
      } else {
        _showErrorBanner(widget.isArabic 
          ? 'حدث خطأ أثناء إرسال رمز التحقق'
          : 'Error sending OTP');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _resendOTP() async {
    try {
      final response = await _authService.generateOTP(_nationalIdController.text);
      if (response['status'] != 'success') {
        throw Exception(widget.isArabic 
          ? (response['message_ar'] ?? 'فشل في إرسال رمز التحقق')
          : (response['message'] ?? 'Failed to send OTP'));
      }
      return response;
    } catch (e) {
      _showErrorBanner(e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _verifyOTPCode(String otp) async {
    try {
      final response = await _authService.verifyOTP(_nationalIdController.text, otp);
      if (response['status'] != 'success') {
        throw Exception(widget.isArabic 
          ? (response['message_ar'] ?? 'رمز التحقق غير صحيح')
          : (response['message'] ?? 'Invalid OTP'));
      }
      return response;
    } catch (e) {
      _showErrorBanner(e.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    final primaryColor = themeColor;

    return WillPopScope(
      onWillPop: () async {
        return _isPasswordMode;
      },
      child: Directionality(
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: isDarkMode 
              ? Color(Constants.darkBackgroundColor) 
              : Color(Constants.lightBackgroundColor),
          body: SafeArea(
            child: Stack(
              children: [
                // Background Logo
                Positioned(
                  top: -100,
                  right: widget.isArabic ? null : -100,
                  left: widget.isArabic ? -100 : null,
                  child: isDarkMode
                    ? Image.asset(
                        'assets/images/nayifat-circle-grey.png',
                        width: 240,
                        height: 240,
                      )
                    : Opacity(
                        opacity: 0.2,
                        child: Image.asset(
                          'assets/images/nayifatlogocircle-nobg.png',
                          width: 240,
                          height: 240,
                        ),
                      ),
                ),

                // Main Content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 100),

                      // Title
                      Text(
                        widget.isArabic ? 'تسجيل الدخول' : 'Sign In',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Authentication Methods
                      if (!_isPasswordMode) ...[
                        if (_isBiometricsAvailable) ...[
                          FutureBuilder<bool>(
                            future: _authService.isBiometricEnabled(),
                            builder: (context, snapshot) {
                              final isBiometricEnabled = snapshot.data ?? false;
                              
                              if (isBiometricEnabled) {
                                return _buildAuthButton(
                                  icon: Icons.fingerprint,
                                  title: widget.isArabic
                                      ? 'السمات الحيوية'
                                      : 'Biometrics Authentication',
                                  subtitle: widget.isArabic
                                      ? 'استخدم السمات الحيوية لتسجيل الدخول'
                                      : 'Use your biometrics to sign in',
                                  onTap: _authenticateWithBiometrics,
                                );
                              } else {
                                return _buildAuthButton(
                                  icon: Icons.fingerprint,
                                  title: widget.isArabic
                                      ? 'تفعيل السمات الحيوية'
                                      : 'Enable Biometrics',
                                  subtitle: widget.isArabic
                                      ? 'قم بتفعيل السمات الحيوية للدخول السريع'
                                      : 'Enable biometrics for quick sign-in',
                                  onTap: () async {
                                    final success = await _authService.enableBiometrics(_nationalIdController.text);
                                    if (success && mounted) {
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            widget.isArabic
                                                ? 'تم تفعيل السمات الحيوية بنجاح'
                                                : 'Biometrics enabled successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                );
                              }
                            },
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Only show password option if device is not registered for this user
                        FutureBuilder<bool>(
                          future: _lastUsedNationalId != null
                              ? _authService.isDeviceRegisteredToUser(_lastUsedNationalId!)
                              : Future.value(false),
                          builder: (context, snapshot) {
                            final isRegistered = snapshot.data ?? false;
                            if (!isRegistered) {
                              return TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordMode = !_isPasswordMode;
                                    _passwordController.clear();
                                    _mpinDigits.fillRange(
                                        0, _mpinDigits.length, '');
                                  });
                                },
                                child: Text(
                                  widget.isArabic
                                      ? 'تسجيل الدخول باستخدام كلمة المرور'
                                      : 'Sign In with Password',
                                  style: TextStyle(color: primaryColor),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],

                      if (_isPasswordMode) ...[
                        _buildNationalIdInput(),
                        const SizedBox(height: 20),
                        _buildPasswordInput(),
                        const SizedBox(height: 20),
                      ] else if (_isMPINSet) ...[
                        const SizedBox(height: 20),
                        _buildMPINInput(),
                        const SizedBox(height: 20),
                        // Add Forgot MPIN link
                        Align(
                          alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _isTimerActive ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetMPINScreen(
                                    isArabic: widget.isArabic,
                                    nationalId: _nationalIdController.text,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                            ),
                            child: Text(
                              widget.isArabic ? 'نسيت رمز الدخول السريع؟' : 'Forgot MPIN?',
                              style: TextStyle(
                                color: _isTimerActive ? Colors.grey : const Color(0xFF0077B6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Sign In Button - only show in password mode
                      if (_isPasswordMode)
                        ElevatedButton(
                          onPressed: (_isLoading || _isTimerActive)
                              ? null
                              : () {
                                  _onNextPressed();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isArabic ? 'دخول' : 'Sign In',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                      if (_isPasswordMode) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isTimerActive ? null : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainPage(
                                  isArabic: widget.isArabic,
                                  onLanguageChanged: (bool newIsArabic) {
                                    // Handle language change if needed
                                  },
                                  userData: {},  // Pass empty map for unauthenticated user
                                  isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            widget.isArabic ? 'إلغاء' : 'Cancel',
                            style: TextStyle(
                              color: _isTimerActive 
                                ? Colors.grey[400] 
                                : (isDarkMode 
                                    ? Color(Constants.darkLabelTextColor)
                                    : Color(Constants.lightLabelTextColor)),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    return Card(
      elevation: 0,
      color: isDarkMode 
          ? Color(Constants.darkFormBackgroundColor)
          : Color(Constants.lightFormBackgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        side: BorderSide(
          color: isDarkMode 
              ? Color(Constants.darkFormBorderColor)
              : Color(Constants.lightFormBorderColor),
        ),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Icon(icon, size: 32, color: themeColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode 
                            ? Color(Constants.darkLabelTextColor)
                            : Color(Constants.lightLabelTextColor),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode 
                            ? Color(Constants.darkHintTextColor)
                            : Color(Constants.lightHintTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode 
                    ? Color(Constants.darkIconColor)
                    : Color(Constants.lightIconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMPINInput() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final bool isFilled = _mpinDigits[index].isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? themeColor : Colors.transparent,
                  border: Border.all(
                    color: isFilled 
                        ? themeColor 
                        : (isDarkMode 
                            ? Color(Constants.darkFormBorderColor)
                            : Color(Constants.lightFormBorderColor)),
                    width: 2,
                  ),
                  boxShadow: isFilled ? [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['1', '2', '3']
                      .map((number) => _buildNumpadButton(number))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['4', '5', '6']
                      .map((number) => _buildNumpadButton(number))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['7', '8', '9']
                      .map((number) => _buildNumpadButton(number))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumpadButton('C', isSpecial: true),
                    _buildNumpadButton('0'),
                    _buildNumpadButton('⌫', isSpecial: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String value, {bool isSpecial = false}) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    final bool isBackspace = value == '⌫';
    final bool isClear = value == 'C';
    
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode 
              ? Color(Constants.darkFormBackgroundColor)
              : (isSpecial ? themeColor : Colors.white),
          gradient: !isSpecial ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? [
              Color(Constants.darkGradientStartColor),
              Color(Constants.darkGradientEndColor),
            ] : [
              Colors.white,
              Colors.white,
            ],
          ) : null,
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Color(Constants.darkPrimaryShadowColor)
                  : Color(Constants.lightPrimaryShadowColor),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: isDarkMode 
                  ? Color(Constants.darkSecondaryShadowColor)
                  : Color(Constants.lightSecondaryShadowColor),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isBackspace) {
                  _handleMPINBackspace();
                } else if (isClear) {
                  _handleMPINClear();
                } else {
                  _handleMPINKeyPress(value);
                }
              },
              splashColor: themeColor.withOpacity(0.1),
              highlightColor: themeColor.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode 
                        ? Color(Constants.darkFormBorderColor)
                        : (isSpecial ? Colors.transparent : Color(Constants.lightFormBorderColor)),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isBackspace
                      ? Icon(
                          Icons.backspace_rounded,
                          color: isDarkMode ? themeColor : Colors.white,
                          size: 28,
                        )
                      : isClear
                          ? Text(
                              'C',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w100,
                                color: isDarkMode ? themeColor : Colors.white,
                                letterSpacing: 1,
                              ),
                            )
                          : Text(
                              value,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode 
                                    ? Color(Constants.darkLabelTextColor)
                                    : Color(Constants.lightLabelTextColor),
                                letterSpacing: 1,
                              ),
                            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleMPINKeyPress(String value) {
    setState(() {
      final emptyIndex = _mpinDigits.indexOf('');
      if (emptyIndex != -1) {
        _mpinDigits[emptyIndex] = value;

        // If MPIN is complete, automatically verify
        if (!_mpinDigits.contains('')) {
          _authenticateWithMPIN();
        }
      }
    });
  }

  void _handleMPINBackspace() {
    setState(() {
      final lastFilledIndex =
          _mpinDigits.lastIndexWhere((digit) => digit.isNotEmpty);
      if (lastFilledIndex != -1) {
        _mpinDigits[lastFilledIndex] = '';
      }
    });
  }

  void _handleMPINClear() {
    setState(() {
      _mpinDigits.fillRange(0, _mpinDigits.length, '');
    });
  }

  Widget _buildNationalIdInput() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    return TextFormField(
      controller: _nationalIdController,
      enabled: !_isTimerActive,
      decoration: InputDecoration(
        labelText: widget.isArabic ? 'رقم الهوية أو الإقامة' : 'National or Iqama ID',
        hintText: widget.isArabic ? 'أدخل رقم الهوية أو الإقامة' : 'Enter your National or Iqama ID',
        prefixIcon: Icon(Icons.person_outline, color: themeColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.formBorderRadius),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Color(Constants.darkFormBorderColor)
                : Color(Constants.lightFormBorderColor),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.formBorderRadius),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Color(Constants.darkFormBorderColor)
                : Color(Constants.lightFormBorderColor),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.formBorderRadius),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Color(Constants.darkFormFocusedBorderColor)
                : Color(Constants.lightFormFocusedBorderColor),
          ),
        ),
        filled: true,
        fillColor: isDarkMode 
            ? Color(Constants.darkFormBackgroundColor)
            : Color(Constants.lightFormBackgroundColor),
        labelStyle: TextStyle(
          color: isDarkMode 
              ? Color(Constants.darkLabelTextColor)
              : Color(Constants.lightLabelTextColor),
        ),
        hintStyle: TextStyle(
          color: isDarkMode 
              ? Color(Constants.darkHintTextColor)
              : Color(Constants.lightHintTextColor),
        ),
      ),
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDarkMode 
            ? Color(Constants.darkLabelTextColor)
            : Color(Constants.lightLabelTextColor),
      ),
    );
  }

  Widget _buildPasswordInput() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _passwordController,
          enabled: !_isTimerActive,
          decoration: InputDecoration(
            labelText: widget.isArabic ? 'كلمة المرور' : 'Password',
            hintText: widget.isArabic ? 'أدخل كلمة المرور' : 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline, color: themeColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
              borderSide: BorderSide(
                color: isDarkMode 
                    ? Color(Constants.darkFormBorderColor)
                    : Color(Constants.lightFormBorderColor),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
              borderSide: BorderSide(
                color: isDarkMode 
                    ? Color(Constants.darkFormBorderColor)
                    : Color(Constants.lightFormBorderColor),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
              borderSide: BorderSide(
                color: isDarkMode 
                    ? Color(Constants.darkFormFocusedBorderColor)
                    : Color(Constants.lightFormFocusedBorderColor),
              ),
            ),
            filled: true,
            fillColor: isDarkMode 
                ? Color(Constants.darkFormBackgroundColor)
                : Color(Constants.lightFormBackgroundColor),
            labelStyle: TextStyle(
              color: isDarkMode 
                  ? Color(Constants.darkLabelTextColor)
                  : Color(Constants.lightLabelTextColor),
            ),
            hintStyle: TextStyle(
              color: isDarkMode 
                  ? Color(Constants.darkHintTextColor)
                  : Color(Constants.lightHintTextColor),
            ),
          ),
          obscureText: true,
          style: TextStyle(
            color: isDarkMode 
                ? Color(Constants.darkLabelTextColor)
                : Color(Constants.lightLabelTextColor),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: widget.isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: TextButton(
            onPressed: _isTimerActive ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForgetPasswordScreen(
                    isArabic: widget.isArabic,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            child: Text(
              widget.isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
              style: TextStyle(
                color: _isTimerActive 
                    ? Colors.grey 
                    : themeColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
