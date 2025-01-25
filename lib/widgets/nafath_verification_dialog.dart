import 'dart:async';
import 'package:flutter/material.dart';
import '../services/nafath_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class NafathVerificationDialog extends StatefulWidget {
  final String nationalId;
  final bool isArabic;
  final Function() onCancel;

  const NafathVerificationDialog({
    Key? key,
    required this.nationalId,
    required this.isArabic,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<NafathVerificationDialog> createState() => _NafathVerificationDialogState();
}

class _NafathVerificationDialogState extends State<NafathVerificationDialog> {
  final NafathService _nafathService = NafathService();
  Timer? _statusCheckTimer;
  bool _isLoading = true;
  String? _random;
  String? _transId;
  String? _errorMessage;
  bool _isVerified = false;
  Map<String, dynamic>? _verificationResponse;

  @override
  void initState() {
    super.initState();
    _initializeNafathRequest();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNafathRequest() async {
    try {
      print('\n=== NAFATH REQUEST INITIALIZATION START ===');
      print('Sending request for ID: ${widget.nationalId}');
      
      final response = await _nafathService.createRequest(widget.nationalId);
      print('Initial Nafath Response: $response');
      
      if (response['success'] == true && response['result'] != null) {
        final result = response['result'];
        print('Request created successfully:');
        print('- Random Code: ${result['random']}');
        print('- Transaction ID: ${result['transId']}');
        
        setState(() {
          _random = result['random'];
          _transId = result['transId'];
          _isLoading = false;
        });
        _startStatusCheck();
      } else {
        print('Failed to create request:');
        print('- Success: ${response['success']}');
        print('- Message: ${response['message']}');
        setState(() {
          _errorMessage = widget.isArabic
              ? 'فشل في إنشاء طلب نفاذ'
              : 'Failed to create Nafath request';
          _isLoading = false;
        });
      }
      print('=== NAFATH REQUEST INITIALIZATION END ===\n');
    } catch (e) {
      print('Error in initialization:');
      print('- Exception: $e');
      setState(() {
        _errorMessage = widget.isArabic
            ? 'حدث خطأ أثناء إنشاء طلب نفاذ'
            : 'Error creating Nafath request';
        _isLoading = false;
      });
    }
  }

  void _startStatusCheck() {
    print('\n=== NAFATH STATUS CHECK STARTED ===');
    print('Will check status every 3 seconds');
    print('Transaction ID: $_transId');
    print('Random Code: $_random\n');
    
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        if (_transId == null || _random == null) {
          print('Missing required data for status check:');
          print('- Transaction ID: $_transId');
          print('- Random Code: $_random');
          return;
        }
        
        print('\n--- Status Check Attempt ---');
        print('Checking status for:');
        print('- National ID: ${widget.nationalId}');
        print('- Transaction ID: $_transId');
        print('- Random Code: $_random');
        
        final response = await _nafathService.checkRequestStatus(
          widget.nationalId,
          _transId!,
          _random!,
        );
        
        print('Status Check Response: $response');

        if (response['success'] == true) {
          final status = response['result']['status'];
          print('Status received: $status');
          
          setState(() {
            switch (status) {
              case 'COMPLETED':
                print('✅ Verification COMPLETED');
                print('Full response data: ${response['result']}');
                _statusCheckTimer?.cancel();
                _isVerified = true;
                _verificationResponse = response;
                if (mounted) {
                  print('Closing dialog with success data');
                  Navigator.of(context).pop({
                    'verified': true,
                    'transId': _transId,
                    'random': _random,
                    'response': response['result']
                  });
                }
                break;
              
              case 'WAITING':
                print('⏳ Status PENDING - Waiting for user action');
                break;
              
              case 'EXPIRED':
                print('⚠️ Request EXPIRED');
                _statusCheckTimer?.cancel();
                _errorMessage = widget.isArabic
                    ? 'انتهت صلاحية طلب نفاذ'
                    : 'Nafath request has expired';
                if (mounted) {
                  Navigator.of(context).pop({
                    'verified': false,
                    'transId': _transId,
                    'random': _random,
                    'response': response,
                    'status': 'EXPIRED'
                  });
                }
                break;
              
              case 'REJECTED':
                print('❌ Request REJECTED by user');
                _statusCheckTimer?.cancel();
                _errorMessage = widget.isArabic
                    ? 'تم رفض طلب نفاذ'
                    : 'Nafath request was rejected';
                if (mounted) {
                  Navigator.of(context).pop({
                    'verified': false,
                    'transId': _transId,
                    'random': _random,
                    'response': response,
                    'status': 'REJECTED'
                  });
                }
                break;
              
              case 'FAILED':
                print('❌ Request FAILED');
                _statusCheckTimer?.cancel();
                _errorMessage = widget.isArabic
                    ? 'فشل طلب نفاذ'
                    : 'Nafath request failed';
                if (mounted) {
                  Navigator.of(context).pop({
                    'verified': false,
                    'transId': _transId,
                    'random': _random,
                    'response': response,
                    'status': 'FAILED'
                  });
                }
                break;
              
              default:
                print('❓ Unknown status received: $status');
                _errorMessage = widget.isArabic
                    ? 'حالة غير معروفة: $status'
                    : 'Unknown status: $status';
                break;
            }
          });
        } else {
          print('Status check failed:');
          print('- Success: ${response['success']}');
          print('- Message: ${response['message']}');
        }
      } catch (e) {
        print('Error checking status:');
        print('- Exception: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = Color(isDarkMode 
        ? Constants.darkPrimaryColor 
        : Constants.lightPrimaryColor);
    final surfaceColor = Color(isDarkMode 
        ? Constants.darkSurfaceColor 
        : Constants.lightSurfaceColor);
    final labelTextColor = Color(isDarkMode 
        ? Constants.darkLabelTextColor 
        : Constants.lightLabelTextColor);
    final hintTextColor = Color(isDarkMode 
        ? Constants.darkHintTextColor 
        : Constants.lightHintTextColor);

    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _isLoading 
            ? [
                const SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isArabic
                      ? 'جاري إنشاء طلب نفاذ...'
                      : 'Creating Nafath request...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: labelTextColor),
                ),
              ]
            : [
              Container(
                height: 100,
                width: 100,
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/nafath_transparent.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.isArabic
                    ? 'رمز التحقق من نفاذ'
                    : 'Nafath Verification Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _random ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: themeColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, 
                        color: Colors.red, 
                        size: 24
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                widget.isArabic
                    ? 'يرجى فتح تطبيق نفاذ والموافقة على طلب التحقق باستخدام الرمز أعلاه'
                    : 'Please open Nafath app and approve the verification request using the code above',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: hintTextColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_errorMessage != null)
            // TextButton(
            //   onPressed: _initializeNafathRequest,
            //   style: TextButton.styleFrom(
            //     foregroundColor: themeColor,
            //   ),
            //   child: Text(widget.isArabic ? 'إعادة المحاولة' : 'Try Again'),
            // ),
          TextButton(
            onPressed: () {
              _statusCheckTimer?.cancel();
              widget.onCancel();
              Navigator.of(context).pop({
                'verified': false,
                'transId': _transId,
                'random': _random,
                'response': null
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: hintTextColor,
            ),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    );
  }
} 