import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/loan_service.dart';
import '../../screens/main_page.dart';
import '../../screens/loans_page.dart';
import '../../screens/loans_page_ar.dart';
import '../../providers/theme_provider.dart';
import '../../screens/customer_service_screen.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';

class LoanOfferScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isArabic;

  const LoanOfferScreen({
    Key? key,
    required this.userData,
    required this.isArabic,
  }) : super(key: key);

  @override
  State<LoanOfferScreen> createState() => _LoanOfferScreenState();
}

class _LoanOfferScreenState extends State<LoanOfferScreen> {
  // Initialize with default values
  double financeAmount = 0;
  double emi = 0;
  int tenure = 60;
  bool showCongratulations = false;
  String? applicationNumber;
  bool get isArabic => widget.isArabic;
  bool _isLoading = true;
  String? _error;
  bool _shouldContactSupport = false;
  double _maxFinanceAmount = 0;
  double _maxEMI = 0;
  double _totalRepayment = 0;
  double _interest = 0;
  double _flatRate = 0;  // Add flat rate storage
  
  // Store original values from API
  double _originalFinanceAmount = 0;
  double _originalEMI = 0;
  double _originalTotalRepayment = 0;
  double _originalInterest = 0;
  int _originalTenure = 60;

  @override
  void initState() {
    super.initState();
    print('\n=== LOAN OFFER SCREEN - INITIALIZATION ===');
    print('Timestamp: ${DateTime.now()}');
    print('Response Data:');
    print('User Data: ${const JsonEncoder.withIndent('  ').convert(widget.userData)}');
    
    // 💡 First check for errors in the response
    if (widget.userData['success'] == false) {
      print('\nResponse indicates failure. Checking error details...');
      setState(() => _shouldContactSupport = true); // All error cases need customer care link
      
      // Check if there are any errors in the response
      if (widget.userData['errors'] != null && widget.userData['errors'] is List && widget.userData['errors'].isNotEmpty) {
        final error = widget.userData['errors'][0];
        print('Error details: ${const JsonEncoder.withIndent('  ').convert(error)}');
        
        // Case 1: Already have active application
        if (error['errorCode'] == '2-201') {
          print('Detected error code 2-201: Active application exists');
          
          // 💡 Extract application ID from error description
          String applicationId = '';
          final errorDesc = error['errorDesc']?.toString() ?? '';
          final applicationIdMatch = RegExp(r'Application Id (\d+)').firstMatch(errorDesc);
          if (applicationIdMatch != null) {
            applicationId = applicationIdMatch.group(1) ?? '';
          }
          
          setState(() {
            _error = widget.isArabic 
              ? 'لديك طلب نشط بالفعل في النظام برقم $applicationId. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
              : 'You already have an active application in pipeline (Application #$applicationId). Please contact customer care for more details.';
            _isLoading = false;
          });
          print('=== LOAN OFFER SCREEN - END (ACTIVE APPLICATION) ===\n');
          return;
        }
        
        // Case 2: Not eligible
        if (error['errorDesc']?.toString().toLowerCase().contains('not eligible') == true) {
          print('Detected not eligible case from error description');
          setState(() {
            _error = widget.isArabic 
              ? 'عذراً، لم تتم الموافقة على طلبك في هذا الوقت. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
              : 'Unfortunately your application is not approved at this time. Please contact customer care for more details.';
            _isLoading = false;
          });
          print('=== LOAN OFFER SCREEN - END (NOT ELIGIBLE) ===\n');
          return;
        }
        
        // Case 3: Other errors
        print('Unhandled error case. Using generic error message');
        setState(() {
          _error = widget.isArabic 
            ? 'حدث خطأ غير متوقع. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
            : 'An unexpected error occurred. Please contact customer care for more details.';
          _isLoading = false;
        });
        print('=== LOAN OFFER SCREEN - END (GENERIC ERROR) ===\n');
        return;
      }
      
      // If no specific error details, show generic error
      print('No specific error details found. Using generic error message');
      setState(() {
        _error = widget.isArabic 
          ? 'حدث خطأ غير متوقع. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
          : 'An unexpected error occurred. Please contact customer care for more details.';
        _isLoading = false;
      });
      print('=== LOAN OFFER SCREEN - END (NO ERROR DETAILS) ===\n');
      return;
    }
    
    // Case 4: Approved with eligibleAmount - proceed with offer screen
    if (widget.userData['result'] != null) {
      print('\nProcessing approved case with eligible amount');
      final result = widget.userData['result'];
      
      setState(() {
        _isLoading = false;
        _error = null;
        
        // Set finance amount
        _maxFinanceAmount = double.tryParse(result['eligibleAmount']?.toString() ?? '0') ?? 0;
        financeAmount = _maxFinanceAmount;
        _originalFinanceAmount = _maxFinanceAmount;
        
        // Set EMI
        _maxEMI = double.tryParse(result['eligibleEmi']?.toString() ?? '0') ?? 0;
        emi = _maxEMI;
        _originalEMI = _maxEMI;
        
        // Set tenure
        tenure = 60; // Default tenure
        _originalTenure = tenure;
        
        // 💡 Calculate total repayment from EMI and tenure
        _totalRepayment = emi * tenure;
        _originalTotalRepayment = _totalRepayment;
        
        // 💡 Calculate interest (total repayment - principal)
        _interest = _totalRepayment - financeAmount;
        _originalInterest = _interest;
        
        // 💡 Calculate flat rate using the formula:
        // Flat Rate = (Interest) / (Principal × Years)
        _flatRate = _interest / (financeAmount * (tenure / 12));
        // Round to 4 decimal places
        _flatRate = double.parse(_flatRate.toStringAsFixed(4));
        
        print('\nInitialized values:');
        print('Finance Amount: $financeAmount');
        print('EMI: $emi');
        print('Tenure: $tenure');
        print('Total Repayment: $_totalRepayment');
        print('Interest: $_interest');
        print('Calculated Flat Rate: $_flatRate');
      });
      print('=== LOAN OFFER SCREEN - END (APPROVED) ===\n');
      return;
    }
    
    // If we reach here, something unexpected happened
    print('\nUnexpected case: No eligible amount found');
    setState(() {
      _shouldContactSupport = true;
      _error = widget.isArabic 
        ? 'حدث خطأ غير متوقع. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
        : 'An unexpected error occurred. Please contact customer care for more details.';
      _isLoading = false;
    });
    print('=== LOAN OFFER SCREEN - END (UNEXPECTED CASE) ===\n');
  }

