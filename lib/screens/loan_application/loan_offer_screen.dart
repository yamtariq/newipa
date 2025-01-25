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
import 'package:provider/provider.dart';

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
    _fetchLoanDecision();
  }

  Future<void> _fetchLoanDecision() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final loanService = LoanService();
      final userData = widget.userData;

      print('DEBUG - User Data received: $userData');

      // Add null checks and default values
      final salary = double.tryParse(userData['salary']?.toString() ?? '0') ?? 0;
      final foodExpense = double.tryParse(userData['food_expense']?.toString() ?? '0') ?? 0;
      final transportExpense = double.tryParse(userData['transportation_expense']?.toString() ?? '0') ?? 0;
      
      // Calculate total liabilities (existing EMIs + other liabilities)
      final existingEMIs = double.tryParse(userData['existing_emis']?.toString() ?? '0') ?? 0;
      final otherLiabilities = double.tryParse(userData['other_liabilities']?.toString() ?? '0') ?? 0;
      final totalLiabilities = existingEMIs + otherLiabilities;

      print('DEBUG - Values being sent to API:');
      print('Salary: $salary');
      print('Total Liabilities: $totalLiabilities');
      print('Food Expense: $foodExpense');
      print('Transport Expense: $transportExpense');
      print('Total Expenses: ${foodExpense + transportExpense}');
      print('Requested Tenure: 60');

      // Only proceed if salary is greater than 0
      if (salary <= 0) {
        throw Exception('Invalid salary amount');
      }

      final response = await loanService.getLoanDecision(
        salary: salary,
        liabilities: totalLiabilities,
        expenses: foodExpense + transportExpense,
        requestedTenure: 60, // Start with maximum tenure
      );

      print('DEBUG - Loan Decision Response:');
      print('Status: ${response['status']}');
      print('Decision: ${response['decision']}');
      print('Finance Amount: ${response['finance_amount']}');
      print('EMI: ${response['emi']}');
      print('Total Repayment: ${response['total_repayment']}');
      print('Interest: ${response['interest']}');

      if (response['status'] == 'success' && response['decision'] == 'approved') {
        // Validate finance amount and EMI
        final financeAmount = double.tryParse(response['finance_amount']?.toString() ?? '0') ?? 0;
        final monthlyEMI = double.tryParse(response['emi']?.toString() ?? '0') ?? 0;
        final totalRepayment = double.tryParse(response['total_repayment']?.toString() ?? '0') ?? 0;
        final interest = double.tryParse(response['interest']?.toString() ?? '0') ?? 0;
        
        // Get flat rate from API response or use default
        _flatRate = double.tryParse(response['flat_rate']?.toString() ?? '0.05') ?? 0.05;
        print('DEBUG - Flat Rate from API: $_flatRate');

        // Store application number from API response
        widget.userData['application_number'] = response['application_number'];
        print('DEBUG - Application Number from API: ${widget.userData['application_number']}');

        print('DEBUG - Validating response values:');
        print('Finance Amount: $financeAmount (Min required: 10000)');
        print('Monthly EMI: $monthlyEMI');
        print('Total Repayment: $totalRepayment');
        print('Interest: $interest');

        // Check if finance amount meets minimum requirement
        if (financeAmount < 10000) {
          print('DEBUG - Finance amount too low: $financeAmount');
          setState(() {
            _error = isArabic 
              ? 'عذراً، المبلغ المتاح للتمويل أقل من الحد الأدنى المطلوب (10,000 ريال)'
              : 'Sorry, the available finance amount is below the minimum requirement (10,000 SAR)';
            _isLoading = false;
          });
          return;
        }

        // Check if EMI is reasonable (not zero or negative)
        if (monthlyEMI <= 0) {
          print('DEBUG - Invalid EMI amount: $monthlyEMI');
          setState(() {
            _error = isArabic 
              ? 'عذراً، حدث خطأ في حساب القسط الشهري'
              : 'Sorry, there was an error calculating the monthly installment';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          // Store original values from API
          _originalFinanceAmount = financeAmount;
          _originalEMI = monthlyEMI;
          _originalTotalRepayment = totalRepayment;
          _originalInterest = interest;
          _originalTenure = int.tryParse(response['tenure_months']?.toString() ?? '60') ?? 60;

          // Set current values
          _maxFinanceAmount = financeAmount;
          print('DEBUG - Setting max finance amount: $_maxFinanceAmount');
          this.financeAmount = _maxFinanceAmount;
          _maxEMI = monthlyEMI;
          emi = _maxEMI;
          tenure = _originalTenure;
          _totalRepayment = totalRepayment;
          _interest = interest;
          _isLoading = false;
        });
      } else {
        print('DEBUG - Loan not approved:');
        print('Status: ${response['status']}');
        print('Code: ${response['code']}');
        print('Message: ${response['message']}');
        
        if (response['code'] == 'ACTIVE_APPLICATION_EXISTS') {
          _showActiveLoanDialog(
            response['application_no'], 
            response['current_status'],
            response['message'],
            response['message_ar']
          );
          return;
        }
        setState(() {
          _error = isArabic 
            ? 'عذراً، لم نتمكن من الموافقة على طلب التمويل الخاص بك في هذا الوقت'
            : 'Sorry, we could not approve your finance application at this time';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching loan decision: $e');
      setState(() {
        _error = isArabic 
          ? 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى'
          : 'An error occurred while processing your request. Please try again';
        _isLoading = false;
      });
    }
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
        return;
      }
      
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
        // Solve for new principal: P = EMI * months / (1 + R * T)
        financeAmount = (emi * tenure) / (1 + (_flatRate * tenureYears));
        // Round down to nearest thousand
        financeAmount = (financeAmount ~/ 1000) * 1000.0;
        // Recalculate final values with rounded principal
        _interest = financeAmount * _flatRate * tenureYears;
        _totalRepayment = financeAmount + _interest;
        emi = _totalRepayment / tenure;
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

      // Update loan application in database first
      final loanService = LoanService();
      
      // Round all numeric values to 2 decimal places and keep UI display values
      final loanData = {
        'national_id': widget.userData['national_id'],
        'application_no': widget.userData['application_number'],
        'customerDecision': 'ACCEPTED',
        'loan_amount': financeAmount.toStringAsFixed(2),
        'loan_tenure': tenure,
        'interest_rate': (_flatRate * 100).toStringAsFixed(2),
        'loan_purpose': widget.userData['loan_purpose'],
        'status': 'pending',
        'remarks': 'Loan offer accepted by customer',
        'noteUser': 'CUSTOMER',
        'note': 'Customer accepted the loan offer with amount ${financeAmount.toStringAsFixed(2)} SAR for $tenure months',
        // Keep these for UI display
        'emi': emi.toStringAsFixed(2),
        'total_repayment': _totalRepayment.toStringAsFixed(2),
        'interest': _interest.toStringAsFixed(2),
      };

      print('DEBUG - Sending loan data to API:');
      print('Loan Purpose: ${widget.userData['loan_purpose']}');  // Debug print
      print(loanData);

      final response = await loanService.updateLoanApplication(loanData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update loan application');
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
        'national_id': widget.userData['national_id'],
        'application_no': widget.userData['application_number'],
        'customerDecision': 'DECLINED',
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
        'noteUser': 'CUSTOMER',
        'note': 'Customer declined the loan offer',
        // Keep these for consistency
        'emi': '0.00',
        'total_repayment': '0.00',
        'interest': '0.00',
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
                              color: Color(Constants.primaryColorValue),
                            ),
                          ),
                        ],
                      ),
                      // Title
                      Text(
                        isArabic ? 'عرض التمويل' : 'Loan Offer',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(Constants.primaryColorValue),
                        ),
                      ),
                    ],
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
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(isArabic ? 'رجوع' : 'Go Back'),
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
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(isArabic ? 'رجوع' : 'Go Back'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(Constants.primaryColorValue),
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
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'جاري المعالجة...' : 'Processing...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
