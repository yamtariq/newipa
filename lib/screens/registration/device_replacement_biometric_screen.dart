import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/session_provider.dart';
import '../main_page.dart';
import '../../providers/theme_provider.dart';

class DeviceReplacementBiometricScreen extends StatefulWidget {
  final bool isArabic;
  final Map<String, dynamic> userData;

  const DeviceReplacementBiometricScreen({
    Key? key,
    required this.isArabic,
    required this.userData,
  }) : super(key: key);

  @override
  State<DeviceReplacementBiometricScreen> createState() =>
      _DeviceReplacementBiometricScreenState();
}

class _DeviceReplacementBiometricScreenState
    extends State<DeviceReplacementBiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isBiometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      // Check for hardware support
      final canAuthWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuth = canAuthWithBiometrics || await _localAuth.isDeviceSupported();

      // Get available biometrics
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometric types: $availableBiometrics');

      if (mounted) {
        setState(() {
          // Only set as available if we have either fingerprint or face ID
          _isBiometricsAvailable = canAuth && 
              (availableBiometrics.contains(BiometricType.fingerprint) ||
               availableBiometrics.contains(BiometricType.face));
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
        await _completeDeviceReplacement(enableBiometric: true);
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

  Future<void> _completeDeviceReplacement({required bool enableBiometric}) async {
    try {
      // Store MPIN locally
      await _authService.storeMPIN(widget.userData['mpin']);

      // Get existing user data to preserve IBAN
      final existingUserData = await _authService.getUserData();
      final String? existingIban = existingUserData?['ibanNo'];
      print('Existing IBAN: $existingIban');

      // Replace device registration
      final response = await _authService.registerDevice(
        nationalId: widget.userData['nationalId'],
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Device replacement failed');
      }

      // Store device registration
      await _authService.storeDeviceRegistration(widget.userData['nationalId']);

      if (enableBiometric) {
        await _authService.enableBiometric(widget.userData['nationalId']);
      }

      // Perform sign in to get user data
      final signInResponse = await _authService.signIn(
        nationalId: widget.userData['nationalId'],
        password: widget.userData['password'],
      );

      if (signInResponse['status'] == 'success') {
        // Get the user data and ensure IBAN is preserved
        final userData = Map<String, dynamic>.from(signInResponse['user']);
        
        // Preserve the IBAN if it exists
        if (existingIban != null) {
          print('Preserving IBAN: $existingIban');
          userData['ibanNo'] = existingIban;
        }
        
        // Store user data and tokens
        await _authService.storeUserData(userData);
        if (signInResponse['token'] != null) {
          await _authService.storeToken(signInResponse['token']);
        }

        // Initialize session
        await _authService.startSession(userData['national_id']);
        
        if (mounted) {
          // Reset manual sign off and set signed in state in session provider
          final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
          sessionProvider.resetManualSignOff();
          sessionProvider.setSignedIn(true);
          
          // Navigate directly to main page after successful device replacement
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainPage(
                isArabic: widget.isArabic,
                userData: userData,
                onLanguageChanged: (bool newIsArabic) {
                  // Handle language change if needed
                },
                initialRoute: '',
                isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        throw Exception(signInResponse['message'] ?? 'Error signing in after device replacement');
      }
    } catch (e) {
      print('Error completing device replacement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'حدث خطأ أثناء استبدال الجهاز'
                  : 'Error replacing device: $e',
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
    final backgroundColor = Color(0xFFF5F6FA);
    final primaryColor = Color(0xFF0077B6);

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
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 5),
                          Text(
                                            '/',
                            style: TextStyle(
                                              fontSize: 90,
                              color: primaryColor,
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
                                color: primaryColor,
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
                                      else
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
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom Buttons
                          Container(
                            padding: const EdgeInsets.all(24.0),
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
                                    onPressed: () => _completeDeviceReplacement(enableBiometric: false),
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

                      if (_isLoading)
                        Container(
                          color: Colors.black.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
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