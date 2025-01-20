import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth/mpin_setup_screen.dart';
import 'auth/sign_in_screen.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'customer_service_screen.dart';
import 'cards_page.dart';
import 'loans_page.dart';
import 'cards_page_ar.dart';
import 'loans_page_ar.dart';
import '../screens/main_page.dart';
import 'account_page_ar.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../widgets/otp_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'splash_screen.dart';

class AccountPage extends StatefulWidget {
  final bool isArabic;
  const AccountPage({super.key, this.isArabic = false});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Color primaryColor = const Color(0xFF0077B6);
  String _userName = '';
  bool _isBiometricsEnabled = false;
  bool _isBiometricsAvailable = false;
  String _biometricsError = '';
  String _currentLanguage = 'English';
  bool _isLoading = true;
  int _tabIndex = 4;  // For Account tab (settings)

  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometricsAvailability();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? '';
      final isBiometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;

      setState(() {
        _userName = userName;
        _isBiometricsEnabled = isBiometricsEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBiometricsAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _isBiometricsAvailable = isAvailable && availableBiometrics.isNotEmpty;
        if (!_isBiometricsAvailable) {
          _biometricsError = widget.isArabic 
              ? 'السمات الحيوية غير متوفرة على هذا الجهاز'
              : 'Biometric authentication is not available on this device';
        }
      });
    } catch (e) {
      setState(() {
        _isBiometricsAvailable = false;
        _biometricsError = widget.isArabic 
            ? 'حدث خطأ أثناء التحقق من توفر السمات الحيوية'
            : 'Error checking biometric availability';
      });
    }
  }

  Future<void> _toggleBiometrics() async {
    if (!_isBiometricsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _biometricsError,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      if (_isBiometricsEnabled) {
        // Verify biometrics before disabling
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى المصادقة لتعطيل المصادقة البيومترية'
              : 'Please authenticate to disable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometrics_enabled', false);
        setState(() => _isBiometricsEnabled = false);
      } else {
        // Enable biometrics
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى المصادقة لتمكين المصادقة البيومترية'
              : 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate) return;

        final prefs = await SharedPreferences.getInstance();
        final nationalId = prefs.getString('national_id') ?? '';
        final isEnabled = await _authService.enableBiometrics(nationalId);
        
        if (isEnabled) {
          await prefs.setBool('biometrics_enabled', true);
          setState(() => _isBiometricsEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic 
                    ? 'تم تفعيل المصادقة البيومترية بنجاح'
                    : 'Biometric authentication enabled successfully',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تحديث إعدادات المصادقة البيومترية'
                : 'Error updating biometric settings',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _changeMPIN() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id') ?? '';
      final password = prefs.getString('password') ?? '';
      
      // First verify current MPIN before allowing change
      bool? shouldProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
          final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);
          
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
            title: Text(
              widget.isArabic ? 'تغيير رمز الدخول' : 'Change MPIN',
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              widget.isArabic 
                  ? 'هل أنت متأكد أنك تريد تغيير رمز الدخول الخاص بك؟'
                  : 'Are you sure you want to change your MPIN?',
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: isDarkMode ? Colors.black87 : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  widget.isArabic ? 'إلغاء' : 'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.black54 : Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  widget.isArabic ? 'متابعة' : 'Continue',
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldProceed != true || !mounted) return;

      // Verify biometrics if enabled
      if (_isBiometricsEnabled && _isBiometricsAvailable) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى المصادقة لتغيير رمز الدخول'
              : 'Please authenticate to change MPIN',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate || !mounted) return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MPINSetupScreen(
            nationalId: nationalId,
            password: password,
            isArabic: widget.isArabic,
            isChangingMPIN: true,  // Add this flag to MPINSetupScreen
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تغيير رمز الدخول'
                : 'Error changing MPIN',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id') ?? '';
      
      // First verify biometrics if enabled
      if (_isBiometricsEnabled && _isBiometricsAvailable) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: widget.isArabic 
              ? 'يرجى المصادقة لتغيير كلمة المرور'
              : 'Please authenticate to change password',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate || !mounted) return;
      }

      // Show password change dialog
      final result = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final currentPasswordController = TextEditingController();
          final newPasswordController = TextEditingController();
          final confirmPasswordController = TextEditingController();
          final formKey = GlobalKey<FormState>();
          bool obscureCurrentPassword = true;
          bool obscureNewPassword = true;
          bool obscureConfirmPassword = true;
          final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
          final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
                title: Text(
                  widget.isArabic ? 'تغيير كلمة المرور' : 'Change Password',
                  textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                          child: TextFormField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrentPassword,
                            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              labelText: widget.isArabic ? 'كلمة المرور الحالية' : 'Current Password',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              suffixIcon: widget.isArabic ? IconButton(
                                icon: Icon(obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                              ) : null,
                              prefixIcon: widget.isArabic ? null : IconButton(
                                icon: Icon(obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return widget.isArabic 
                                    ? 'يرجى إدخال كلمة المرور الحالية'
                                    : 'Please enter current password';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                          child: TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNewPassword,
                            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              labelText: widget.isArabic ? 'كلمة المرور الجديدة' : 'New Password',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              suffixIcon: widget.isArabic ? IconButton(
                                icon: Icon(obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => obscureNewPassword = !obscureNewPassword),
                              ) : null,
                              prefixIcon: widget.isArabic ? null : IconButton(
                                icon: Icon(obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => obscureNewPassword = !obscureNewPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return widget.isArabic 
                                    ? 'يرجى إدخال كلمة المرور الجديدة'
                                    : 'Please enter new password';
                              }
                              if (value.length < 8) {
                                return widget.isArabic
                                    ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
                                    : 'Password must be at least 8 characters';
                              }
                              if (!value.contains(RegExp(r'[A-Z]'))) {
                                return widget.isArabic
                                    ? 'كلمة المرور يجب أن تحتوي على حرف كبير'
                                    : 'Password must contain uppercase letter';
                              }
                              if (!value.contains(RegExp(r'[a-z]'))) {
                                return widget.isArabic
                                    ? 'كلمة المرور يجب أن تحتوي على حرف صغير'
                                    : 'Password must contain lowercase letter';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return widget.isArabic
                                    ? 'كلمة المرور يجب أن تحتوي على رقم'
                                    : 'Password must contain number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                          child: TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              labelText: widget.isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              suffixIcon: widget.isArabic ? IconButton(
                                icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                              ) : null,
                              prefixIcon: widget.isArabic ? null : IconButton(
                                icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return widget.isArabic
                                    ? 'يرجى تأكيد كلمة المرور الجديدة'
                                    : 'Please confirm new password';
                              }
                              if (value != newPasswordController.text) {
                                return widget.isArabic
                                    ? 'كلمة المرور غير متطابقة'
                                    : 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      widget.isArabic ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(context).pop({
                          'currentPassword': currentPasswordController.text,
                          'newPassword': newPasswordController.text,
                        });
                      }
                    },
                    child: Text(
                      widget.isArabic ? 'تغيير' : 'Change',
                      style: TextStyle(
                        color: isDarkMode ? Colors.black : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || !mounted) return;

      // First verify current password
      final loginResponse = await _authService.login(
        nationalId: nationalId,
        password: result['currentPassword']!,
      );

      if (loginResponse['status'] != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? 'كلمة المرور الحالية غير صحيحة'
                  : 'Current password is incorrect',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Generate OTP
      final otpResponse = await http.post(
        Uri.parse('${AuthService.baseUrl}/otp_generate.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'api-key': AuthService.apiKey,
        },
        body: {
          'national_id': nationalId,
          'type': 'change_password',
        },
      );

      final otpData = json.decode(otpResponse.body);
      
      if (otpData['status'] != 'success' || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? (otpData['message_ar'] ?? 'فشل في إرسال رمز التحقق')
                  : (otpData['message'] ?? 'Failed to send OTP'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Verify OTP
      final otpVerified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OTPDialog(
          nationalId: nationalId,
          isArabic: widget.isArabic,
          onResendOTP: () async {
            final response = await http.post(
              Uri.parse('${AuthService.baseUrl}/otp_generate.php'),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'api-key': AuthService.apiKey,
              },
              body: {
                'national_id': nationalId,
                'type': 'change_password',
              },
            );
            return json.decode(response.body);
          },
          onVerifyOTP: (otp) async {
            final response = await http.post(
              Uri.parse('${AuthService.baseUrl}/otp_verification.php'),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'api-key': AuthService.apiKey,
              },
              body: {
                'national_id': nationalId,
                'otp_code': otp,
                'type': 'change_password',
              },
            );
            return json.decode(response.body);
          },
        ),
      );

      if (otpVerified != true || !mounted) return;

      // Change password
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/password_change.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'api-key': AuthService.apiKey,
        },
        body: {
          'national_id': nationalId,
          'new_password': result['newPassword'],
          'type': 'change_password',
        },
      );

      final data = json.decode(response.body);
      
      if (data['status'] == 'success') {
        // Update stored password
        await prefs.setString('password', result['newPassword']!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? 'تم تغيير كلمة المرور بنجاح'
                  : 'Password changed successfully',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic 
                  ? (data['message_ar'] ?? 'حدث خطأ أثناء تغيير كلمة المرور')
                  : (data['message'] ?? 'Error changing password'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تغيير كلمة المرور'
                : 'Error changing password',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleLanguage() async {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: [
              Text(
                'Change Language',
                style: TextStyle(
                  color: themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'تغيير اللغة',
                style: TextStyle(
                  color: themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isArabic 
                    ? 'Are you sure you want to change the language to English?'
                    : 'Are you sure you want to change the language to Arabic?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.black87 : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isArabic 
                    ? 'هل أنت متأكد أنك تريد تغيير اللغة إلى الإنجليزية؟'
                    : 'هل أنت متأكد أنك تريد تغيير اللغة إلى العربية؟',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.black87 : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Column(
                        children: [
                          Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDarkMode ? Colors.black54 : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'إلغاء',
                            style: TextStyle(
                              color: isDarkMode ? Colors.black54 : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        // Save the new language preference
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isArabic', !widget.isArabic);
                        
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(
                              isArabic: !widget.isArabic,
                              userData: const {},
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            'Confirm',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تأكيد',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      print('\n=== SIGN OFF SEQUENCE START ===');
      print('1. Sign Off button clicked');

      // First clear auth service data
      print('2. Calling AuthService.signOff()');
      await _authService.signOff();
      print('3. AuthService.signOff() completed');

      if (!mounted) return;
      
      print('4. Navigating to MainPage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(
            isArabic: widget.isArabic,
            userData: const {},
          ),
        ),
      );
      print('5. Sign Off sequence completed successfully');
      print('=== SIGN OFF SEQUENCE END ===\n');
    } catch (e) {
      print('ERROR in Sign Off sequence: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic 
                ? 'حدث خطأ أثناء تسجيل الخروج'
                : 'Error signing off: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return ListTile(
      leading: Icon(icon, color: themeColor),
      title: Text(
        widget.isArabic ? _getArabicTitle(title) : title,
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.black : Colors.black87,
        ),
      ),
      trailing: trailing ?? Icon(
        widget.isArabic ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
        size: 16,
        color: isDarkMode ? Colors.black.withOpacity(0.7) : Colors.black54,
      ),
      onTap: onTap,
    );
  }

  String _getArabicTitle(String englishTitle) {
    switch (englishTitle) {
      case 'Biometric Authentication':
        return 'السمات الحيوية';
      case 'Change MPIN':
        return 'تغيير رمز الدخول';
      case 'Change Password':
        return 'تغيير كلمة المرور';
      case 'Language':
        return 'اللغة';
      case 'Sign Off':
        return 'تسجيل خروج';
      case 'Dark Mode':
        return 'الوضع الداكن';
      default:
        return englishTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 100,
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Center title
                    Center(
                      child: Text(
                        widget.isArabic ? 'حسابي' : 'Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    // Logo positioned at start
                    Positioned(
                      right: 0,
                      child: isDarkMode 
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/nayifat-logo-no-bg.png',
                              height: MediaQuery.of(context).size.height * 0.06,
                            ),
                          )
                        : Image.asset(
                            'assets/images/nayifat-logo-no-bg.png',
                            height: MediaQuery.of(context).size.height * 0.06,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                    children: [
                      const SizedBox(height: 20),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildSettingItem(
                            icon: Icons.brightness_6,
                            title: 'Dark Mode',
                            onTap: () {
                              final newDarkMode = !themeProvider.isDarkMode;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SplashScreen(
                                    isDarkMode: newDarkMode,
                                  ),
                                ),
                              );
                            },
                            trailing: Switch(
                              value: themeProvider.isDarkMode,
                              onChanged: (value) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SplashScreen(
                                      isDarkMode: value,
                                    ),
                                  ),
                                );
                              },
                              activeColor: themeProvider.isDarkMode ? Colors.black : primaryColor,
                              activeTrackColor: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : primaryColor.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.grey.withOpacity(0.3),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.fingerprint,
                        title: 'Biometric Authentication',
                        onTap: () {
                          if (!_isBiometricsAvailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _biometricsError,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            _toggleBiometrics();
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isBiometricsAvailable)
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              )
                            else
                              Switch(
                                value: _isBiometricsEnabled,
                                onChanged: (_) => _toggleBiometrics(),
                                activeColor: isDarkMode ? Colors.black : primaryColor,
                                activeTrackColor: isDarkMode ? Colors.black.withOpacity(0.3) : primaryColor.withOpacity(0.3),
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                              ),
                          ],
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.pin,
                        title: 'Change MPIN',
                        onTap: _changeMPIN,
                      ),
                      _buildSettingItem(
                        icon: Icons.lock,
                        title: 'Change Password',
                        onTap: _changePassword,
                      ),
                      _buildSettingItem(
                        icon: Icons.language,
                        title: widget.isArabic ? 'اللغة Language' : 'Language اللغة',
                        onTap: _toggleLanguage,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isArabic ? 'العربية' : 'English',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              widget.isArabic ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
                              size: 16
                            ),
                          ],
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.logout,
                        title: 'Sign Off',
                        onTap: _signOut,
                        trailing: Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: _signOut,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.red[50],
                              side: BorderSide(
                                color: isDarkMode ? Colors.black : Colors.red,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              widget.isArabic ? 'تسجيل خروج' : 'Sign Off',
                              style: TextStyle(
                                color: isDarkMode ? Colors.black : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700]! : primaryColor,
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.grey[900]! : primaryColor,
                blurRadius: isDarkMode ? 10 : 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CircleNavBar(
              activeIcons: widget.isArabic ? [
                Icon(Icons.settings, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.home, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.headset_mic, color: isDarkMode ? Colors.grey[400]! : primaryColor),
              ] : [
                Icon(Icons.headset_mic, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.home, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.settings, color: isDarkMode ? Colors.grey[400]! : primaryColor),
              ],
              inactiveIcons: widget.isArabic ? [
                Icon(Icons.settings, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.home, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.headset_mic, color: isDarkMode ? Colors.grey[400]! : primaryColor),
              ] : [
                Icon(Icons.headset_mic, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.credit_card, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.home, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.account_balance, color: isDarkMode ? Colors.grey[400]! : primaryColor),
                Icon(Icons.settings, color: isDarkMode ? Colors.grey[400]! : primaryColor),
              ],
              levels: widget.isArabic 
                ? const ["حسابي", "التمويل", "الرئيسية", "البطاقات", "الدعم"]
                : const ["Support", "Cards", "Home", "Loans", "Account"],
              activeLevelsStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400]! : primaryColor,
              ),
              inactiveLevelsStyle: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400]! : primaryColor,
              ),
              color: isDarkMode ? Colors.black : Colors.white,
              height: 70,
              circleWidth: 60,
              activeIndex: widget.isArabic ? 0 : 4,
              onTap: (index) {
                if ((widget.isArabic && index == 0) || (!widget.isArabic && index == 4)) {
                  setState(() {
                    _tabIndex = index;
                  });
                  return;  // Don't navigate if we're already on account
                }

                Widget? page;
                if (widget.isArabic) {
                  switch (index) {
                    case 0:
                      return; // Already on account
                    case 1:
                      page = const LoansPageAr();
                      break;
                    case 2:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                            isArabic: true,
                            userData: const {},
                          ),
                        ),
                      );
                      return;
                    case 3:
                      page = const CardsPageAr();
                      break;
                    case 4:
                      page = const CustomerServiceScreen(isArabic: true);
                      break;
                  }
                } else {
                  switch (index) {
                    case 0:
                      page = const CustomerServiceScreen(isArabic: false);
                      break;
                    case 1:
                      page = const CardsPage();
                      break;
                    case 2:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                            isArabic: false,
                            userData: const {},
                          ),
                        ),
                      );
                      return;
                    case 3:
                      page = const LoansPage();
                      break;
                    case 4:
                      return; // Already on account
                  }
                }

                if (page != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page!),
                  );
                }
              },
              cornerRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
                bottomRight: Radius.circular(0),
                bottomLeft: Radius.circular(0),
              ),
              shadowColor: Colors.transparent,
              elevation: 20,
            ),
          ),
        ),
      ),
    );
  }
}