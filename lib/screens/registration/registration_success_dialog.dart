import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/marked.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic 
                ? (isDeviceReplacement ? 'تم إعداد الجهاز الجديد' : 'تم التسجيل بنجاح')
                : (isDeviceReplacement ? 'New Device Setup Complete' : 'Registration Successful'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? (isDeviceReplacement 
                    ? 'تم إعداد جهازك الجديد بنجاح${enableBiometric ? ' مع تفعيل السمات الحيوية' : ''}'
                    : 'تم إنشاء حسابك بنجاح${enableBiometric ? ' مع تفعيل السمات الحيوية' : ''}')
                : (isDeviceReplacement
                    ? 'Your new device has been set up successfully${enableBiometric ? ' with biometric authentication enabled' : ''}'
                    : 'Your account has been created successfully${enableBiometric ? ' with biometric authentication enabled' : ''}'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: Text(
            isArabic ? 'متابعة' : 'Continue',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}