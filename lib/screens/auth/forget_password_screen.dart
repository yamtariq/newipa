import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../widgets/otp_dialog.dart';
import '../../utils/constants.dart';
import 'sign_in_screen.dart';
import 'mpin_setup_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgetPasswordScreen extends StatefulWidget {
  final bool isArabic;

  const ForgetPasswordScreen({
    Key? key,
    this.isArabic = false,
  }) : super(key: key);

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _otpVerified = false;
  final AuthService _authService = AuthService();

  void _showErrorBanner(String message) {
    if (!mounted) return;
    
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
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessBanner(String message) {
    if (!mounted) return;
    
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
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _verifyNationalId() async {
    if (!_formKey.currentState!.validate()) return;

    print('T_ResetPass_1: Starting national ID verification process');
    print('T_ResetPass_2: National ID: ${_nationalIdController.text}');

    setState(() => _isLoading = true);

    try {
      print('T_ResetPass_3: Attempting to generate OTP');
      // Generate OTP using AuthService
      final response = await _authService.generateOTP(_nationalIdController.text);
      print('T_ResetPass_4: OTP generation response: $response');
      
      if (response['success'] == true) {
        print('T_ResetPass_5: OTP generation successful');
        // 💡 Store phone number if available in response
        if (response['phone'] != null) {
          print('T_ResetPass_6: Phone number found in response: ${response['phone']}');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_phone', response['phone']);
          print('T_ResetPass_7: Stored phone number in SharedPreferences');
        } else {
          print('T_ResetPass_8: No phone number in response');
        }

        if (mounted) {
          print('T_ResetPass_9: Showing OTP dialog');
          final otpVerified = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => OTPDialog(
              nationalId: _nationalIdController.text,
              isArabic: widget.isArabic,
              onResendOTP: () async {
                print('T_ResetPass_10: Resending OTP');
                return await _authService.generateOTP(_nationalIdController.text);
              },
              onVerifyOTP: (otp) async {
                print('T_ResetPass_11: Verifying OTP: $otp');
                return await _authService.verifyOTP(_nationalIdController.text, otp);
              },
            ),
          );

          print('T_ResetPass_12: OTP dialog result: $otpVerified');
          if (otpVerified == true) {
            print('T_ResetPass_13: OTP verified successfully');
            setState(() => _otpVerified = true);
          } else {
            print('T_ResetPass_14: OTP verification failed or cancelled');
          }
        }
      } else {
        print('T_ResetPass_15: OTP generation failed with code: ${response['code']}');
        String errorMessage;
        
        switch (response['code']) {
          case 'USER_NOT_FOUND':
            errorMessage = widget.isArabic
                ? 'رقم الهوية غير مسجل في النظام'
                : 'National ID is not registered in the system';
            print('T_ResetPass_16: User not found error');
            break;
          case 'RATE_LIMIT_EXCEEDED':
            errorMessage = widget.isArabic
                ? 'يرجى الانتظار قبل طلب رمز تحقق جديد'
                : 'Please wait before requesting a new OTP';
            print('T_ResetPass_17: Rate limit exceeded error');
            break;
          case 'INVALID_PHONE':
            errorMessage = widget.isArabic
                ? 'رقم الهاتف المسجل غير صالح'
                : 'Registered phone number is invalid';
            print('T_ResetPass_18: Invalid phone error');
            break;
          case 'INVALID_ID_FORMAT':
            errorMessage = widget.isArabic
                ? 'صيغة رقم الهوية غير صحيحة'
                : 'Invalid National ID format';
            print('T_ResetPass_19: Invalid ID format error');
            break;
          default:
            errorMessage = widget.isArabic
                ? (response['message_ar'] ?? 'حدث خطأ غير متوقع')
                : (response['message'] ?? 'An unexpected error occurred');
            print('T_ResetPass_20: Unexpected error: ${response['message']}');
        }
        
        _showErrorBanner(errorMessage);
      }
    } catch (e) {
      print('T_ResetPass_21: Error during verification: $e');
      _showErrorBanner(
        widget.isArabic
            ? 'حدث خطأ أثناء التحقق. يرجى المحاولة مرة أخرى'
            : 'Error during verification. Please try again'
      );
    } finally {
      if (mounted) {
        print('T_ResetPass_22: Resetting loading state');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    print('T_ResetPass_23: Starting password reset process');
    setState(() => _isLoading = true);

    try {
      print('T_ResetPass_24: Sending password reset request');
      print('T_ResetPass_25: National ID: ${_nationalIdController.text}');
      
      // 💡 Create HTTP client that bypasses SSL verification
      final client = Constants.createHttpClient(validateCertificate: false);
      try {
        // Send request
        final response = await client.post(
          Uri.parse('${Constants.apiBaseUrl}${Constants.endpointPasswordChange}'),
          headers: Constants.authHeaders,
          body: json.encode({
            'nationalId': _nationalIdController.text,
            'newPassword': _newPasswordController.text,
          }),
        );
        
        print('T_ResetPass_26: Response Status Code: ${response.statusCode}');
        print('T_ResetPass_27: Response Body: ${response.body}');

        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('T_ResetPass_28: Password reset successful');
          _showSuccessBanner(
            widget.isArabic
                ? data['data']['message']
                : data['data']['message']
          );
          
          // Sign in with the new password to get user data
          print('T_ResetPass_29: Attempting sign in with new password');
          final signInResponse = await AuthService().signIn(
            nationalId: _nationalIdController.text,
            password: _newPasswordController.text,
          );

          print('T_ResetPass_30: Sign in response: ${json.encode(signInResponse)}');

          if (signInResponse['success'] == true && signInResponse['data'] != null) {
            // Register device
            final deviceInfo = await AuthService().getDeviceInfo();
            final registerResponse = await AuthService().registerDevice(
              nationalId: _nationalIdController.text,
              deviceInfo: deviceInfo,
            );

            print('T_ResetPass_31: Device registration response: ${json.encode(registerResponse)}');

            if (registerResponse['success'] == true) {
              // Reset manual sign off flag in session provider
              if (mounted) {
                Provider.of<SessionProvider>(context, listen: false).resetManualSignOff();
              }

              // Store user data in local storage
              await AuthService().storeUserData(signInResponse['data']['user']);

              // Set session as active
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isSessionActive', true);

              // Navigate to MPIN setup after 1 second
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MPINSetupScreen(
                        nationalId: _nationalIdController.text,
                        password: _newPasswordController.text,
                        user: signInResponse['data']['user'],
                        isArabic: widget.isArabic,
                        showSteps: false,
                      ),
                    ),
                  );
                }
              });
            } else {
              print('T_ResetPass_32: Device registration failed with code: ${registerResponse['code']}');
              String errorMessage;
              
              switch (registerResponse['code']) {
                case 'DEVICE_ALREADY_REGISTERED':
                  errorMessage = widget.isArabic
                      ? 'هذا الجهاز مسجل بالفعل لمستخدم آخر'
                      : 'This device is already registered to another user';
                  break;
                case 'MAX_DEVICES_REACHED':
                  errorMessage = widget.isArabic
                      ? 'لقد وصلت إلى الحد الأقصى من الأجهزة المسجلة'
                      : 'You have reached the maximum number of registered devices';
                  break;
                default:
                  errorMessage = widget.isArabic
                      ? (registerResponse['message_ar'] ?? 'فشل في تسجيل الجهاز')
                      : (registerResponse['message'] ?? 'Failed to register device');
              }
              
              _showErrorBanner(errorMessage);
            }
          } else {
            print('T_ResetPass_33: Sign in failed with code: ${signInResponse['code']}');
            String errorMessage;
            
            switch (signInResponse['code']) {
              case 'INVALID_CREDENTIALS':
                errorMessage = widget.isArabic
                    ? 'بيانات الدخول غير صحيحة'
                    : 'Invalid credentials';
                break;
              case 'USER_NOT_FOUND':
                errorMessage = widget.isArabic
                    ? 'رقم الهوية غير مسجل في النظام'
                    : 'National ID is not registered in the system';
                break;
              case 'ACCOUNT_LOCKED':
                errorMessage = widget.isArabic
                    ? 'تم قفل الحساب مؤقتاً. يرجى المحاولة لاحقاً'
                    : 'Account temporarily locked. Please try again later';
                break;
              case 'DEVICE_NOT_REGISTERED':
                errorMessage = widget.isArabic
                    ? 'الجهاز غير مسجل'
                    : 'Device not registered';
                break;
              default:
                errorMessage = widget.isArabic
                    ? (signInResponse['message_ar'] ?? 'حدث خطأ أثناء تسجيل الدخول')
                    : (signInResponse['message'] ?? 'Error during sign in process');
            }
            
            _showErrorBanner(errorMessage);
          }
        } else {
          _showErrorBanner(
            widget.isArabic
                ? data['message_ar']
                : data['message']
          );
        }
      } finally {
        client.close(); // 💡 Always close the client
      }
    } catch (e) {
      print('T_ResetPass_34: Error during password reset: $e');
      _showErrorBanner(
        widget.isArabic
            ? 'حدث خطأ أثناء تغيير كلمة المرور. يرجى المحاولة مرة أخرى'
            : 'Error during password change. Please try again'
      );
    } finally {
      if (mounted) {
        print('T_ResetPass_35: Resetting loading state');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Color(isDarkMode ? Constants.darkBackgroundColor : Constants.lightBackgroundColor),
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

              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 100),

                      // Title
                      Text(
                        widget.isArabic ? 'نسيت كلمة المرور' : 'Forgot Password',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.primaryColorValue),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.primaryColorValue),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Description
                      Text(
                        widget.isArabic
                            ? 'أدخل رقم الهوية أو الإقامة لإعادة تعيين كلمة المرور'
                            : 'Enter your National ID or Iqama number to reset your password',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(isDarkMode ? Constants.darkLabelTextColor : Constants.lightLabelTextColor),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // National ID Input
                      TextFormField(
                        controller: _nationalIdController,
                        enabled: !_otpVerified,
                        decoration: InputDecoration(
                          labelText: widget.isArabic ? 'رقم الهوية أو الإقامة' : 'National or Iqama ID',
                          hintText: widget.isArabic ? 'أدخل رقم الهوية أو الإقامة' : 'Enter your National or Iqama ID',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Color(isDarkMode ? Constants.darkIconColor : Constants.lightIconColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                            borderSide: BorderSide(
                              color: Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                            borderSide: BorderSide(
                              color: Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                            borderSide: BorderSide(
                              color: Color(isDarkMode ? Constants.darkFormFocusedBorderColor : Constants.lightFormFocusedBorderColor),
                            ),
                          ),
                          filled: true,
                          fillColor: Color(isDarkMode ? Constants.darkFormBackgroundColor : Constants.lightFormBackgroundColor),
                          labelStyle: TextStyle(
                            color: Color(isDarkMode ? Constants.darkLabelTextColor : Constants.lightLabelTextColor),
                          ),
                          hintStyle: TextStyle(
                            color: Color(isDarkMode ? Constants.darkHintTextColor : Constants.lightHintTextColor),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return widget.isArabic
                                ? 'يرجى إدخال رقم الهوية أو الإقامة'
                                : 'Please enter your National or Iqama ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      if (!_otpVerified) ...[
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyNationalId,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.primaryColorValue),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isArabic ? 'إعادة تعيين' : 'Reset',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            widget.isArabic ? 'إلغاء' : 'Cancel',
                            style: TextStyle(
                              color: Color(isDarkMode ? Constants.darkLabelTextColor : Constants.lightLabelTextColor),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],

                      if (_otpVerified) ...[
                        // New Password Input
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: InputDecoration(
                            labelText: widget.isArabic ? 'كلمة المرور الجديدة' : 'New Password',
                            hintText: widget.isArabic ? 'أدخل كلمة المرور الجديدة' : 'Enter new password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(isDarkMode ? Constants.darkIconColor : Constants.lightIconColor),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                              borderSide: BorderSide(
                                color: Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                              borderSide: BorderSide(
                                color: Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                              borderSide: BorderSide(
                                color: Color(isDarkMode ? Constants.darkFormFocusedBorderColor : Constants.lightFormFocusedBorderColor),
                              ),
                            ),
                            filled: true,
                            fillColor: Color(isDarkMode ? Constants.darkFormBackgroundColor : Constants.lightFormBackgroundColor),
                            labelStyle: TextStyle(
                              color: Color(isDarkMode ? Constants.darkLabelTextColor : Constants.lightLabelTextColor),
                            ),
                            hintStyle: TextStyle(
                              color: Color(isDarkMode ? Constants.darkHintTextColor : Constants.lightHintTextColor),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return widget.isArabic
                                  ? 'يرجى إدخال كلمة المرور الجديدة'
                                  : 'Please enter new password';
                            }
                            if (value.length < 8) {
                              return widget.isArabic
                                  ? 'يجب أن تكون كلمة المرور 8 أحرف على الأقل'
                                  : 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Confirm Password Input with same theme as New Password Input
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: widget.isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                            hintText: widget.isArabic ? 'أدخل كلمة المرور مرة أخرى' : 'Enter password again',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(isDarkMode ? Constants.darkIconColor : Constants.lightIconColor),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                              borderSide: BorderSide(
                                color: Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                              borderSide: BorderSide(
                                color: Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                              borderSide: BorderSide(
                                color: Color(isDarkMode ? Constants.darkFormFocusedBorderColor : Constants.lightFormFocusedBorderColor),
                              ),
                            ),
                            filled: true,
                            fillColor: Color(isDarkMode ? Constants.darkFormBackgroundColor : Constants.lightFormBackgroundColor),
                            labelStyle: TextStyle(
                              color: Color(isDarkMode ? Constants.darkLabelTextColor : Constants.lightLabelTextColor),
                            ),
                            hintStyle: TextStyle(
                              color: Color(isDarkMode ? Constants.darkHintTextColor : Constants.lightHintTextColor),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return widget.isArabic
                                  ? 'يرجى تأكيد كلمة المرور'
                                  : 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return widget.isArabic
                                  ? 'كلمات المرور غير متطابقة'
                                  : 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.primaryColorValue),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isArabic ? 'تغيير كلمة المرور' : 'Reset Password',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 