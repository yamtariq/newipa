import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/custom_button.dart';
import 'loan_application_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class LoanApplicationStartScreen extends StatefulWidget {
  final bool isArabic;
  const LoanApplicationStartScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<LoanApplicationStartScreen> createState() => _LoanApplicationStartScreenState();
}

class _LoanApplicationStartScreenState extends State<LoanApplicationStartScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _termsAccepted = false;
  String _nationalId = '';
  String _dateOfBirth = '';
  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // 💡 First try secure storage
      String? nationalId = await _secureStorage.read(key: 'national_id');
      String? userDataStr = await _secureStorage.read(key: 'user_data');
      Map<String, dynamic>? userData;
      String? dateOfBirth;
      
      if (userDataStr != null) {
        userData = json.decode(userDataStr) as Map<String, dynamic>;
        dateOfBirth = userData?['dob']?.toString() ?? userData?['dateOfBirth']?.toString();
      }
      
      // 💡 If not found in secure storage, try SharedPreferences
      if (nationalId == null || userData == null) {
        final prefs = await SharedPreferences.getInstance();
        nationalId = prefs.getString('national_id');
        
        // Try to get DOB from registration data first
        final registrationDataStr = prefs.getString('registration_data');
        if (registrationDataStr != null) {
          final registrationData = json.decode(registrationDataStr) as Map<String, dynamic>;
          if (registrationData['userData'] != null) {
            final userDataMap = registrationData['userData'] as Map<String, dynamic>;
            dateOfBirth = userDataMap['dob']?.toString() ?? userDataMap['dateOfBirth']?.toString();
          }
        }
        
        // If not found in registration data, try user_data
        if (dateOfBirth == null) {
          final prefsUserData = prefs.getString('user_data');
          if (prefsUserData != null) {
            final parsedUserData = json.decode(prefsUserData) as Map<String, dynamic>;
            dateOfBirth = parsedUserData['dob']?.toString() ?? parsedUserData['dateOfBirth']?.toString();
          }
        }
      }
      
      setState(() {
        _nationalId = nationalId ?? '';
        _dateOfBirth = dateOfBirth ?? '';
        _isLoading = false;
      });
      
      // 💡 Sync data back to secure storage if it was found in SharedPreferences
      if (nationalId != null && userDataStr == null) {
        await _secureStorage.write(key: 'national_id', value: nationalId);
        if (userData != null) {
          await _secureStorage.write(key: 'user_data', value: json.encode({
            ...userData,
            'dob': dateOfBirth,
          }));
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openPdf(String type) async {
    String url = type == 'terms' 
      ? 'https://icreditdept.com/terms.pdf'
      : 'https://icreditdept.com/privacy.pdf';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $type document')),
      );
    }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Back Button Row
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: Row(
                    mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(
                          isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 64.0),
                      child: Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.center,
                        children: [
                          // Company Logo - centered for both
                          Center(
                            child: Image.asset(
                              'assets/images/nayifat-logo-no-bg.png',
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 80),

                          // Loan Application Title - centered for both
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                children: [
                                  Text(
                                    isArabic ? 'طلب ' : 'Loan ',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w300,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    isArabic ? 'تمويل' : 'Application',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 4,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Form fields with modern styling
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Directionality(
                                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      child: TextFormField(
                                        initialValue: _nationalId,
                                        readOnly: true,
                                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                        style: TextStyle(
                                          color: textColor,
                                          locale: isArabic ? const Locale('ar', '') : const Locale('en', ''),
                                        ),
                                        decoration: InputDecoration(
                                          labelText: isArabic ? 'رقم الهوية' : 'National ID',
                                          labelStyle: TextStyle(color: textColor),
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: Color(themeProvider.isDarkMode 
                                                  ? Constants.darkFormBorderColor 
                                                  : Constants.lightFormBorderColor),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: Color(themeProvider.isDarkMode 
                                                  ? Constants.darkFormBorderColor 
                                                  : Constants.lightFormBorderColor),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: themeProvider.isDarkMode 
                                              ? Color(Constants.darkFormBackgroundColor)
                                              : Color(Constants.darkFormBackgroundColor).withOpacity(0.06),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: isArabic ? 12 : null,
                                      left: isArabic ? null : 12,
                                      top: 16,
                                      child: Icon(Icons.person_outline, color: primaryColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Stack(
                                  children: [
                                    Directionality(
                                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      child: TextFormField(
                                        initialValue: _dateOfBirth,
                                        readOnly: true,
                                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                        style: TextStyle(
                                          color: textColor,
                                          locale: isArabic ? const Locale('ar', '') : const Locale('en', ''),
                                        ),
                                        decoration: InputDecoration(
                                          labelText: isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                                          labelStyle: TextStyle(color: textColor),
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: Color(themeProvider.isDarkMode 
                                                  ? Constants.darkFormBorderColor 
                                                  : Constants.lightFormBorderColor),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: Color(themeProvider.isDarkMode 
                                                  ? Constants.darkFormBorderColor 
                                                  : Constants.lightFormBorderColor),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Constants.formBorderRadius),
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: themeProvider.isDarkMode 
                                              ? Color(Constants.darkFormBackgroundColor)
                                              : Color(Constants.darkFormBackgroundColor).withOpacity(0.06),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: isArabic ? 12 : null,
                                      left: isArabic ? null : 12,
                                      top: 16,
                                      child: Icon(Icons.calendar_today, color: primaryColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Terms and Conditions with modern styling
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Directionality(
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                              child: Row(
                                mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: _termsAccepted,
                                      onChanged: (value) {
                                        setState(() => _termsAccepted = value ?? false);
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      activeColor: primaryColor,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Wrap(
                                        alignment: isArabic ? WrapAlignment.end : WrapAlignment.start,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            isArabic ? 'أوافق على ' : 'I agree to the ',
                                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                            style: TextStyle(color: textColor),
                                          ),
                                          GestureDetector(
                                            onTap: () => _openPdf('terms'),
                                            child: Text(
                                              isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                                              textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                              style: TextStyle(
                                                color: primaryColor,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            isArabic ? ' و ' : ' and ',
                                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                            style: TextStyle(color: textColor),
                                          ),
                                          GestureDetector(
                                            onTap: () => _openPdf('privacy'),
                                            child: Text(
                                              isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                                              textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                              style: TextStyle(
                                                color: primaryColor,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
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
                          const SizedBox(height: 32),

                          // Next Button with modern styling
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: !_termsAccepted ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoanApplicationDetailsScreen(isArabic: isArabic),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor: primaryColor.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor: primaryColor.withOpacity(0.5),
                              ),
                              child: Text(
                                isArabic ? 'التالي' : 'Next',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 