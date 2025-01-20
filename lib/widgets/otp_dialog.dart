import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';

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
        throw Exception(result['message']);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      
      if (result['success'] == true) {
        _startTimer();
        _otpController.clear();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: Column(
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
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isArabic
                  ? 'الرجاء إدخال رمز التحقق المرسل إلى رقم هاتفك'
                  : 'Please enter the verification code sent to your phone',
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              focusNode: _focusNode,
              autofocus: true,
              showCursor: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (value.length == 6) {
                  _handleVerify();
                }
              },
              decoration: InputDecoration(
                counterText: '',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
                hintText: '______',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.5),
                  fontSize: 20,
                  letterSpacing: 8,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(
                letterSpacing: 8,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formattedTime,
              style: TextStyle(
                color: _canResend ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: _canResend && !_isLoading ? _handleResend : null,
          child: Text(
            widget.isArabic ? 'إعادة إرسال' : 'Resend',
            style: TextStyle(
              color: _canResend && !_isLoading ? null : Colors.grey,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerify,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.isArabic ? 'تحقق' : 'Verify'),
        ),
      ],
    );
  }
}