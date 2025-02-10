import 'package:flutter/material.dart';
import '../../widgets/nafath_verification_dialog.dart';
import 'loan_application_details_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../services/dakhli_service.dart';
import 'loan_application_salary_selection_screen.dart';
import 'dart:convert';

class LoanApplicationNafathScreen extends StatefulWidget {
  final bool isArabic;
  final String nationalId;

  const LoanApplicationNafathScreen({
    Key? key,
    required this.isArabic,
    required this.nationalId,
  }) : super(key: key);

  @override
  State<LoanApplicationNafathScreen> createState() => _LoanApplicationNafathScreenState();
}

class _LoanApplicationNafathScreenState extends State<LoanApplicationNafathScreen> {
  bool _isLoading = false;
  final _dakhliService = DakhliService();

  // 💡 Handle Dakhli API call
  Future<void> _handleDakhliVerification() async {
    print('🔄 Starting Dakhli verification process');
    setState(() => _isLoading = true);

    try {
      print('📡 Calling Dakhli service for National ID: ${widget.nationalId}');
      final dakhliResponse = await _dakhliService.fetchSalaryInfo(widget.nationalId);
      
      if (!mounted) {
        print('⚠️ Widget not mounted after Dakhli API call');
        return;
      }

      print('✅ Dakhli API response received: ${json.encode(dakhliResponse)}');
      final List<Map<String, dynamic>> salaries = List<Map<String, dynamic>>.from(
        dakhliResponse['salaries'] ?? []
      );
      print('📊 Found ${salaries.length} salary records');

      if (salaries.isEmpty) {
        print('⚠️ No salary data found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'لم يتم العثور على بيانات الراتب، يرجى إدخال الراتب يدوياً'
                    : 'No salary data found, please enter salary manually',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoanApplicationDetailsScreen(
                isArabic: widget.isArabic,
              ),
            ),
          );
        }
      } else if (salaries.length == 1) {
        print('✅ Single salary found: ${json.encode(salaries[0])}');
        // Single salary found, save it and proceed
        await _dakhliService.getSavedSalaryData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isArabic
                    ? 'تم التحقق من الراتب بنجاح'
                    : 'Salary verified successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoanApplicationDetailsScreen(
                isArabic: widget.isArabic,
              ),
            ),
          );
        }
      } else {
        print('📝 Multiple salaries found (${salaries.length}), showing selection screen');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoanApplicationSalarySelectionScreen(
                salaries: salaries,
                isArabic: widget.isArabic,
                nationalId: widget.nationalId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in Dakhli verification: ${e.toString()}');
      if (!mounted) {
        print('⚠️ Widget not mounted after error');
        return;
      }
      
      String errorMessage = e.toString();
      String userMessage = widget.isArabic
          ? _getArabicDakhliErrorMessage(errorMessage)
          : _getEnglishDakhliErrorMessage(errorMessage);
      
      print('⚠️ Showing error message to user: $userMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: widget.isArabic ? 'متابعة' : 'Continue',
            textColor: Colors.white,
            onPressed: () {
              print('👆 User tapped Continue on error message');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoanApplicationDetailsScreen(
                    isArabic: widget.isArabic,
                  ),
                ),
              );
            },
          ),
        ),
      );
      
      // Auto-navigate after showing error
      print('⏳ Starting auto-navigation delay after error');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print('🔄 Auto-navigating to details screen after error');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoanApplicationDetailsScreen(
                isArabic: widget.isArabic,
              ),
            ),
          );
        } else {
          print('⚠️ Widget not mounted during auto-navigation');
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('🏁 Dakhli verification process completed');
    }
  }

  String _getArabicDakhliErrorMessage(String error) {
    if (error.contains('Network connection')) {
      return 'خطأ في الاتصال بالشبكة، يرجى التحقق من اتصال الإنترنت';
    } else if (error.contains('timeout')) {
      return 'انتهت مهلة الطلب، يرجى المحاولة مرة أخرى';
    } else if (error.contains('Unauthorized')) {
      return 'غير مصرح بالوصول، يرجى المحاولة مرة أخرى';
    } else if (error.contains('Invalid response format')) {
      return 'تنسيق استجابة غير صالح من الخادم';
    } else if (error.contains('Salary information not found')) {
      return 'لم يتم العثور على معلومات الراتب';
    }
    return 'حدث خطأ أثناء جلب بيانات الراتب، يرجى إدخال الراتب يدوياً';
  }

  String _getEnglishDakhliErrorMessage(String error) {
    if (error.contains('Network connection')) {
      return 'Network connection error, please check your internet connection';
    } else if (error.contains('timeout')) {
      return 'Request timed out, please try again';
    } else if (error.contains('Unauthorized')) {
      return 'Unauthorized access, please try again';
    } else if (error.contains('Invalid response format')) {
      return 'Invalid response format from server';
    } else if (error.contains('Salary information not found')) {
      return 'Salary information not found';
    }
    return 'Error fetching salary data, please enter salary manually';
  }

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
    ).then((result) async {
      if (result != null && result is Map<String, dynamic>) {
        if (result['verified'] == true) {
          // 💡 Call Dakhli API after successful Nafath verification
          await _handleDakhliVerification();
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