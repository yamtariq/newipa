import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import '../main_page.dart';
import 'registration_success_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class BiometricSetupScreen extends StatefulWidget {
  final String nationalId;
  final String password;
  final String mpin;
  final bool isArabic;
  final bool showSteps;
  final Function(bool) onSetupComplete;

  const BiometricSetupScreen({
    Key? key,
    required this.nationalId,
    required this.password,
    required this.mpin,
    required this.onSetupComplete,
    this.isArabic = false,
    this.showSteps = false,
  }) : super(key: key);

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _authService = AuthService();
  final _registrationService = RegistrationService();
  bool _isLoading = false;
  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
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

  Future<void> _enableBiometrics() async {
    setState(() => _isLoading = true);

    try {
      // Get available biometrics
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
        setState(() => _isBiometricsEnabled = true);
      }
    } catch (e) {
      print('Error enabling biometrics: $e');
      if (mounted) {
        final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        final errorColor = Color(isDarkMode 
            ? Constants.darkFormBorderColor 
            : Constants.lightFormBorderColor);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ أثناء تفعيل السمات الحيوية'
                  : 'Error enabling biometrics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: errorColor,
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
      // 1. Complete registration with biometric preference
      final registrationResult = await _registrationService.completeRegistration(
        nationalId: widget.nationalId,
        password: widget.password,
        mpin: widget.mpin,
        enableBiometric: _isBiometricsEnabled,
      );

      if (!registrationResult) {
        throw Exception(widget.isArabic
            ? 'فشل إكمال التسجيل'
            : 'Failed to complete registration');
      }

      // 2. Get stored registration data
      final storedData = await _registrationService.getStoredRegistrationData();
      if (storedData == null || storedData['userData'] == null) {
        throw Exception(widget.isArabic
            ? 'بيانات المستخدم غير متوفرة'
            : 'User data not available');
      }

      // 3. Store user data locally
      final userData = <String, dynamic>{
        ...(storedData['userData'] as Map<String, dynamic>),
        'email': storedData['email'],
        'isSessionActive': true,
      };
      await _authService.storeUserData(userData);

      // 4. Store device registration
      await _authService.storeDeviceRegistration(widget.nationalId);

      // 5. Start user session
      await _authService.startSession(
        widget.nationalId,
        userId: storedData['userData']['id']?.toString(),
      );

      if (!mounted) return;

      // 6. Initialize session in provider
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.resetManualSignOff();
      sessionProvider.setSignedIn(true);
      await sessionProvider.initializeSession();

      // 7. Show success dialog and navigate to main page
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RegistrationSuccessDialog(
          isArabic: widget.isArabic,
          enableBiometric: _isBiometricsEnabled,
          onContinue: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  isArabic: widget.isArabic,
                  onLanguageChanged: (bool value) {},
                  userData: {
                    ...userData,
                    'deviceRegistered': true,
                    'deviceUserId': widget.nationalId,
                  },
                  initialRoute: '',
                  isDarkMode: Provider.of<ThemeProvider>(context).isDarkMode,
                ),
              ),
              (route) => false,
            );
          },
        ),
      );

      // 8. Notify parent about completion
      widget.onSetupComplete(_isBiometricsEnabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final backgroundColor = Color(isDarkMode 
        ? Constants.darkBackgroundColor 
        : Constants.lightBackgroundColor);
    final surfaceColor = Color(isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final labelTextColor = Color(isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintTextColor = Color(isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);
    final formBackgroundColor = Color(isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);
    final formBorderColor = Color(isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);
    final inactiveColor = Color(isDarkMode 
        ? Constants.darkFormBackgroundColor 
        : Constants.lightFormBackgroundColor);
    final inactiveBorderColor = Color(isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: constraints.maxHeight < 600 
                    ? const AlwaysScrollableScrollPhysics() 
                    : const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: [
                        // Background Logo
                        Positioned(
                          top: -75,
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

                        Column(
                          children: [
                            const SizedBox(height: 40),
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

                            if (widget.showSteps) ...[
                              // Progress Indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(3 * 2 - 1, (index) {
                                        if (index % 2 == 0) {
                                          final stepIndex = index ~/ 2;
                                          final isActive = stepIndex == 2;
                                          final isPast = stepIndex < 2;
                                          return Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isActive || isPast ? themeColor : inactiveColor,
                                              border: Border.all(
                                                color: isActive || isPast ? themeColor : inactiveBorderColor,
                                                width: 1,
                                              ),
                                              boxShadow: isActive ? [
                                                BoxShadow(
                                                  color: themeColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ] : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                widget.isArabic 
                                                    ? '${3 - stepIndex}'
                                                    : '${stepIndex + 1}',
                                                style: TextStyle(
                                                  color: isActive || isPast
                                                      ? (isDarkMode ? Colors.black : Colors.white)
                                                      : labelTextColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          final stepIndex = index ~/ 2;
                                          final isPastLine = stepIndex < 2;
                                          return Container(
                                            width: 60,
                                            height: 2,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isPastLine ? [
                                                  themeColor,
                                                  themeColor,
                                                ] : [
                                                  themeColor.withOpacity(0.5),
                                                  inactiveBorderColor,
                                                ],
                                              ),
                                            ),
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                          );
                                        }
                                      }),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(3 * 2 - 1, (index) {
                                        if (index % 2 == 0) {
                                          final stepIndex = index ~/ 2;
                                          final steps = widget.isArabic
                                              ? ['رمز الدخول', 'كلمة المرور', 'معلومات']
                                              : ['Basic', 'Password', 'MPIN'];
                                          final isActive = stepIndex == 2;
                                          final isPast = stepIndex < 2;
                                          return SizedBox(
                                            width: 80,
                                            child: Text(
                                              steps[stepIndex],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isActive || isPast 
                                                    ? themeColor 
                                                    : labelTextColor,
                                                fontWeight: isActive || isPast 
                                                    ? FontWeight.bold 
                                                    : FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        } else {
                                          return const SizedBox(width: 40);
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: inactiveBorderColor,
                              ),
                            ],

                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.fingerprint,
                                              size: 84,
                                              color: _isBiometricsEnabled ? Colors.green : themeColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '/',
                                              style: TextStyle(
                                                fontSize: 90,
                                                color: _isBiometricsEnabled ? Colors.green : themeColor,
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
                                                  color: _isBiometricsEnabled ? Colors.green : themeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          widget.isArabic
                                              ? 'تسجيل الدخول بالسمات الحيوية'
                                              : 'Biometric Login',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: labelTextColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          widget.isArabic
                                              ? 'يمكنك تسجيل الدخول باستخدام بصمة الإصبع أو بصمة الوجه'
                                              : 'You can sign in using your fingerprint or face ID',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: hintTextColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 32),
                                        if (!_isBiometricsAvailable)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: formBackgroundColor,
                                              borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                                              border: Border.all(
                                                color: formBorderColor,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: themeColor.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
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
                                                    color: labelTextColor,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (!_isBiometricsEnabled)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 100),
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _enableBiometrics,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: themeColor,
                                                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 32,
                                                  vertical: 16,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                            isDarkMode ? Colors.black : Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      widget.isArabic
                                                          ? 'تفعيل'
                                                          : 'Enable',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: isDarkMode ? Colors.black : Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          )
                                        else
                                          Column(
                                            children: [
                                              const Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.green,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                widget.isArabic
                                                    ? 'تم تفعيل السمات الحيوية بنجاح'
                                                    : 'Biometrics enabled successfully',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom button
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _handleSetup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: themeColor,
                                        foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                        ),
                                      ),
                                      child: Text(
                                        widget.isArabic ? 'التالي' : 'Next',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDarkMode ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FaceIDPainter extends CustomPainter {
  final Color color;

  FaceIDPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Draw the J-shaped nose and smile
    final path = Path()
      ..moveTo(size.width * 0.4, size.height * 0.3)  // Start from top of J
      ..lineTo(size.width * 0.4, size.height * 0.5)  // Vertical line of J
      ..quadraticBezierTo(
        size.width * 0.4,  // Control point
        size.height * 0.6,  // Control point
        size.width * 0.5,  // End point
        size.height * 0.6,  // End point
      )  // Curve of J
      ..moveTo(size.width * 0.3, size.height * 0.7)  // Start of smile
      ..quadraticBezierTo(
        size.width * 0.5,  // Control point
        size.height * 0.8,  // Control point
        size.width * 0.7,  // End point
        size.height * 0.7,  // End point
      );  // Smile curve

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
