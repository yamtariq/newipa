import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:lottie/lottie.dart';

class LoanApplicationStatusScreen extends StatelessWidget {
  final bool isArabic;
  final bool isRejected; // true for rejection, false for error
  final String? errorCode;

  const LoanApplicationStatusScreen({
    Key? key,
    required this.isArabic,
    required this.isRejected,
    this.errorCode,
  }) : super(key: key);

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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.1),
                  backgroundColor,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Back Button and Title Row
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
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
                      Text(
                        isArabic ? 'حالة الطلب' : 'Application Status',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Status Icon/Animation
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: isRejected
                                ? Lottie.asset(
                                    'assets/animations/rejected.json',
                                    repeat: false,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.cancel_outlined,
                                        size: 120,
                                        color: Colors.red,
                                      );
                                    },
                                  )
                                : Lottie.asset(
                                    'assets/animations/error.json',
                                    repeat: true,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.error_outline,
                                        size: 120,
                                        color: Colors.orange,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 32),
                          // Status Title
                          Text(
                            isRejected
                                ? (isArabic ? 'تم رفض الطلب' : 'Application Rejected')
                                : (isArabic ? 'خطأ في الطلب' : 'Application Error'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isRejected ? Colors.red : Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Status Message
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isRejected
                                      ? (isArabic
                                          ? 'عذراً، تم رفض طلب التمويل الخاص بك.'
                                          : 'Sorry, your finance application has been rejected.')
                                      : (isArabic
                                          ? 'عذراً، حدث خطأ أثناء معالجة طلبك.'
                                          : 'Sorry, an error occurred while processing your application.'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: textColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isRejected
                                      ? (isArabic
                                          ? 'لمعرفة سبب الرفض، يرجى التواصل مع خدمة العملاء.'
                                          : 'To know the reason for rejection, please contact customer service.')
                                      : (isArabic
                                          ? 'لمزيد من المعلومات، يرجى التواصل مع خدمة العملاء.'
                                          : 'For more information, please contact customer service.'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor.withOpacity(0.7),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (errorCode != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    isArabic
                                        ? 'رقم المرجع: $errorCode'
                                        : 'Reference Number: $errorCode',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Contact Customer Service Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to customer service page
                                Navigator.pushNamed(context, '/customer-service');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor: primaryColor.withOpacity(0.5),
                              ),
                              child: Text(
                                isArabic ? 'تواصل مع خدمة العملاء' : 'Contact Customer Service',
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