  // Add helper methods for loan calculations using flat rate
  Map<String, double> _recalculateLoan(double principal, int months) {
    // Convert tenure to years for flat rate calculation
    final tenureYears = months / 12;
    
    // Use the same flat rate as the API (5%)
    const flatRate = 0.05;
    
    // Calculate total interest using flat rate formula: P * R * T
    final interest = principal * flatRate * tenureYears;
    
    // Calculate total repayment
    final totalRepayment = principal + interest;
    
    // Calculate EMI = total repayment / number of months
    final calculatedEMI = totalRepayment / months;
    
    // If EMI exceeds max EMI, recalculate everything
    if (calculatedEMI > _maxEMI) {
      // Use the reverse flat rate formula from the API:
      // EMI = P(1 + R*T) / (12*T)
      // P = EMI(12*T) / (1 + R*T)
      final newPrincipal = (_maxEMI * 12 * tenureYears) / (1 + (flatRate * tenureYears));
      
      // Round down to nearest thousand as done in the API
      final roundedPrincipal = (newPrincipal ~/ 1000) * 1000.0;
      
      // Recalculate everything with the new principal
      final newInterest = roundedPrincipal * flatRate * tenureYears;
      final newTotalRepayment = roundedPrincipal + newInterest;
      final newEMI = newTotalRepayment / months;
      
      return {
        'principal': roundedPrincipal,
        'emi': newEMI,
        'totalPayment': newTotalRepayment,
        'totalInterest': newInterest,
      };
    }
    
    return {
      'principal': principal,
      'emi': calculatedEMI,
      'totalPayment': totalRepayment,
      'totalInterest': interest,
    };
  }

