import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../main_page.dart';

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
  final Color primaryColor = const Color(0xFF0077B6);
  final Color backgroundColor = const Color(0xFFF5F6FA);
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
        print('Biometric authentication successful');
        await _authService.enableBiometric(widget.nationalId);
        setState(() => _isBiometricsEnabled = true);
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
    return Scaffold(
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
                          const SizedBox(height: 100),
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
                                      widget.isArabic ? 'تم' : 'Done',
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
    );
  }
} 