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
  bool _isDarkMode = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  final Color primaryColor = const Color(0xFF0077B6);
  final Color primaryLightColor = const Color(0xFFE6F3F8);  // Lightest shade for background
  final Color primaryMediumColor = const Color(0xFF0077B6).withOpacity(0.2);  // Medium shade for containers
  final Color primaryDarkColor = const Color(0xFF005B8D);  // Darker shade for emphasis

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await ThemeService.isDarkMode();
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _showResultDialog(bool isSuccess) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black,  // Black
                  Colors.black,  // Black
                  const Color(0xFF00A650),  // Nayifat green
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // OK Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00A650),  // Nayifat green
                        Colors.black,  // Black
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A650).withOpacity(0.3),
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
                            userData: const {},
                            onLanguageChanged: null,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'حسناً' : 'OK',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final applicationData = {
          'name': _nameController.text,
          'id_number': _idNumberController.text,
          'email': _emailController.text,
          'salary': double.parse(_salaryController.text),
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
          print('URL: ${Constants.apiBaseUrl}/update_loan_application.php');
          print('Headers: ${jsonEncode({
            'Content-Type': 'application/json',
            'api-key': Constants.apiKey,
          })}');
          print('Payload: ${jsonEncode(loanData)}');

          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}/update_loan_application.php'),
            headers: {
              'Content-Type': 'application/json',
              'api-key': Constants.apiKey,
            },
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
          print('URL: ${Constants.apiBaseUrl}/update_cards_application.php');
          print('Headers: ${jsonEncode({
            'Content-Type': 'application/json',
            'api-key': Constants.apiKey,
          })}');
          print('Payload: ${jsonEncode(cardData)}');

          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}/update_cards_application.php'),
            headers: {
              'Content-Type': 'application/json',
              'api-key': Constants.apiKey,
            },
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

  @override
  Widget build(BuildContext context) {
    final themeColor = _isDarkMode ? Colors.black : primaryColor;

    // Helper function to create label text with required asterisk
    Widget _buildLabel(String label) {
      return Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _isDarkMode ? Colors.black87 : primaryDarkColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            ' *',
            style: TextStyle(
              color: _isDarkMode ? themeColor.withOpacity(0.7) : primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[100] : primaryLightColor,
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
                          _isDarkMode 
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Colors.black,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/images/nayifat-logo-no-bg.png',
                                  height: 45,
                                ),
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
                        color: _isDarkMode ? Colors.grey[100] : primaryMediumColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _isDarkMode ? themeColor.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        widget.isArabic
                            ? widget.isLoanApplication ? 'طلب تمويل' : 'طلب بطاقة ائتمانية'
                            : widget.isLoanApplication ? 'Loan Application' : 'Credit Card Application',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.black87 : primaryColor,
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
                                    color: _isDarkMode ? Colors.white : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isDarkMode ? themeColor.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.05),
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
                                          color: _isDarkMode ? Colors.black87 : primaryDarkColor,
                                        ),
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'الاسم' : 'Name'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: themeColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: _isDarkMode ? Colors.grey[100] : primaryLightColor,
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
                                          color: _isDarkMode ? Colors.black87 : primaryDarkColor,
                                        ),
                                        keyboardType: TextInputType.number,
                                        maxLength: 10,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'رقم الهوية' : 'ID Number'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: themeColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: _isDarkMode ? Colors.grey[100] : primaryLightColor,
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

                                      // Email Field
                                      TextFormField(
                                        controller: _emailController,
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.black87 : primaryDarkColor,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'البريد الإلكتروني' : 'Email'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: themeColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: _isDarkMode ? Colors.grey[100] : primaryLightColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال البريد الإلكتروني'
                                                : 'Please enter your email';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                              .hasMatch(value)) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال بريد إلكتروني صحيح'
                                                : 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Salary Field
                                      TextFormField(
                                        controller: _salaryController,
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.black87 : primaryDarkColor,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          label: _buildLabel(widget.isArabic ? 'الراتب الشهري' : 'Monthly Salary'),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _isDarkMode ? themeColor.withOpacity(0.3) : primaryMediumColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: themeColor, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: _isDarkMode ? Colors.grey[100] : primaryLightColor,
                                          prefixText: widget.isArabic ? '' : 'SAR ',
                                          suffixText: widget.isArabic ? ' ريال' : '',
                                          prefixStyle: TextStyle(color: _isDarkMode ? Colors.black87 : primaryDarkColor),
                                          suffixStyle: TextStyle(color: _isDarkMode ? Colors.black87 : primaryDarkColor),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return widget.isArabic
                                                ? 'الرجاء إدخال الراتب الشهري'
                                                : 'Please enter your monthly salary';
                                          }
                                          final salary = double.tryParse(value);
                                          if (salary == null || salary < 2000) {
                                            return widget.isArabic
                                                ? 'الراتب يجب أن يكون 2000 ريال على الأقل'
                                                : 'Salary must be at least 2000 SAR';
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
                                    backgroundColor: _isDarkMode ? Colors.black.withOpacity(0.1) : primaryColor,
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _isDarkMode ? Colors.black : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    widget.isArabic ? 'متابعة' : 'Continue',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode ? Colors.black : Colors.white,
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    widget.isArabic ? 'إلغاء' : 'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isDarkMode ? themeColor : primaryDarkColor,
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