  void _updateFinanceAmount(double value) {
    setState(() {
      // If we're at original tenure, calculate proportionally from original values
      if (tenure == _originalTenure) {
        final ratio = value / _originalFinanceAmount;
        financeAmount = value.clamp(10000, _maxFinanceAmount);
        emi = _originalEMI * ratio;
        _interest = _originalInterest * ratio;
        _totalRepayment = financeAmount + _interest;
      } else {
        // Otherwise use flat rate calculations
        financeAmount = (value.clamp(10000, _maxFinanceAmount) ~/ 1000) * 1000.0;
        final tenureYears = tenure / 12;
        
        _interest = financeAmount * _flatRate * tenureYears;
        _totalRepayment = financeAmount + _interest;
        emi = _totalRepayment / tenure;
        
        if (emi > _maxEMI) {
          emi = _maxEMI;
          _totalRepayment = emi * tenure;
          financeAmount = (emi * tenure) / (1 + (_flatRate * tenureYears));
          financeAmount = (financeAmount ~/ 1000) * 1000.0;
          _interest = financeAmount * _flatRate * tenureYears;
          _totalRepayment = financeAmount + _interest;
        }
      }

      print('DEBUG - Finance Update:');
      print('Requested Amount: $value');
      print('Final Amount: $financeAmount');
      print('EMI: $emi (Max: $_maxEMI)');
      print('Total Repayment: $_totalRepayment');
      print('Interest: $_interest');
      print('Using Flat Rate: $_flatRate');
    });
  }

  void _updateTenure(int value) {
    setState(() {
      tenure = value;
      
      // If returning to original tenure, restore original values
      if (tenure == _originalTenure) {
        financeAmount = _originalFinanceAmount;
        emi = _originalEMI;
        _totalRepayment = _originalTotalRepayment;
        _interest = _originalInterest;
        print('DEBUG - Restored original values for tenure $_originalTenure');
      } else {
        // Otherwise recalculate with flat rate
        final tenureYears = tenure / 12;
        
        // Calculate new values
        _interest = financeAmount * _flatRate * tenureYears;
        _totalRepayment = financeAmount + _interest;
        emi = _totalRepayment / tenure;
        
        // If new EMI exceeds max, adjust everything down
        if (emi > _maxEMI) {
          emi = _maxEMI;
          _totalRepayment = emi * tenure;
          financeAmount = (emi * tenure) / (1 + (_flatRate * tenureYears));
          financeAmount = (financeAmount ~/ 1000) * 1000.0;
          _interest = financeAmount * _flatRate * tenureYears;
          _totalRepayment = financeAmount + _interest;
        }
      }

      print('DEBUG - Tenure Update:');
      print('New Tenure: $value months');
      print('Finance Amount: $financeAmount');
      print('EMI: $emi (Max: $_maxEMI)');
      print('Total Repayment: $_totalRepayment');
      print('Interest: $_interest');
      print('Using Flat Rate: $_flatRate');
    });
  }

