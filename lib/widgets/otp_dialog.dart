import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class BackspaceTextInputFormatter extends TextInputFormatter {
  final Function() onBackspace;

  BackspaceTextInputFormatter({required this.onBackspace});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text.isNotEmpty && newValue.text.isEmpty) {
      onBackspace();
    }
    return newValue;
  }
}

class OTPDialog extends StatefulWidget {
  final String nationalId;
  final bool isArabic;
  final Future<Map<String, dynamic>> Function() onResendOTP;
  final Future<Map<String, dynamic>> Function(String otp) onVerifyOTP;

  const OTPDialog({
    Key? key,
    required this.nationalId,
    required this.isArabic,
    required this.onResendOTP,
    required this.onVerifyOTP,
  }) : super(key: key);

  @override
  State<OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<OTPDialog> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _timer;
  int _timeLeft = 120; // 2 minutes
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Ensure focus and keyboard are shown after dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timeLeft = 120;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = (_timeLeft / 60).floor();
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onVerifyOTP(_otpController.text);
      
      if (result['status'] == 'success') {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final message = result['message'] ?? '';
        final arabicMessage = _getArabicErrorMessage(message);
        throw Exception(widget.isArabic ? arabicMessage : message);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getArabicErrorMessage(String englishMessage) {
    switch (englishMessage.toLowerCase()) {
      case 'invalid or expired otp':
        return 'رمز التحقق غير صالح أو منتهي الصلاحية';
      case 'otp has expired':
        return 'انتهت صلاحية رمز التحقق';
      case 'national_id and otp code are required':
        return 'الرقم الوطني ورمز التحقق مطلوبان';
      case 'failed to mark otp as used':
        return 'فشل في تحديث حالة رمز التحقق';
      case 'invalid request method':
        return 'طريقة طلب غير صالحة';
      case 'otp verified successfully':
        return 'تم التحقق من الرمز بنجاح';
      default:
        return 'حدث خطأ ما!';
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onResendOTP();
      
      if (result['status'] == 'success') {
        setState(() {
          _errorMessage = null;
        });
        _startTimer();
        _otpController.clear();
      } else {
        final message = result['message'] ?? '';
        final arabicMessage = _getArabicErrorMessage(message);
        throw Exception(widget.isArabic ? arabicMessage : message);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor);
    final backgroundColor = Color(isDarkMode ? Constants.darkFormBackgroundColor : Constants.lightFormBackgroundColor);
    final borderColor = Color(isDarkMode ? Constants.darkFormBorderColor : Constants.lightFormBorderColor);
    final focusedBorderColor = Color(isDarkMode ? Constants.darkFormFocusedBorderColor : Constants.lightFormFocusedBorderColor);
    final labelTextColor = Color(isDarkMode ? Constants.darkLabelTextColor : Constants.lightLabelTextColor);
    final hintTextColor = Color(isDarkMode ? Constants.darkHintTextColor : Constants.lightHintTextColor);
    
    return Dialog(
      backgroundColor: Color(isDarkMode ? Constants.darkSurfaceColor : Constants.lightSurfaceColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.containerBorderRadius),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 24 : 40),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    child: Lottie.asset(
                      'assets/animations/otp-animation.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isArabic ? 'رمز التحقق' : 'OTP Verification',
                    textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: labelTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isArabic
                            ? 'الرجاء إدخال رمز التحقق المرسل إلى رقم هاتفك'
                            : 'Please enter the verification code sent to your phone',
                        textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          color: labelTextColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _otpController,
                            focusNode: _focusNode,
                            autofocus: true,
                            showCursor: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              setState(() {
                                _errorMessage = null;
                              });
                              if (value.length == 6) {
                                _handleVerify();
                              }
                            },
                            decoration: InputDecoration(
                              counterText: '',
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
                                borderSide: BorderSide(color: focusedBorderColor),
                              ),
                              hintText: '______',
                              hintStyle: TextStyle(
                                color: hintTextColor,
                                fontSize: 20,
                                letterSpacing: 8,
                              ),
                              filled: true,
                              fillColor: backgroundColor,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: TextStyle(
                              letterSpacing: 8,
                              fontSize: 20,
                              color: labelTextColor,
                            ),
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.red[300] : Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          color: _canResend 
                            ? (isDarkMode ? Colors.red[300] : Colors.red)
                            : hintTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                  child: Text(
                    widget.isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      color: hintTextColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _canResend && !_isLoading ? _handleResend : null,
                  child: Text(
                    widget.isArabic ? 'إعادة إرسال' : 'Resend',
                    style: TextStyle(
                      color: _canResend && !_isLoading 
                        ? themeColor
                        : hintTextColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Constants.buttonBorderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isArabic ? 'تحقق' : 'Verify',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}