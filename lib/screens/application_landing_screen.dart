import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
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
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPVerification}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'api-key': Constants.apiKey,
        },
        body: {
          'national_id': _idNumberController.text,
          'otp_code': otp,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  Future<bool> _sendOTP() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'api-key': Constants.apiKey,
        },
        body: {
          'national_id': _idNumberController.text,
        },
      );

      print('OTP Generation Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
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
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'api-key': Constants.apiKey,
            },
            body: {
              'national_id': _idNumberController.text,
            },
          );
          return json.decode(response.body);
        },
        onVerifyOTP: (otp) async {
          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPVerification}'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'api-key': Constants.apiKey,
            },
            body: {
              'national_id': _idNumberController.text,
              'otp_code': otp,
            },
          );
          return json.decode(response.body);
        },
      ),
    );

    return otpVerified ?? false;
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

        final applicationData = {
          'name': _nameController.text,
          'id_number': _idNumberController.text,
          'phone': _phoneController.text,
          'application_no': "0",
        };

        // Store data in secure storage first
        await _storage.write(
          key: 'application_data',
          value: jsonEncode(applicationData),
        );

        if (widget.isLoanApplication) {
          // Loan application
          final loanData = {
            'national_id': _idNumberController.text,
            'application_no': "0",
            'customerDecision': 'pending',
            'loan_amount': 0,
            'loan_purpose': 'N/A',
            'loan_tenure': 0,
            'interest_rate': 0,
            'status': 'pending',
            'remarks': 'N/A',
            'noteUser': 'CUSTOMER',
            'note': 'N/A'
          };

          print('\n=== LOAN APPLICATION API CALL ===');
          print('URL: ${Constants.apiBaseUrl}${Constants.endpointUpdateLoanApplication}');
          print('Headers: ${jsonEncode(Constants.defaultHeaders)}');
          print('Payload: ${jsonEncode(loanData)}');

          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUpdateLoanApplication}'),
            headers: Constants.defaultHeaders,
            body: jsonEncode(loanData),
          );

          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('=== END LOAN APPLICATION API CALL ===\n');

          if (response.statusCode != 200) {
            throw Exception('Failed to submit loan application');
          }
        } else {
          // Card application - following same pattern as loan application
          final cardData = {
            'national_id': _idNumberController.text,
            'application_number': "0",
            'customerDecision': 'pending',
            'card_type': 'N/A',
            'card_limit': 0,
            'status': 'pending',
            'remarks': 'N/A',
            'noteUser': 'CUSTOMER',
            'note': 'N/A'
          };

          print('\n=== CARD APPLICATION API CALL ===');
          print('URL: ${Constants.apiBaseUrl}${Constants.endpointUpdateCardApplication}');
          print('Headers: ${jsonEncode(Constants.defaultHeaders)}');
          print('Payload: ${jsonEncode(cardData)}');

          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUpdateCardApplication}'),
            headers: Constants.defaultHeaders,
            body: jsonEncode(cardData),
          );

          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('=== END CARD APPLICATION API CALL ===\n');

          if (response.statusCode != 200) {
            throw Exception('Failed to submit card application');
          }
        }

        if (mounted) {
          await _showResultDialog(true);
        }
      } catch (e) {
        print('Error submitting application: $e');
        if (mounted) {
          await _showResultDialog(false);
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

  Future<void> _showResultDialog(bool isSuccess) async {
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
                // Lottie Animation
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
                  child: Lottie.asset(
                    'assets/animations/celebration.json',
                    repeat: isSuccess,
                    reverse: isSuccess,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Message
                Text(
                  isSuccess
                      ? (widget.isArabic
                          ? 'تم تقديم طلبك بنجاح'
                          : 'Your application has been submitted successfully')
                      : (widget.isArabic
                          ? 'حدث خطأ أثناء تقديم طلبك'
                          : 'There was an error submitting your application'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                // OK Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Color(themeProvider.isDarkMode 
                            ? Constants.darkPrimaryShadowColor 
                            : Constants.lightPrimaryShadowColor),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'حسناً' : 'OK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: surfaceColor,
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
                                        maxLength: 10,
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
                                          prefixText: widget.isArabic ? '' : '+966 ',
                                          prefixStyle: TextStyle(color: textColor),
                                          counterText: '',
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال رقم الهاتف'
                                                : 'Please enter your phone number';
                                          }
                                          if (value.length != 10) {
                                            return widget.isArabic
                                                ? 'رقم الهاتف يجب أن يكون 10 أرقام'
                                                : 'Phone number must be 10 digits';
                                          }
                                          if (!value.startsWith('05')) {
                                            return widget.isArabic
                                                ? 'رقم الهاتف يجب أن يبدأ بـ 05'
                                                : 'Phone number must start with 05';
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