  void _showCongratulationsDialog() async {
    try {
      setState(() => _isLoading = true);

      // Get user data from secure storage
      final authService = AuthService();
      final userData = await authService.getUserData();
      
      if (userData == null || userData['national_id'] == null) {
        throw Exception('Could not retrieve user data from secure storage');
      }

      // 💡 First call the UpdateAmount API
      final updateAmountData = {
        'AgreementId': widget.userData['application_number']?.toString() ?? '',
        'Amount': financeAmount,
        'Tenure': tenure,
        'FinEmi': emi,
        'RateEliGible': _flatRate * 100
      };

      print('DEBUG - Calling UpdateAmount API:');
      print('URL: ${Constants.endpointFinnoneUpdateAmount}');
      print('Data: $updateAmountData');

      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      // 💡 Prepare proxy request with structured format
      final targetUrl = Uri.parse(Constants.endpointFinnoneUpdateAmount).toString();
      print('\nTarget URL before encoding: $targetUrl');
      
      final proxyRequest = {
        'TargetUrl': targetUrl,
        'Method': 'POST',
        'InternalHeaders': {
          ...Constants.bankApiHeaders,
          'Content-Type': 'application/json',
        },
        'Body': updateAmountData
      };

      final proxyUrl = Uri.parse('${Constants.apiBaseUrl}/proxy/forward');
      print('\nProxy URL: $proxyUrl');
      
      final request = await client.postUrl(proxyUrl);
      
      // Add proxy headers
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': Constants.apiKey,
      };
      
      // Log request details
      print('\n=== UPDATE AMOUNT REQUEST DETAILS ===');
      print('Proxy Endpoint: ${Constants.apiBaseUrl}/proxy/forward');
      print('Target URL: ${Constants.endpointFinnoneUpdateAmount}');
      print('Headers:');
      headers.forEach((key, value) {
        print('$key: ${key.toLowerCase() == 'authorization' ? '[REDACTED]' : value}');
      });
      print('\nProxy Request Body:');
      print(const JsonEncoder.withIndent('  ').convert(proxyRequest));

      // Add headers
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      request.write(jsonEncode(proxyRequest));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('DEBUG - UpdateAmount API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      // 💡 Handle empty response
      if (responseBody.isEmpty) {
        print('\nEmpty response body received');
        throw Exception('Empty response received from server');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update amount: ${response.statusCode}');
      }

      // Parse response to check for success
      final updateAmountResponse = jsonDecode(responseBody);
      if (updateAmountResponse['status'] == 'error') {
        throw Exception(updateAmountResponse['message'] ?? 'Failed to update amount');
      }

      // If UpdateAmount API call is successful, proceed with inserting loan application
      final loanService = LoanService();

      final loanData = {
        'customerDecision': 'ACCEPTED',
        'noteUser': 'CUSTOMER',
        'loan_emi': double.parse(emi.toStringAsFixed(2)),
        'national_id': userData['national_id'],  // 💡 Use national ID from secure storage
        'application_no': int.tryParse(widget.userData['application_number']?.toString() ?? '') ?? 0,
        'consent_status': 'True',
        'nafath_status': 'True',
        'loan_amount': double.parse(financeAmount.toStringAsFixed(2)),
        'loan_purpose': widget.userData['loan_purpose'] ?? 'Personal',
        'loan_tenure': tenure,
        'interest_rate': double.parse((_flatRate * 100).toStringAsFixed(2)),
        'status': 'pending',
        'status_date': DateTime.now().toIso8601String(),
        'remarks': 'Loan offer accepted by customer',
        'note': 'Customer accepted the loan offer with amount ${financeAmount.toStringAsFixed(2)} SAR for $tenure months',
        'consent_status_date': DateTime.now().toIso8601String(),
        'nafath_status_date': DateTime.now().toIso8601String(),
        'loan_emi': double.parse(emi.toStringAsFixed(2))
      };

      print('DEBUG - Sending loan data to API:');
      print('National ID: ${userData['national_id']}'); // 💡 Debug print for national_id
      print('Loan Purpose: ${widget.userData['loan_purpose']}');
      print(const JsonEncoder.withIndent('  ').convert(loanData));

      final response2 = await loanService.insertLoanApplication(loanData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      print('\nDEBUG - Insert Loan Application Response:');
      print(const JsonEncoder.withIndent('  ').convert(response2));

      if (!response2['success']) {
        throw Exception(response2['message'] ?? 'Failed to insert loan application');
      }

      // Get application number from the loan decision response
      final applicationNumber = widget.userData['application_number'] ?? 
        'ERROR'; // This should never happen as we get it from the loan decision API

      print('DEBUG - Using application number in dialog: $applicationNumber');

      // Show congratulations dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(  // Prevent back button from closing dialog
          onWillPop: () async => false,
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/animations/celebration.json',
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading celebration animation: $error');
                          return const Icon(
                            Icons.celebration,
                            size: 100,
                            color: Colors.green,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      isArabic ? 'مبروك!' : 'Congratulations!',
                      style: const TextStyle(
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
                        ? 'تم تقديم طلب التمويل الخاص بك بنجاح!'
                        : 'Your loan application has been submitted successfully!',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'رقم الطلب: $applicationNumber'
                        : 'Application #: $applicationNumber',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'مبلغ التمويل: ${financeAmount.toStringAsFixed(2)} ريال'
                        : 'Loan Amount: SAR ${financeAmount.toStringAsFixed(2)}',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'القسط الشهري: ${emi.toStringAsFixed(2)} ريال'
                        : 'Monthly Installment: SAR ${emi.toStringAsFixed(2)}',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'مدة التمويل: $tenure شهر'
                        : 'Tenure: $tenure months',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'يمكنك متابعة حالة طلبك في صفحة التمويل'
                        : 'You can track your application status in the Loans page',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close dialog
                    
                    // Get current session data
                    final authService = AuthService();
                    final userData = await authService.getUserData();
                    final isDeviceRegistered = await authService.isDeviceRegistered();
                    
                    if (!mounted) return;

                    // Navigate to main page with preserved session state
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => MainPage(
                          isArabic: isArabic,
                          onLanguageChanged: (bool value) {},
                          userData: {
                            ...?userData,
                            'isSessionActive': true,
                            'isSignedIn': true,
                            'deviceRegistered': isDeviceRegistered,
                          },
                          initialRoute: '',
                          isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    isArabic ? 'تم' : 'Done',
                    style: TextStyle(
                      color: Color(Constants.primaryColorValue),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = isArabic 
          ? 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى'
          : 'An error occurred while processing your request. Please try again';
        _isLoading = false;
      });
      print('Error processing loan approval: $e');
    }
  }

  void _showDeclineConfirmation() async {
    final bool? shouldDecline = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            isArabic ? 'تأكيد الرفض' : 'Confirm Decline',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(Constants.primaryColorValue),
            ),
          ),
          content: Text(
            isArabic 
              ? 'هل أنت متأكد من رفض عرض التمويل؟'
              : 'Are you sure you want to decline the loan offer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                isArabic ? 'إلغاء' : 'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isArabic ? 'تأكيد الرفض' : 'Confirm Decline',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDecline == true) {
      _processDecline();
    }
  }

  Future<void> _processDecline() async {
    try {
      setState(() => _isLoading = true);

      // Update loan application in database
      final loanService = LoanService();
      
      final loanData = {
        'customerDecision': 'DECLINED',
        'noteUser': 'CUSTOMER',
        'loan_emi': double.parse(emi.toStringAsFixed(2)),
        'national_id': widget.userData['national_id'],
        'application_no': widget.userData['application_number'],
        'consent_status': 'True',
        'nafath_status': 'True',
        'loan_amount': '0.00',
        'loan_tenure': '0',
        'emi': '0.00',
        'total_repayment': '0.00',
        'interest': '0.00',
        'interest_rate': '0.00',
        'loan_tenure': 0,
        'loan_purpose': widget.userData['loan_purpose'],
        'status': 'declined',
        'remarks': 'Loan offer declined by customer',
        'application_number': widget.userData['application_number'],
        'note': 'Customer declined the loan offer',
        'loan_emi': double.parse(emi.toStringAsFixed(2))
      };

      print('DEBUG - Sending decline data to API:');
      print(loanData);

      final response = await loanService.updateLoanApplication(loanData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update loan application');
      }

      // Show success message
      await showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              isArabic ? 'تم الرفض' : 'Declined Successfully',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(Constants.primaryColorValue),
              ),
            ),
            content: Text(
              isArabic 
                ? 'تم رفض عرض التمويل بنجاح'
                : 'The loan offer has been declined successfully',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isArabic ? 'حسناً' : 'OK',
                  style: TextStyle(
                    color: Color(Constants.primaryColorValue),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Get current session data
      final authService = AuthService();
      final userData = await authService.getUserData();
      final isDeviceRegistered = await authService.isDeviceRegistered();
      
      if (!mounted) return;

      // Navigate to main page with preserved session state
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainPage(
            isArabic: isArabic,
            onLanguageChanged: (bool value) {},
            userData: {
              ...?userData,
              'isSessionActive': true,
              'isSignedIn': true,
              'deviceRegistered': isDeviceRegistered,
            },
            initialRoute: '',
            isDarkMode: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
          ),
        ),
        (route) => false,
      );

    } catch (e) {
      setState(() {
        _error = isArabic 
          ? 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى'
          : 'An error occurred while processing your request. Please try again';
        _isLoading = false;
      });
      print('Error processing loan decline: $e');
    }
  }

  void _showActiveLoanDialog(dynamic applicationNo, String status, String message, String messageAr) async {
    // Convert application number to string
    final String applicationNoStr = applicationNo.toString();
    
    setState(() => _isLoading = false);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              isArabic ? 'طلب تمويل نشط' : 'Active Loan Application',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(Constants.primaryColorValue),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: Text(
                    isArabic ? messageAr : message,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: Text(
                    isArabic 
                      ? 'رقم الطلب: $applicationNoStr'
                      : 'Application #: $applicationNoStr',
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: Text(
                    isArabic 
                      ? 'الحالة: $status'
                      : 'Status: $status',
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: Text(
                    isArabic 
                      ? 'يمكنك متابعة حالة طلبك في صفحة التمويل'
                      : 'You can track your application status in the Loans page',
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                  
                  // Navigate to appropriate loans page based on language
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => isArabic 
                        ? const LoansPageAr()
                        : const LoansPage(),
                    ),
                  );
                },
                child: Text(
                  isArabic ? 'حسناً' : 'OK',
                  style: TextStyle(
                    color: Color(Constants.primaryColorValue),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Get the current theme mode
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Validate finance amounts before building UI
    final bool canShowFinanceDetails = _maxFinanceAmount >= 10000;
    
    // Set safe initial values for sliders
    final safeFinanceAmount = financeAmount.clamp(10000.0, max(_maxFinanceAmount, 10000.0)).toDouble();
    final safeTenure = tenure.clamp(12, 60).toDouble();

    // --- FIX: Conditionally set divisions for the finance amount slider ---
    final double financeRange = max(_maxFinanceAmount, 10000.0) - 10000.0;
    final int computedDivisions = (financeRange / 1000.0).round();
    final int? safeFinanceDivisions = computedDivisions > 0 ? computedDivisions : null;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(Constants.darkBackgroundColor) : Colors.white,
      body: WillPopScope(  // 💡 Add WillPopScope to prevent back navigation
        onWillPop: () async => false,  // 💡 Prevent back key
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor).withOpacity(0.1),
                    Color(isDarkMode ? Constants.darkBackgroundColor : Constants.lightBackgroundColor),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // 💡 Title Row (removed back button)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: Center(  // 💡 Center the title
                      child: Text(
                        isArabic ? 'عرض التمويل' : 'Loan Offer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  if (_error != null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Color(isDarkMode ? Constants.darkErrorColor : Constants.lightErrorColor),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_shouldContactSupport)
                                Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CustomerServiceScreen(
                                              isArabic: widget.isArabic,
                                              source: 'loan_application',
                                              applicationNumber: widget.userData['application_number']?.toString(),
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                        shadowColor: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor).withOpacity(0.3),
                                      ),
                                      child: Text(
                                        widget.isArabic ? 'تواصل مع خدمة العملاء' : 'Contact Customer Service',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                  shadowColor: Colors.grey.withOpacity(0.3),
                                ),
                                child: Text(
                                  widget.isArabic ? 'رجوع' : 'Go Back',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (!canShowFinanceDetails && !_isLoading)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isArabic 
                                  ? 'عذراً، لا يمكن تقديم عرض تمويل في الوقت الحالي'
                                  : 'Sorry, we cannot provide a finance offer at this time',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                                ),
                                child: Text(isArabic ? 'رجوع' : 'Go Back'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (canShowFinanceDetails || _isLoading)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Opacity(
                          opacity: _isLoading ? 0.6 : 1.0,
                          child: IgnorePointer(
                            ignoring: _isLoading,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                              child: Column(
                                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  // Finance Details Card
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(isDarkMode ? Constants.darkSurfaceColor : Constants.lightSurfaceColor),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(isDarkMode ? Constants.darkPrimaryShadowColor : Constants.lightPrimaryShadowColor),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic ? 'تفاصيل التمويل' : 'Finance Details',
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Finance Amount Section
                                        Text(
                                          isArabic ? 'مبلغ التمويل' : 'Finance Amount',
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                isArabic ? 'ريال ' : 'SAR ',
                                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00A650),
                                                ),
                                              ),
                                              Text(
                                                ' ' + financeAmount.toStringAsFixed(2),
                                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00A650),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              activeTrackColor: Color(0xFF008040),
                                              inactiveTrackColor: Color(0xFF008040).withOpacity(0.1),
                                              thumbColor: Color(0xFF008040),
                                              overlayColor: Color(0xFF008040).withOpacity(0.2),
                                            ),
                                            child: Slider(
                                              value: safeFinanceAmount,
                                              min: 10000.0,
                                              max: max(_maxFinanceAmount, 10000.0).toDouble(),
                                              onChanged: _updateFinanceAmount,
                                              // Use the safeFinanceDivisions here
                                              divisions: safeFinanceDivisions,
                                              label: isArabic 
                                                ? '${safeFinanceAmount.toStringAsFixed(0)} ريال'
                                                : 'SAR ${safeFinanceAmount.toStringAsFixed(0)}',
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // EMI Section
                                        Text(
                                          isArabic ? 'القسط الشهري' : 'Monthly Installment (EMI)',
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                isArabic ? 'ريال ' : 'SAR ',
                                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(Constants.primaryColorValue),
                                                ),
                                              ),
                                              Text(
                                                ' ' + emi.toStringAsFixed(2),
                                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(Constants.primaryColorValue),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Tenure Section
                                        Text(
                                          isArabic ? 'مدة التمويل' : 'Tenure (Months)',
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                isArabic ? ' شهر' : ' $tenure',
                                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(Constants.primaryColorValue),
                                                ),
                                              ),
                                              Text(
                                                isArabic ? ' $tenure' : ' Months',
                                                textAlign: isArabic ? TextAlign.left : TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(Constants.primaryColorValue),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              activeTrackColor: Color(0xFF008040),
                                              inactiveTrackColor: Color(0xFF008040).withOpacity(0.1),
                                              thumbColor: Color(0xFF008040),
                                              overlayColor: Color(0xFF008040).withOpacity(0.2),
                                            ),
                                            child: Slider(
                                              value: safeTenure,
                                              min: 12.0,
                                              max: 60.0,
                                              onChanged: (value) => _updateTenure(value.round()),
                                              divisions: 48, // Fixed non-zero divisions
                                              label: isArabic
                                                ? '${safeTenure.round()} شهر'
                                                : '${safeTenure.round()} months',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Total Repayment Section
                                        Text(
                                          isArabic ? 'إجمالي المبلغ المستحق' : 'Total Repayment Amount',
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    isArabic ? 'ريال ' : 'SAR ',
                                                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(Constants.primaryColorValue),
                                                    ),
                                                  ),
                                                  Text(
                                                    ' ' + _totalRepayment.toStringAsFixed(2),
                                                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(Constants.primaryColorValue),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isArabic 
                                                  ? '(يشمل الفائدة: ${_interest.toStringAsFixed(2)} ريال)'
                                                  : '(Including Interest: SAR ${_interest.toStringAsFixed(2)})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: !_isLoading ? _showDeclineConfirmation : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                              shadowColor: Colors.red.withOpacity(0.3),
                                            ),
                                            child: Text(
                                              isArabic ? 'رفض' : 'Decline',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: _showCongratulationsDialog,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF00A650),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                              shadowColor: const Color(0xFF00A650).withOpacity(0.3),
                                            ),
                                            child: Text(
                                              isArabic ? 'موافق' : 'Approve',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
