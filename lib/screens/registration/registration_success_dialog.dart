import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class RegistrationSuccessDialog extends StatelessWidget {
  final bool isArabic;
  final bool enableBiometric;
  final bool isDeviceReplacement;
  final VoidCallback onContinue;

  const RegistrationSuccessDialog({
    Key? key,
    required this.isArabic,
    this.enableBiometric = false,
    this.isDeviceReplacement = false,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final labelTextColor = Color(isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintTextColor = Color(isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);
    final surfaceColor = Color(isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final successColor = Color(isDarkMode 
        ? Constants.darkNavbarActiveIcon 
        : Constants.lightNavbarActiveIcon);
    final buttonTextColor = Color(isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final borderColor = Color(isDarkMode 
        ? Constants.darkFormBorderColor 
        : Constants.lightFormBorderColor);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
      ),
      backgroundColor: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
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
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading celebration animation: $error');
                    return Icon(
                      Icons.celebration,
                      size: 100,
                      color: successColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isArabic ? 'مبروك' : 'Congratulations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: Text(
                isArabic
                    ? (isDeviceReplacement ? 'تم إعداد الجهاز الجديد بنجاح' : 'تم التسجيل بنجاح')
                    : (isDeviceReplacement ? 'New device setup completed successfully' : 'Registration completed successfully'),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  color: labelTextColor,
                ),
              ),
            ),
            if (enableBiometric) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: Text(
                  isArabic
                      ? 'تم تفعيل السمات الحيوية للدخول السريع'
                      : 'Biometric login enabled for quick access',
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    color: labelTextColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: Text(
                isArabic 
                    ? 'يمكنك الآن تسجيل الدخول باستخدام رمز الدخول أو السمات الحيوية'
                    : 'You can now sign in using MPIN or biometrics',
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  color: hintTextColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                  ),
                ),
                child: Text(
                  isArabic ? 'متابعة' : 'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: buttonTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}