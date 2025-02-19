import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';  // Add this import for TimeoutException
import 'dart:io';  // 💡 Add this import for HttpClient
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import 'loan_application/loan_application_details_screen.dart';
import 'card_application/card_application_details_screen.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../screens/main_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/otp_dialog.dart';
import 'package:flutter/rendering.dart' as ui;

class ApplicationLandingScreen extends StatefulWidget {
  final bool isArabic;
  final bool isLoanApplication;

  const ApplicationLandingScreen({
    Key? key,
    required this.isArabic,
    required this.isLoanApplication,
  }) : super(key: key);

  @override
  State<ApplicationLandingScreen> createState() => _ApplicationLandingScreenState();
}

class _ApplicationLandingScreenState extends State<ApplicationLandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  final _otpController = TextEditingController();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<bool> _verifyOTP(String otp) async {
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final uri = Uri.parse('${Constants.proxyOtpVerifyUrl}');
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      final body = {
        'nationalId': _idNumberController.text,
        'otp': otp,
        'userId': '1'
      };
      request.write(jsonEncode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  Future<bool> _sendOTP() async {
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final uri = Uri.parse(Constants.proxyOtpGenerateUrl);
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      final body = Constants.otpGenerateRequestBody(
        _idNumberController.text,
        '966${_phoneController.text}',
        purpose: 'application'
      );
      request.write(jsonEncode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('OTP Generation Response: $responseBody'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _verifyOTPCode(String otp) async {
    int maxRetries = 3;
    int currentTry = 0;
    
    while (currentTry < maxRetries) {
      try {
        print('\n=== VERIFYING OTP (Attempt ${currentTry + 1}/${maxRetries}) ===');
        print('National ID: ${_idNumberController.text}');
        print('OTP: $otp');
        
        // 💡 Create a custom HttpClient that accepts self-signed certificates
        final client = HttpClient()
          ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
        
        final uri = Uri.parse('${Constants.proxyOtpVerifyUrl}');
        final request = await client.postUrl(uri);
        
        // Add headers
        Constants.defaultHeaders.forEach((key, value) {
          request.headers.set(key, value);
        });
        
        // Add body
        final body = Constants.otpVerifyRequestBody(
          _idNumberController.text,
          otp
        );
        request.write(jsonEncode(body));
        
        final response = await request.close().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out. Please try again.');
          },
        );
        final responseBody = await response.transform(utf8.decoder).join();
        
        print('OTP Verification Response: $responseBody');
        final data = jsonDecode(responseBody);
        
        if (data['success'] == true) {
          print('✅ OTP verified successfully');
          if (mounted) {
            Navigator.of(context).pop(true);  // Close OTP dialog with success
          }
          return data;
        }
        
        throw Exception(widget.isArabic 
          ? (data['message_ar'] ?? 'رمز التحقق غير صحيح')
          : (data['message'] ?? 'Invalid OTP'));
      } catch (e) {
        currentTry++;
        print('❌ Error verifying OTP (Attempt $currentTry/$maxRetries): $e');
        
        if (e is TimeoutException || (e.toString().contains('Connection closed') && currentTry < maxRetries)) {
          if (mounted) {
            final shouldRetry = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isArabic ? 'خطأ في الاتصال' : 'Connection Error',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isArabic
                            ? 'سنقوم بإرسال رمز تحقق جديد. هل تريد المتابعة؟'
                            : 'We will send a new OTP. Would you like to continue?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              widget.isArabic ? 'إلغاء' : 'Cancel',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(widget.isArabic ? 'متابعة' : 'Continue'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ) ?? false;

            if (!shouldRetry) {
              break;
            }
            
            try {
              final otpSent = await _sendOTP();
              if (!otpSent) {
                throw Exception(widget.isArabic 
                  ? 'فشل في إرسال رمز التحقق الجديد'
                  : 'Failed to send new OTP');
              }
              Navigator.pop(context);
              await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => OTPDialog(
                  nationalId: _idNumberController.text,
                  isArabic: widget.isArabic,
                  onResendOTP: () async {
                    final response = await http.post(
                      Uri.parse('${Constants.proxyOtpGenerateUrl}'),
                      headers: Constants.defaultHeaders,
                      body: jsonEncode(Constants.otpGenerateRequestBody(
                        _idNumberController.text,
                        '966${_phoneController.text}',  // Add country code prefix
                        purpose: 'application'
                      )),
                    );
                    return json.decode(response.body);
                  },
                  onVerifyOTP: _verifyOTPCode,
                ),
              );
            } catch (otpError) {
              print('Error generating new OTP: $otpError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isArabic
                          ? 'فشل في إرسال رمز التحقق الجديد'
                          : 'Failed to send new OTP'
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              break;
            }
            return {};
          }
        }
        
        if (currentTry >= maxRetries || (!e.toString().contains('Connection closed') && !(e is TimeoutException))) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isArabic
                      ? 'فشل في التحقق من الرمز. يرجى المحاولة مرة أخرى'
                      : 'Failed to verify OTP. Please try again'
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          rethrow;
        }
      }
    }
    
    throw Exception(widget.isArabic 
      ? 'فشل في الاتصال بالنظام. يرجى المحاولة مرة أخرى لاحقاً'
      : 'Failed to connect to server. Please try again later');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First verify phone with OTP
        final verified = await _showOTPDialog();
        if (!verified) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Create application data with PascalCase for API request
        final applicationData = {
          'NationalId': _idNumberController.text,
          'Name': _nameController.text,
          'Phone': '966${_phoneController.text}'  // Add country code prefix
        };

        // Store data in secure storage first
        await _storage.write(
          key: 'application_data',
          value: jsonEncode(applicationData),
        );

        if (widget.isLoanApplication) {
          // Loan application
          print('\n=== LOAN APPLICATION API CALL ===');
          print('URL: ${Constants.apiBaseUrl}${Constants.endpointCreateLoanLead}');
          print('Headers: ${jsonEncode(Constants.defaultHeaders)}');
          print('Payload: ${jsonEncode(applicationData)}');

          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointCreateLoanLead}'),
            headers: Constants.defaultHeaders,
            body: jsonEncode(applicationData),
          );

          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('=== END LOAN APPLICATION API CALL ===\n');

          if (response.statusCode != 200) {
            final errorData = jsonDecode(response.body);
            throw Exception(errorData['error'] ?? 'Failed to submit loan application');
          }

          if (mounted) {
            // Show success dialog before navigation
            await _showResultDialog(true);
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  isArabic: widget.isArabic,
                  onLanguageChanged: (bool value) {},
                  userData: {},
                  initialRoute: '',
                  isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                ),
              ),
              (route) => false,
            );
          }
        } else {
          // Card application
          print('\n=== CARD APPLICATION API CALL ===');
          print('URL: ${Constants.apiBaseUrl}${Constants.endpointCreateCardLead}');
          print('Headers: ${jsonEncode(Constants.defaultHeaders)}');
          print('Payload: ${jsonEncode(applicationData)}');

          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointCreateCardLead}'),
            headers: Constants.defaultHeaders,
            body: jsonEncode(applicationData),
          );

          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('=== END CARD APPLICATION API CALL ===\n');

          if (response.statusCode != 200) {
            final errorData = jsonDecode(response.body);
            throw Exception(errorData['error'] ?? 'Failed to submit card application');
          }

          if (mounted) {
            // Show success dialog before navigation
            await _showResultDialog(true);
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  isArabic: widget.isArabic,
                  onLanguageChanged: (bool value) {},
                  userData: {},
                  initialRoute: '',
                  isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                ),
              ),
              (route) => false,
            );
          }
        }
      } catch (e) {
        print('Error submitting application: $e');
        if (mounted) {
          // Show error dialog instead of snackbar
          await _showResultDialog(false, errorMessage: e.toString().replaceAll('Exception: ', ''));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showResultDialog(bool isSuccess, {String? errorMessage}) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(themeProvider.isDarkMode 
                      ? Constants.darkPrimaryShadowColor 
                      : Constants.lightPrimaryShadowColor),
                  blurRadius: 15,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon/Animation
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: isSuccess 
                    ? Lottie.asset(
                        'assets/animations/celebration.json',
                        repeat: true,
                        reverse: true,
                      )
                    : Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[700],
                      ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  isSuccess
                      ? (widget.isArabic ? 'تم تقديم طلبك بنجاح' : 'Application Submitted Successfully')
                      : (widget.isArabic ? 'خطأ' : 'Error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  isSuccess
                      ? (widget.isArabic
                          ? 'تم تقديم طلبك بنجاح'
                          : 'Your application has been submitted successfully')
                      : (widget.isArabic
                          ? errorMessage?.replaceAll('Exception: ', '') ?? 'حدث خطأ أثناء تقديم طلبك'
                          : errorMessage?.replaceAll('Exception: ', '') ?? 'There was an error submitting your application'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (isSuccess) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(
                              isArabic: widget.isArabic,
                              onLanguageChanged: (bool value) {},
                              userData: {},
                              initialRoute: '',
                              isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess ? primaryColor : Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                      ),
                    ),
                    child: Text(
                      isSuccess 
                        ? (widget.isArabic ? 'متابعة' : 'Continue')
                        : (widget.isArabic ? 'حسناً' : 'OK'),
                      style: TextStyle(
                        fontSize: 16,
                        color: surfaceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showOTPDialog() async {
    bool isVerified = false;
    
    // Send OTP first
    final otpSent = await _sendOTP();
    if (!otpSent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'فشل في إرسال رمز التحقق. الرجاء المحاولة مرة أخرى'
                  : 'Failed to send OTP. Please try again',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    if (!mounted) return false;

    final otpVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OTPDialog(
        nationalId: _idNumberController.text,
        isArabic: widget.isArabic,
        onResendOTP: () async {
          final response = await http.post(
            Uri.parse('${Constants.proxyOtpGenerateUrl}'),
            headers: Constants.defaultHeaders,
            body: jsonEncode(Constants.otpGenerateRequestBody(
              _idNumberController.text,
              '966${_phoneController.text}',  // Add country code prefix
              purpose: 'application'
            )),
          );
          return json.decode(response.body);
        },
        onVerifyOTP: _verifyOTPCode,
      ),
    );

    return otpVerified ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Color(themeProvider.isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final backgroundColor = Color(themeProvider.isDarkMode 
        ? Constants.darkBackgroundColor 
        : Constants.lightBackgroundColor);
    final surfaceColor = Color(themeProvider.isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintColor = Color(themeProvider.isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);
    final borderColor = Color(themeProvider.isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);

    // Helper function to create label text with required asterisk
    Widget _buildLabel(String label) {
      return Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            ' *',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        child: Stack(
          children: [
            SafeArea(
              child: Directionality(
                textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  children: [
                    // Header with Logo and Title
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          themeProvider.isDarkMode 
                            ? Image.asset(
                                'assets/images/nayifat-logo-no-bg.png',
                                height: 45,
                              )
                            : Image.asset(
                                'assets/images/nayifat-logo-no-bg.png',
                                height: 45,
                              ),
                        ],
                      ),
                    ),
                    // Title
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Text(
                        widget.isArabic
                            ? widget.isLoanApplication ? 'طلب تمويل' : 'طلب بطاقة ائتمانية'
                            : widget.isLoanApplication ? 'Loan Application' : 'Credit Card Application',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Form fields with glass effect container
                                Container(
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
                                    border: Border.all(
                                      color: borderColor,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(themeProvider.isDarkMode 
                                            ? Constants.darkPrimaryShadowColor 
                                            : Constants.lightPrimaryShadowColor),
                                        blurRadius: 15,
                                        spreadRadius: -8,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Name Field
                                      TextFormField(
                                        controller: _nameController,
                                        style: TextStyle(
                                          color: textColor,
                                        ),
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'الاسم' : 'Name'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: surfaceColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال الاسم'
                                                : 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // ID Number Field
                                      TextFormField(
                                        controller: _idNumberController,
                                        style: TextStyle(
                                          color: textColor,
                                        ),
                                        keyboardType: TextInputType.number,
                                        maxLength: 10,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'رقم الهوية' : 'ID Number'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: surfaceColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          counterText: '',
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال رقم الهوية'
                                                : 'Please enter your ID number';
                                          }
                                          if (value.length != 10) {
                                            return widget.isArabic
                                                ? 'رقم الهوية يجب أن يكون 10 أرقام'
                                                : 'ID number must be 10 digits';
                                          }
                                          if (!value.startsWith('1') && !value.startsWith('2')) {
                                            return widget.isArabic
                                                ? 'رقم الهوية يجب أن يبدأ بـ 1 أو 2'
                                                : 'ID number must start with 1 or 2';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Phone Field
                                      TextFormField(
                                        controller: _phoneController,
                                        style: TextStyle(
                                          color: textColor,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        maxLength: 9,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'رقم الهاتف' : 'Phone Number'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: surfaceColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          suffixIcon: widget.isArabic
                                              ? Container(
                                                  width: 50,
                                                  alignment: Alignment.centerLeft,
                                                  padding: const EdgeInsets.only(left: 8),
                                                  child: Directionality(
                                                    textDirection: ui.TextDirection.ltr,
                                                    child: Text(
                                                      '+966 ',
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        color: textColor,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : null,
                                          prefix: !widget.isArabic
                                              ? Text(
                                                  '+966 ',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontSize: 16,
                                                  ),
                                                )
                                              : null,
                                          counterText: '',
                                        ),
                                        textAlign: TextAlign.left,
                                        textDirection: ui.TextDirection.ltr,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال رقم الهاتف'
                                                : 'Please enter your phone number';
                                          }
                                          if (value.length != 9) {
                                            return widget.isArabic
                                                ? 'رقم الهاتف يجب أن يكون 9 أرقام'
                                                : 'Phone number must be 9 digits';
                                          }
                                          if (!value.startsWith('5')) {
                                            return widget.isArabic
                                                ? '5'
                                                : 'Phone number must start with 5';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Submit Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                    ),
                                    elevation: themeProvider.isDarkMode ? 0 : 2,
                                  ),
                                  child: Text(
                                    widget.isArabic ? 'متابعة' : 'Continue',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: surfaceColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Cancel Button
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                                    ),
                                  ),
                                  child: Text(
                                    widget.isArabic ? 'إلغاء' : 'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 