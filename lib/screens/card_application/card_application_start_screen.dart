import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/custom_button.dart';
import 'card_application_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../utils/constants.dart';

class CardApplicationStartScreen extends StatefulWidget {
  final bool isArabic;
  const CardApplicationStartScreen({Key? key, this.isArabic = false}) : super(key: key);

  @override
  State<CardApplicationStartScreen> createState() => _CardApplicationStartScreenState();
}

class _CardApplicationStartScreenState extends State<CardApplicationStartScreen> {
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
      final userDataStr = await _secureStorage.read(key: 'user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        setState(() {
          _nationalId = userData['national_id'] ?? '';
          _dateOfBirth = userData['dob'] ?? '';
          _isLoading = false;
        });
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1B3E6C).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),
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
                          color: Color(Constants.primaryColorValue),
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
                            child: SvgPicture.asset(
                              'assets/images/nayifat-logo.svg',
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 80),

                          // Card Application Title - centered for both
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3E6C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                isArabic ? 'طلب بطاقة' : 'Card Application',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(Constants.primaryColorValue),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Form fields with modern styling
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                                          locale: isArabic ? const Locale('ar', '') : const Locale('en', ''),
                                        ),
                                        decoration: InputDecoration(
                                          labelText: isArabic ? 'رقم الهوية' : 'National ID',
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          contentPadding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: isArabic ? 12 : null,
                                      left: isArabic ? null : 12,
                                      top: 16,
                                      child: Icon(Icons.person_outline, color: Color(Constants.primaryColorValue)),
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
                                          locale: isArabic ? const Locale('ar', '') : const Locale('en', ''),
                                        ),
                                        decoration: InputDecoration(
                                          labelText: isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          contentPadding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: isArabic ? 12 : null,
                                      left: isArabic ? null : 12,
                                      top: 16,
                                      child: Icon(Icons.calendar_today, color: Color(Constants.primaryColorValue)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                                      activeColor: Color(Constants.primaryColorValue),
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
                                          ),
                                          GestureDetector(
                                            onTap: () => _openPdf('terms'),
                                            child: Text(
                                              isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
                                              textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                              style: const TextStyle(
                                                color: Color(Constants.primaryColorValue),
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            isArabic ? ' و ' : ' and ',
                                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          ),
                                          GestureDetector(
                                            onTap: () => _openPdf('privacy'),
                                            child: Text(
                                              isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                                              textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                              style: const TextStyle(
                                                color: Color(Constants.primaryColorValue),
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
                                    builder: (context) => CardApplicationDetailsScreen(isArabic: isArabic),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(Constants.primaryColorValue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor: const Color(0xFF1B3E6C).withOpacity(0.5),
                              ),
                              child: Text(
                                isArabic ? 'التالي' : 'Next',
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