import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import '../main_page.dart';
import 'registration_success_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';

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
      final registrationResult = await _registrationService.completeRegistration(
        nationalId: widget.nationalId,
        password: widget.password,
        mpin: widget.mpin,
        enableBiometric: _isBiometricsEnabled,
      );

      if (registrationResult) {
        print('Registration successful, showing success dialog');
        if (widget.onSetupComplete != null) {
          widget.onSetupComplete(_isBiometricsEnabled);
        }

        final storedData = await _registrationService.getStoredRegistrationData();
        print('Stored data for MainPage: $storedData');
        print('UserData being passed to MainPage: ${storedData?['userData']}');

        if (storedData == null || storedData['userData'] == null) {
          print('Warning: storedData or userData is null!');
        }

        print('\n=== STORING USER DATA ===');
        final userData = <String, dynamic>{
          ...(storedData?['userData'] as Map<String, dynamic>? ?? {}),
          'email': storedData?['email'],
          'isSessionActive': true,
        };
        await _authService.storeUserData(userData);
        print('User data being stored: $userData');
        print('=== USER DATA STORED ===\n');

        print('\n=== STORING DEVICE REGISTRATION ===');
        await _authService.storeDeviceRegistration(widget.nationalId);
        print('=== DEVICE REGISTRATION STORED ===\n');

        print('\n=== STARTING SESSION ===');
        await _authService.startSession(
          widget.nationalId,
          userId: storedData?['userData']?['id']?.toString(),
        );
        print('=== SESSION STARTED ===\n');

        if (!mounted) return;

        print('\n=== INITIALIZING SESSION IN PROVIDER ===');
        print('1. Getting session provider');
        final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
        print('2. Current session state: ${sessionProvider.isSignedIn}');
        
        print('3. Resetting manual sign off');
        sessionProvider.resetManualSignOff();
        
        print('4. Setting signed in state to true');
        sessionProvider.setSignedIn(true);
        
        print('5. Initializing session');
        await sessionProvider.initializeSession();
        
        print('6. Verifying session state after update');
        final updatedSignedIn = Provider.of<SessionProvider>(context, listen: false).isSignedIn;
        print('   - Updated signed in state: $updatedSignedIn');
        print('=== SESSION INITIALIZED IN PROVIDER ===\n');

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RegistrationSuccessDialog(
            isArabic: widget.isArabic,
            enableBiometric: _isBiometricsEnabled,
            onContinue: () async {
              Navigator.of(context).pop();
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => MainPage(
                    isArabic: widget.isArabic,
                    userData: <String, dynamic>{
                      ...userData,
                      'deviceRegistered': true,
                      'deviceUserId': widget.nationalId,
                    },
                  ),
                ),
                (route) => false,
              );
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'فشل في إكمال التسجيل'
                  : 'Failed to complete registration',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic ? 'حدث خطأ' : 'An error occurred: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0077B6);
    final backgroundColor = const Color(0xFFF5F6FA);

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
                          right: widget.isArabic ? null : -75,
                          left: widget.isArabic ? -75 : null,
                          child: Opacity(
                            opacity: 0.2,
                            child: Image.asset(
                              'assets/images/nayifatlogocircle-nobg.png',
                              width: 200,
                              height: 200,
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
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 60,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
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
                                              color: isActive || isPast
                                                  ? primaryColor
                                                  : Colors.grey[300],
                                            ),
                                            child: Center(
                                              child: Text(
                                                widget.isArabic 
                                                    ? '${3 - stepIndex}'
                                                    : '${stepIndex + 1}',
                                                style: TextStyle(
                                                  color: isActive || isPast
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            width: 60,
                                            height: 2,
                                            color: Colors.grey[300],
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
                                          return SizedBox(
                                            width: 80,
                                            child: Text(
                                              steps[stepIndex],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isActive ? primaryColor : (stepIndex < 2 ? primaryColor : Colors.grey[600]),
                                                fontWeight: isActive ? FontWeight.bold : (stepIndex < 2 ? FontWeight.bold : FontWeight.normal),
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        } else {
                                          return SizedBox(width: 40);
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ],

                            Expanded(
                              child: Column(
                                // mainAxisAlignment: MainAxisAlignment.center,
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
                                              color: _isBiometricsEnabled ? Colors.green : primaryColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '/',
                                              style: TextStyle(
                                                fontSize: 90,
                                                color: _isBiometricsEnabled ? Colors.green : primaryColor,
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
                                                  color: _isBiometricsEnabled ? Colors.green : primaryColor,
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
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
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
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 32),
                                        if (!_isBiometricsAvailable)
                                          Text(
                                            widget.isArabic
                                                ? 'السمات الحيوية غير متوفرة على هذا الجهاز'
                                                : 'Biometrics not available on this device',
                                            style: TextStyle(color: Colors.red),
                                            textAlign: TextAlign.center,
                                          )
                                        else if (!_isBiometricsEnabled)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 100),
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _enableBiometrics,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 32,
                                                  vertical: 16,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                            Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      widget.isArabic
                                                          ? 'تفعيل'
                                                          : 'Enable',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          )
                                        else
                                          Column(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.green,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                widget.isArabic
                                                    ? 'تم تفعيل السمات الحيوية بنجاح'
                                                    : 'Biometrics enabled successfully',
                                                style: TextStyle(
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
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _handleSetup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        widget.isArabic ? 'التالي' : 'Next',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
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
