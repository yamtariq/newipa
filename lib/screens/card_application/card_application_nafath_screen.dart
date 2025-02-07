import 'package:flutter/material.dart';
import '../../widgets/nafath_verification_dialog.dart';
import 'card_application_details_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class CardApplicationNafathScreen extends StatefulWidget {
  final bool isArabic;
  final String nationalId;

  const CardApplicationNafathScreen({
    Key? key,
    required this.isArabic,
    required this.nationalId,
  }) : super(key: key);

  @override
  State<CardApplicationNafathScreen> createState() => _CardApplicationNafathScreenState();
}

class _CardApplicationNafathScreenState extends State<CardApplicationNafathScreen> {
  bool _isLoading = false;

  void _showNafathDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NafathVerificationDialog(
        nationalId: widget.nationalId,
        isArabic: widget.isArabic,
        onCancel: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to previous screen
        },
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        if (result['verified'] == true) {
          // Navigate to details screen on success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CardApplicationDetailsScreen(
                isArabic: widget.isArabic,
              ),
            ),
          );
        } else {
          // Handle verification failure
          String status = result['status'] ?? 'UNKNOWN';
          String errorMessage = widget.isArabic
              ? _getArabicErrorMessage(status)
              : _getEnglishErrorMessage(status);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context); // Go back to previous screen
        }
      }
    });
  }

  String _getArabicErrorMessage(String status) {
    switch (status) {
      case 'EXPIRED':
        return 'انتهت صلاحية طلب نفاذ';
      case 'REJECTED':
        return 'تم رفض طلب نفاذ';
      case 'FAILED':
        return 'فشل طلب نفاذ';
      default:
        return 'فشل في التحقق من نفاذ';
    }
  }

  String _getEnglishErrorMessage(String status) {
    switch (status) {
      case 'EXPIRED':
        return 'Nafath request has expired';
      case 'REJECTED':
        return 'Nafath request was rejected';
      case 'FAILED':
        return 'Nafath request failed';
      default:
        return 'Nafath verification failed';
    }
  }

  @override
  void initState() {
    super.initState();
    // Show Nafath dialog after a short delay to allow screen transition
    Future.delayed(const Duration(milliseconds: 300), _showNafathDialog);
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
    final textColor = Color(themeProvider.isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 8,
              left: widget.isArabic ? null : 8,
              right: widget.isArabic ? 8 : null,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  widget.isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                  color: primaryColor,
                ),
              ),
            ),
            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/nafath_transparent.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isArabic
                        ? 'جاري التحقق من نفاذ...'
                        : 'Verifying with Nafath...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 