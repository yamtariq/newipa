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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

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
  late TextEditingController _nationalIdController;
  late TextEditingController _passwordController;
  final List<String> _mpinDigits = List.filled(6, '');

  bool _isLoading = false;
  bool _isBiometricsAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isMPINSet = false;
  bool _isPasswordMode = true;
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
    _initializeScreen();
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
      print('\n=== CHECKING AUTH STATUS ===');
      
      // Check biometric availability
      _isBiometricsAvailable = await _authService.checkBiometricsAvailable();
      if (_isBiometricsAvailable) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
      }

      // Check if MPIN is set
      _isMPINSet = await _authService.isMPINSet();

      // Check if device is registered and get last used national ID
      final isDeviceRegistered = await _authService.isDeviceRegistered();
      final prefs = await SharedPreferences.getInstance();
      _lastUsedNationalId = prefs.getString('device_user_id');
      
      // Check if session is active
      final sessionActive = await _authService.isSessionActive();
      final manualSignOff = Provider.of<SessionProvider>(context, listen: false).manualSignOff;

      setState(() {
        // Show quick sign-in methods only if:
        // 1. Device is registered
        // 2. Has quick sign-in methods available
        // 3. Not manually signed off
        // 4. Not forced to use password
        if (isDeviceRegistered && 
            (_isBiometricsAvailable || _isMPINSet) && 
            !manualSignOff && 
            !widget.startWithPassword) {
          _isPasswordMode = false;
        } else {
          _isPasswordMode = true;
        }
      });

      print('Auth Status Check:');
      print('- Biometrics Available: $_isBiometricsAvailable');
      print('- MPIN Set: $_isMPINSet');
      print('- Device Registered: $isDeviceRegistered');
      print('- Last Used ID: $_lastUsedNationalId');
      print('- Password Mode: $_isPasswordMode');
      print('- Session Active: $sessionActive');
      print('- Manual Sign Off: $manualSignOff');
      print('=== AUTH STATUS CHECK END ===\n');
    } catch (e) {
      print('Error checking authentication status: $e');
      setState(() {
        _isPasswordMode = true;
      });
    }
  }

  Future<void> _handleSignInResponse(Map<String, dynamic> response) async {
    print('\n=== HANDLE SIGN IN RESPONSE START ===');
    print('Response data: ${json.encode(response)}');

    if (response['success'] == true && response['data'] != null) {
      final responseData = response['data'];
      
      try {
        // Step 1: Generate OTP without storing any data
        print('\n=== GENERATING OTP ===');
        final otpGenResult = await _authService.generateOTP(_nationalIdController.text);
        if (otpGenResult['success'] != true) {
          throw Exception(widget.isArabic 
            ? (otpGenResult['message_ar'] ?? 'فشل في إرسال رمز التحقق')
            : (otpGenResult['message'] ?? 'Failed to send OTP'));
        }

        // Step 2: Show OTP dialog and verify
        final otpVerified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => OTPDialog(
            nationalId: _nationalIdController.text,
            isArabic: widget.isArabic,
            onResendOTP: _resendOTP,
            onVerifyOTP: (otp) => _verifyOTPCode(otp, responseData),
          ),
        );

        if (otpVerified == true) {
          print('✅ OTP verification completed, MPIN setup will start automatically');
        } else {
          _showErrorBanner(
            widget.isArabic
                ? 'فشل في التحقق من رمز OTP'
                : 'OTP verification failed'
          );
        }
      } catch (e, stackTrace) {
        print('Error during sign in process: $e\n$stackTrace');
        if (mounted) {
          _showErrorBanner(
            widget.isArabic
                ? 'حدث خطأ أثناء تسجيل الدخول'
                : e.toString()
          );
        }
      }
    } else {
      print('Sign in failed with code: ${response['details']?['code']}');

      final errorCode = response['details']?['code'] ?? 'UNKNOWN_ERROR';
      final errorMessage = widget.isArabic 
          ? (response['details']?['message_ar'] ?? response['error'])
          : (response['error'] ?? 'Unknown error');

      switch (errorCode) {
        case 'CUSTOMER_NOT_FOUND':
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildCustomDialog(
                title: widget.isArabic ? 'مستخدم جديد' : 'New User',
                message: errorMessage,
                icon: Icons.person_add_rounded,
                iconColor: Colors.orange[700],
                actions: [
                  Directionality(
                    textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: widget.isArabic
                          ? [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
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
                              ),
                            ]
                          : [
                              Expanded(
                                child: TextButton(
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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
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
                              ),
                            ],
                    ),
                  ),
                ],
              );
            },
          );
          break;

        case 'PASSWORD_NOT_SET':
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildCustomDialog(
                title: widget.isArabic ? 'تنبيه' : 'Alert',
                message: errorMessage,
                icon: Icons.password_rounded,
                iconColor: Colors.red[700],
                actions: [
                  Directionality(
                    textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetPasswordScreen(
                                    isArabic: widget.isArabic,
                                  ),
                                ),
                              );
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
                              widget.isArabic ? 'تعيين كلمة المرور' : 'Set Password',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
          break;

        case 'INVALID_PASSWORD':
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildCustomDialog(
                title: widget.isArabic ? 'تنبيه' : 'Alert',
                message: errorMessage,
                icon: Icons.lock_outline,
                iconColor: Colors.red[700],
                actions: [
                  Directionality(
                    textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: widget.isArabic
                          ? [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ForgetPasswordScreen(
                                          isArabic: widget.isArabic,
                                        ),
                                      ),
                                    );
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
                                    widget.isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.isArabic ? 'المحاولة مرة أخرى' : 'Try Again',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.isArabic ? 'المحاولة مرة أخرى' : 'Try Again',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ForgetPasswordScreen(
                                            isArabic: widget.isArabic,
                                          ),
                                        ),
                                      );
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
                                    child: Center(
                                      child: Text(
                                      widget.isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    ),
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
          // Clear password field after showing error
          _passwordController.clear();
          break;

        case 'INVALID_MPIN':
        case 'BIOMETRIC_VERIFICATION_FAILED':
          // These cases are handled locally, just show error message
          _showErrorBanner(errorMessage);
          break;

        default:
          if (mounted) {
            _showErrorBanner(errorMessage);
          }
      }
    }
    print('=== HANDLE SIGN IN RESPONSE END ===\n');
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: widget.isArabic
            ? 'استخدم السمات الحيوية لتسجيل الدخول'
            : 'Use biometrics to sign in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        // Get user data from local storage
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');
        if (userDataString == null) {
          throw Exception('User data not found');
        }
        final userData = json.decode(userDataString);

        // Initialize session and reset manual sign off
        final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
        sessionProvider.resetManualSignOff();
        await sessionProvider.initializeSession();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(
                isArabic: widget.isArabic,
                userData: userData,
                isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorBanner(
        widget.isArabic
            ? 'فشل في مصادقة السمات الحيوية'
            : 'Biometric authentication failed',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _authenticateWithMPIN() async {
    if (_isLoading) return;

    final mpin = _mpinDigits.join();
    if (mpin.length != 6) return;

    setState(() => _isLoading = true);

    try {
      // First verify MPIN locally
      final bool isValid = await _authService.verifyMPIN(mpin);
      
      if (isValid) {
        // Get the national ID and user data from secure storage first
        final secureStorage = const FlutterSecureStorage();
        final nationalId = await secureStorage.read(key: 'device_user_id');
        final secureUserData = await secureStorage.read(key: 'user_data');

        if (nationalId == null) {
          throw Exception('Device not registered');
        }

        // Perform MPIN-based login which will handle session initialization
        final loginResult = await _authService.loginWithMPIN(
          nationalId: nationalId,
          mpin: mpin,
        );

        if (loginResult['success'] != true) {
          throw Exception(loginResult['message'] ?? 'MPIN authentication failed');
        }

        // Get user data from secure storage or login result
        Map<String, dynamic> userData;
        if (secureUserData != null) {
          userData = json.decode(secureUserData);
        } else if (loginResult['data']?['user'] != null) {
          userData = loginResult['data']['user'];
          // Store the user data for future use
          await secureStorage.write(
            key: 'user_data',
            value: json.encode(userData)
          );
          // Also store in SharedPreferences for redundancy
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(userData));
        } else {
          throw Exception('User data not available');
        }

        // Initialize session and reset manual sign off
        final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
        sessionProvider.resetManualSignOff();
        await sessionProvider.initializeSession();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(
                isArabic: widget.isArabic,
                userData: userData,
                isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              ),
            ),
          );
        }
      } else {
        _showErrorBanner(
          widget.isArabic ? 'رمز MPIN غير صحيح' : 'Invalid MPIN',
        );
        _mpinDigits.fillRange(0, _mpinDigits.length, '');
        setState(() {});
      }
    } catch (e) {
      print('Error in MPIN authentication: $e');
      _showErrorBanner(
        widget.isArabic
            ? 'فشل في المصادقة باستخدام MPIN'
            : 'MPIN authentication failed',
      );
      _mpinDigits.fillRange(0, _mpinDigits.length, '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              : e.toString()
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      // Step 1: Sign in with credentials
      print('\n=== STARTING SIGN IN PROCESS ===');
      final signInResult = await _authService.signIn(
        nationalId: _nationalIdController.text,
        password: _passwordController.text,
      );

      if (signInResult['success'] != true) {
        print('Sign in failed: ${signInResult['code']}');
        await _handleSignInResponse(signInResult);
        return;
      }

      // Step 2: Generate OTP
      print('\n=== GENERATING OTP ===');
      final otpGenResult = await _authService.generateOTP(_nationalIdController.text);
      if (otpGenResult['success'] != true) {
        throw Exception(widget.isArabic 
          ? (otpGenResult['message_ar'] ?? 'فشل في إرسال رمز التحقق')
          : (otpGenResult['message'] ?? 'Failed to send OTP'));
      }

      // Step 3: Show OTP dialog and verify
      final otpVerified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OTPDialog(
          nationalId: _nationalIdController.text,
          isArabic: widget.isArabic,
          onResendOTP: _resendOTP,
          onVerifyOTP: (otp) => _verifyOTPCode(otp, signInResult['data']),
        ),
      );

      if (otpVerified == true) {
        print('✅ OTP verification completed, MPIN setup will start automatically');
      } else {
        _showErrorBanner(
          widget.isArabic
              ? 'فشل في التحقق من رمز OTP'
              : 'OTP verification failed'
        );
      }
    } catch (e, stackTrace) {
      print('Error during sign in process:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showErrorBanner(
          widget.isArabic
              ? 'حدث خطأ أثناء تسجيل الدخول'
              : e.toString()
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTimerActive = false;
        });
      }
    }
  }

  void _initiateUserRegistration() async {
    // Navigate to registration screen with the entered national ID
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => InitialRegistrationScreen(
          isArabic: widget.isArabic,
          nationalId: _nationalIdController.text,
        ),
      ),
    );
  }

  Future<void> _generateOTP(String nationalId) async {
    try {
      print('Generating OTP for ID: $nationalId');
      final response = await _authService.generateOTP(nationalId);
      print('OTP Generation Response: ${json.encode(response)}');

      if (response['success'] != true) {
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
      if (response['success'] != true) {
        throw Exception(widget.isArabic 
          ? (response['message_ar'] ?? 'فشل في إرسال رمز التحقق')
          : (response['message'] ?? 'Failed to send OTP'));
      }
      
      // Close current OTP dialog and show new one to reset timer
      if (mounted) {
        Navigator.pop(context); // Close current dialog
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => OTPDialog(
            nationalId: _nationalIdController.text,
            isArabic: widget.isArabic,
            onResendOTP: _resendOTP,
            onVerifyOTP: _verifyOTPCode,
          ),
        );
      }
      
      return response;
    } catch (e) {
      _showErrorBanner(e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _verifyOTPCode(String otp, [Map<String, dynamic>? signInData]) async {
    int maxRetries = 3;
    int currentTry = 0;
    
    while (currentTry < maxRetries) {
      try {
        print('\n=== VERIFYING OTP (Attempt ${currentTry + 1}/${maxRetries}) ===');
        print('National ID: ${_nationalIdController.text}');
        print('OTP: $otp');
        
        final response = await _authService.verifyOTP(_nationalIdController.text, otp).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out. Please try again.');
          },
        );
        
        print('OTP Verification Response: ${json.encode(response)}');
        
        if (response['status'] == 'success' && signInData != null) {
          print('✅ OTP verified successfully');

          // Now initialize session and store data after OTP verification
          final responseData = signInData;
          final userData = responseData['user'];
          
          try {
            // Store user data in local storage
            final prefs = await SharedPreferences.getInstance();
            final secureStorage = const FlutterSecureStorage();
            
            // Store access token securely FIRST
            final token = responseData['token'];
            print('\n=== TOKEN STORAGE ===');
            print('Token from response: $token');
            
            if (token != null) {
              await secureStorage.write(key: 'auth_token', value: token);
              print('✅ Auth Token stored successfully');
              
              // Verify token was stored
              final storedToken = await secureStorage.read(key: 'auth_token');
              print('Verification - Stored token exists: ${storedToken != null}');
            } else {
              print('❌ No token found in response data');
              print('Response data structure: ${json.encode(responseData)}');
              throw Exception('No auth token in response');
            }
            
            // Store refresh token securely if available
            final refreshToken = responseData['refresh_token'];
            if (refreshToken != null) {
              await secureStorage.write(key: 'refresh_token', value: refreshToken);
              print('✅ Refresh Token stored successfully');
            }

            // Store session data
            await secureStorage.write(key: 'session_active', value: 'true');
            await secureStorage.write(key: 'session_user_id', value: userData['id']?.toString() ?? _nationalIdController.text);
            print('✅ Session data stored');
            
            // Store user data
            final userDataJson = json.encode({
              ...userData,
              'id_expiry_date': userData['id_expiry_date'] ?? 
                               userData['IdExpiryDate'] ?? 
                               userData['idExpiryDate'] ?? 
                               userData['id_expiry_date_hijri'],
            });
            await prefs.setString('user_data', userDataJson);
            await secureStorage.write(
              key: 'user_data',
              value: userDataJson
            );
            print('\n=== STORED USER DATA ===');
            print('User Data: $userDataJson');
            
            // Store other response data
            final lastLogin = DateTime.now().toIso8601String();
            await prefs.setString('last_login', lastLogin);
            print('Last Login: $lastLogin');
            
            if (responseData['settings'] != null) {
              await prefs.setString('user_settings', json.encode(responseData['settings']));
              print('Settings: ${json.encode(responseData['settings'])}');
            }
            if (responseData['preferences'] != null) {
              await prefs.setString('user_preferences', json.encode(responseData['preferences']));
              print('Preferences: ${json.encode(responseData['preferences'])}');
            }
            print('=== LOCAL STORAGE UPDATED SUCCESSFULLY ===\n');

            // Update session provider state AFTER OTP verification
            final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
            sessionProvider.resetManualSignOff();
            sessionProvider.setSignedIn(true);
            await sessionProvider.initializeSession();

            // Then start session
            await _authService.startSession(_nationalIdController.text, userId: userData['id']?.toString());
            print('Session started successfully');

            if (mounted) {
              try {
                // Return success before showing dialog to close OTP dialog
                Navigator.of(context).pop(true);
                
                // Show success dialog and navigate
                if (mounted) {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return _buildCustomDialog(
                        title: widget.isArabic ? 'تم التحقق بنجاح' : 'Verification Successful',
                        message: widget.isArabic
                            ? 'سنقوم الآن بإعداد رمز الدخول السريع والسمات الحيوية لتسهيل تسجيل الدخول في المستقبل'
                            : 'We will now set up your MPIN and biometrics for easier sign-in in the future',
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.green[700],
                        actions: [
                          Directionality(
                            textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      // Navigate to MPIN setup screen
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MPINSetupScreen(
                                            isArabic: widget.isArabic,
                                            nationalId: _nationalIdController.text,
                                            password: _passwordController.text,
                                            user: userData,
                                            showSteps: false,
                                          ),
                                        ),
                                      );
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
                                      widget.isArabic ? 'متابعة' : 'Continue',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                }
              } catch (error) {
                print('Error in OTP verification flow: $error');
                throw Exception(widget.isArabic 
                  ? 'حدث خطأ أثناء عملية التحقق'
                  : 'Error during verification process');
              }
            }
          } catch (e) {
            print('Error during session initialization: $e');
            throw e;
          }
          return response;
        }
        
        throw Exception(widget.isArabic 
          ? (response['message_ar'] ?? 'رمز التحقق غير صحيح')
          : (response['message'] ?? 'Invalid OTP'));
      } catch (e) {
        currentTry++;
        print('❌ Error verifying OTP (Attempt $currentTry/$maxRetries): $e');
        
        if (e is TimeoutException || (e.toString().contains('Connection closed') && currentTry < maxRetries)) {
          // Show retry dialog for connection issues
          if (mounted) {
            final shouldRetry = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return _buildCustomDialog(
                  title: widget.isArabic ? 'خطأ في الاتصال' : 'Connection Error',
                  message: widget.isArabic
                      ? 'سنقوم بإرسال رمز تحقق جديد. هل تريد المتابعة؟'
                      : 'We will send a new OTP. Would you like to continue?',
                  icon: Icons.error_outline,
                  iconColor: Colors.orange[700],
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        widget.isArabic ? 'إلغاء' : 'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.isArabic ? 'متابعة' : 'Continue'),
                    ),
                  ],
                );
              },
            ) ?? false;

            if (!shouldRetry) {
              break;
            }
            
            // Generate new OTP before continuing
            try {
              await _generateOTP(_nationalIdController.text);
              // Close the current OTP dialog and show a new one
              Navigator.pop(context); // Close current OTP dialog
              await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => OTPDialog(
                  nationalId: _nationalIdController.text,
                  isArabic: widget.isArabic,
                  onResendOTP: _resendOTP,
                  onVerifyOTP: _verifyOTPCode,
                ),
              );
            } catch (otpError) {
              print('Error generating new OTP: $otpError');
              _showErrorBanner(
                widget.isArabic
                    ? 'فشل في إرسال رمز التحقق الجديد'
                    : 'Failed to send new OTP'
              );
              break;
            }
            return {}; // Return empty map to prevent further processing
          }
        }
        
        if (currentTry >= maxRetries || (!e.toString().contains('Connection closed') && !(e is TimeoutException))) {
          _showErrorBanner(
            widget.isArabic
                ? 'فشل في التحقق من الرمز. يرجى المحاولة مرة أخرى'
                : 'Failed to verify OTP. Please try again'
          );
          rethrow;
        }
      }
    }
    
    throw Exception(widget.isArabic 
      ? 'فشل في الاتصال بالخادم. يرجى المحاولة مرة أخرى لاحقاً'
      : 'Failed to connect to server. Please try again later');
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
                        // Show biometric option first if available
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
    
    return Container(
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
          borderRadius: BorderRadius.circular(37.5),
          child: Container(
            width: 75,
            height: 75,
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initializeScreen() async {
    try {
      print('\n=== INITIALIZING SIGN IN SCREEN ===');
      
      // Initialize controllers
      _nationalIdController = TextEditingController();
      _passwordController = TextEditingController();
      
      // Get last used national ID if available
      final prefs = await SharedPreferences.getInstance();
      _lastUsedNationalId = prefs.getString('device_user_id');
      if (_lastUsedNationalId != null) {
        _nationalIdController.text = _lastUsedNationalId!;
      }
      
      // Check authentication status
      await _checkAuthenticationStatus();
      
      print('Screen Initialization Complete');
      print('=== SCREEN INIT END ===\n');
    } catch (e) {
      print('Error initializing screen: $e');
    }
  }
}
