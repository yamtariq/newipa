import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../widgets/otp_dialog.dart';
import 'mpin_setup_screen.dart';
import 'biometric_setup_screen.dart';
import '../main_page.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgetMPINScreen extends StatefulWidget {
  final bool isArabic;
  final String? nationalId;

  const ForgetMPINScreen({
    Key? key,
    this.isArabic = false,
    this.nationalId,
  }) : super(key: key);

  @override
  State<ForgetMPINScreen> createState() => _ForgetMPINScreenState();
}

class _ForgetMPINScreenState extends State<ForgetMPINScreen> {
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.nationalId != null) {
      _nationalIdController.text = widget.nationalId!;
    }
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    });

    try {
      // First verify the password
      final loginResponse = await _authService.signIn(
        nationalId: _nationalIdController.text,
        password: _passwordController.text,
      );

      if (loginResponse['status'] != 'success') {
        _showErrorBanner(
          widget.isArabic
              ? 'كلمة المرور غير صحيحة'
              : 'Invalid password'
        );
        return;
      }

      // Generate OTP
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'api-key': AuthService.apiKey,
        },
        body: {
          'national_id': _nationalIdController.text,
        },
      );

      final data = json.decode(response.body);
      
      if (data['status'] == 'success') {
        if (mounted) {
          final otpVerified = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => OTPDialog(
              nationalId: _nationalIdController.text,
              isArabic: widget.isArabic,
              onResendOTP: () async {
                final response = await http.post(
                  Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}'),
                  headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'api-key': AuthService.apiKey,
                  },
                  body: {
                    'national_id': _nationalIdController.text,
                  },
                );
                return json.decode(response.body);
              },
              onVerifyOTP: (otp) async {
                final response = await http.post(
                  Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPVerification}'),
                  headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'api-key': AuthService.apiKey,
                  },
                  body: {
                    'national_id': _nationalIdController.text,
                    'otp_code': otp,
                  },
                );
                return json.decode(response.body);
              },
            ),
          );

          if (otpVerified == true) {
            // Navigate to MPIN setup screen
            if (mounted) {
              // Reset manual sign off flag in session provider
              Provider.of<SessionProvider>(context, listen: false).resetManualSignOff();
              
              // Store user data in local storage
              await _authService.storeUserData(loginResponse['user']);

              // Set session as active
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isSessionActive', true);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MPINSetupScreen(
                    nationalId: _nationalIdController.text,
                    password: _passwordController.text,
                    isArabic: widget.isArabic,
                    showSteps: false,
                    user: loginResponse['user'],
                  ),
                ),
              );
            }
          }
        }
      } else {
        _showErrorBanner(
          widget.isArabic
              ? (data['message_ar'] ?? 'فشل في إرسال رمز التحقق')
              : (data['message'] ?? 'Failed to send OTP')
        );
      }
    } catch (e) {
      print('Error during MPIN reset process: $e');
      _showErrorBanner(
        widget.isArabic
            ? 'حدث خطأ أثناء إعادة تعيين رمز الدخول'
            : 'Error during MPIN reset'
      );
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

    return Directionality(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 90),

                      // Title
                      Text(
                        widget.isArabic ? 'نسيت رمز الدخول السريع' : 'Forgot MPIN',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Description
                      Text(
                        widget.isArabic
                            ? 'لإعادة تعيين رمز الدخول السريع، يرجى إدخال رقم الهوية وكلمة المرور'
                            : 'To reset your MPIN, please enter your National ID and password',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode 
                              ? Color(Constants.darkLabelTextColor)
                              : Color(Constants.lightLabelTextColor),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // National ID Input (Disabled)
                      TextFormField(
                        controller: _nationalIdController,
                        enabled: false,
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
                          filled: true,
                          fillColor: isDarkMode 
                              ? Color(Constants.darkFormBackgroundColor)
                              : Color(Constants.lightFormBackgroundColor),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                            borderSide: BorderSide(
                              color: isDarkMode 
                                  ? Color(Constants.darkFormBorderColor)
                                  : Color(Constants.lightFormBorderColor),
                            ),
                          ),
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
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
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
                      const SizedBox(height: 40),

                      // Next Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _onNextPressed,
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
                                widget.isArabic ? 'متابعة' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.isArabic ? 'إلغاء' : 'Cancel',
                          style: TextStyle(
                            color: isDarkMode 
                                ? Color(Constants.darkLabelTextColor)
                                : Color(Constants.lightLabelTextColor),
                            fontSize: 16,
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
      ),
    );
  }
} 