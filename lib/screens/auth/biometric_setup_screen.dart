import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../main_page.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class SignInBiometricSetupScreen extends StatefulWidget {
  final String nationalId;
  final bool isArabic;
  final Function(bool) onSetupComplete;

  const SignInBiometricSetupScreen({
    Key? key,
    required this.nationalId,
    required this.onSetupComplete,
    this.isArabic = false,
  }) : super(key: key);

  @override
  State<SignInBiometricSetupScreen> createState() => _SignInBiometricSetupScreenState();
}

class _SignInBiometricSetupScreenState extends State<SignInBiometricSetupScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadBiometricStatus();
  }

  Future<void> _checkBiometrics() async {
    try {
      // First check if the device has biometric hardware
      final canAuthWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuth = canAuthWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuth) {
        if (mounted) {
          setState(() => _isBiometricsAvailable = false);
        }
        return;
      }

      // Then check if there are any enrolled biometrics
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (mounted) {
        setState(() {
          // Only set as available if we have hardware support AND enrolled biometrics
          _isBiometricsAvailable = canAuth && availableBiometrics.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking biometric availability: $e');
      if (mounted) {
        setState(() {
          _isBiometricsAvailable = false;
        });
      }
    }
  }

  Future<void> _loadBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometrics_enabled_${widget.nationalId}') ?? false;
    if (mounted) {
      setState(() {
        _isBiometricsEnabled = enabled;
      });
    }
  }

  Future<void> _enableBiometrics() async {
    setState(() => _isLoading = true);

    try {
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics');

      String authMessage = widget.isArabic
          ? 'قم بتسجيل السمات الحيوية للمتابعة'
          : 'Authenticate to enable biometric login';

      // Customize message based on available biometrics
      if (availableBiometrics.contains(BiometricType.face)) {
        authMessage = widget.isArabic
            ? 'قم بتسجيل بصمة الوجه للمتابعة'
            : 'Scan your face to enable Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        authMessage = widget.isArabic
            ? 'قم بتسجيل بصمة الإصبع للمتابعة'
            : 'Scan your fingerprint to enable Touch ID';
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: authMessage,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        print('Biometric authentication successful');
        // Save biometric status to both API and local storage
        await _authService.enableBiometric(widget.nationalId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometrics_enabled_${widget.nationalId}', true);
        
        if (mounted) {
          setState(() => _isBiometricsEnabled = true);
        }
        print('Biometrics enabled successfully');
      }
    } catch (e, stackTrace) {
      print('Error enabling biometrics: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ أثناء تفعيل السمات الحيوية'
                  : 'Error enabling biometrics',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSetup() async {
    setState(() => _isLoading = true);
    try {
      print('Handling biometric setup completion');
      
      // Start session before completing setup
      try {
        await _authService.startSession(widget.nationalId);
        print('Session started successfully');
        
        // Store session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSessionActive', true);
        
        // Store user session in AuthService
        await _authService.storeUserData({
          'isSessionActive': true,
          'lastSessionStart': DateTime.now().toIso8601String(),
        });
        
      } catch (e) {
        print('Error starting session: $e');
      }
      
      if (widget.onSetupComplete != null) {
        print('Calling onSetupComplete with biometrics enabled: $_isBiometricsEnabled');
        widget.onSetupComplete(_isBiometricsEnabled);
      } else {
        print('onSetupComplete callback is null');
      }

    } catch (e, stackTrace) {
      print('Error in handleSetup: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? 'حدث خطأ: ${e.toString()}'
                  : 'An error occurred: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode 
        ? Color(Constants.darkPrimaryColor) 
        : Color(Constants.lightPrimaryColor);
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? Color(Constants.darkBackgroundColor)
          : Color(Constants.lightBackgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Title with decoration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(
                    widget.isArabic ? 'السمات الحيوية' : 'Biometrics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isBiometricsEnabled) 
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 120,
                          color: themeColor,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fingerprint,
                              size: 84,
                              color: themeColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '/',
                              style: TextStyle(
                                fontSize: 90,
                                color: themeColor,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              width: 84,
                              height: 84,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/faceid.png',
                                  width: 70,
                                  height: 70,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    Text(
                      _isBiometricsEnabled
                          ? (widget.isArabic 
                              ? 'تم تفعيل السمات الحيوية بنجاح'
                              : 'Biometrics enabled successfully')
                          : (widget.isArabic
                              ? 'قم بتفعيل السمات الحيوية للدخول السريع'
                              : 'Enable biometrics for quick sign-in'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode 
                            ? Color(Constants.darkLabelTextColor)
                            : Color(Constants.lightLabelTextColor),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isBiometricsEnabled
                          ? (widget.isArabic
                              ? 'يمكنك الآن استخدام السمات الحيوية لتسجيل الدخول'
                              : 'You can now use biometrics to sign in')
                          : (widget.isArabic
                              ? 'استخدم السمات الحيوية لتسجيل الدخول بسرعة وأمان'
                              : 'Use biometrics for quick and secure sign-in'),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode 
                            ? Color(Constants.darkHintTextColor)
                            : Color(Constants.lightHintTextColor),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (!_isBiometricsEnabled && _isBiometricsAvailable)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _enableBiometrics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
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
                                widget.isArabic
                                    ? 'تفعيل السمات الحيوية'
                                    : 'Enable Biometrics',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    if (!_isBiometricsAvailable)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Color(Constants.darkFormBackgroundColor)
                              : Color(Constants.lightFormBackgroundColor),
                          borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                          border: Border.all(
                            color: isDarkMode 
                                ? Color(Constants.darkFormBorderColor)
                                : Color(Constants.lightFormBorderColor),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.isArabic
                                  ? 'السمات الحيوية غير متوفرة على هذا الجهاز'
                                  : 'Biometrics not available on this device',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode 
                                    ? Color(Constants.darkLabelTextColor)
                                    : Color(Constants.lightLabelTextColor),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Text(
                            //   widget.isArabic
                            //       ? 'يرجى تفعيل السمات الحيوية في إعدادات الجهاز'
                            //       : 'Please enable biometrics in device settings',
                            //   style: TextStyle(
                            //     fontSize: 14,
                            //     color: isDarkMode 
                            //         ? Color(Constants.darkHintTextColor)
                            //         : Color(Constants.lightHintTextColor),
                            //   ),
                            //   textAlign: TextAlign.center,
                            // ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _isLoading ? null : _handleSetup,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        _isBiometricsEnabled
                            ? (widget.isArabic ? 'التالي' : 'Next')
                            : (widget.isArabic ? 'تخطي' : 'Skip'),
                        style: TextStyle(
                          fontSize: 16,
                          color: _isLoading 
                              ? Colors.grey[400] 
                              : themeColor,
                        ),
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
  }
} 