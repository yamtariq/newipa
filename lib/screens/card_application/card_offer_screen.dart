import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/card_service.dart';
import '../../screens/main_page.dart';
import '../../screens/cards_page.dart';
import '../../screens/cards_page_ar.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class CardOfferScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isArabic;
  final double maxCreditLimit;
  final double minCreditLimit;

  const CardOfferScreen({
    Key? key,
    required this.userData,
    required this.isArabic,
    required this.maxCreditLimit,
    required this.minCreditLimit,
  }) : super(key: key);

  @override
  State<CardOfferScreen> createState() => _CardOfferScreenState();
}

class _CardOfferScreenState extends State<CardOfferScreen> {
  double creditLimit = 0;
  double _maxCreditLimit = 0;  // Store API max limit
  double _minCreditLimit = 0;  // Store API min limit
  bool _isLoading = true;
  bool _hasApiResponse = false;
  String? _error;
  String? _applicationNumber;
  String? _cardType;
  bool get isArabic => widget.isArabic;

  // Card type localization map
  final Map<String, String> _cardTypeArabicNames = {
    'GOLD': 'الذهبية',
    'REWARD': 'المكافآت',
  };

  // Get localized card type name
  String get localizedCardType {
    if (_cardType == null) return '';
    return isArabic ? _cardTypeArabicNames[_cardType] ?? _cardType! : _cardType!;
  }

  @override
  void initState() {
    super.initState();
    _fetchCardDecision();
  }

  Future<void> _fetchCardDecision() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _hasApiResponse = false;
      });

      final cardService = CardService();
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
      print('Phone: ${userData['phone']}');

      final response = await cardService.getCardDecision(
        salary: salary,
        liabilities: totalLiabilities,
        expenses: foodExpense + transportExpense,
        nationalId: userData['national_id'],
        phone: userData['phone'] ?? '',
      );

      print('DEBUG - Card Decision Response:');
      print('Status: ${response['status']}');
      print('Code: ${response['code']}');
      print('Decision: ${response['decision']}');

      if (response['code'] == 'ACTIVE_APPLICATION_EXISTS') {
        _showActiveCardDialog(
          response['application_no'], 
          response['current_status'],
          response['message'],
          response['message_ar']
        );
        return;
      }

      if (response['status'] == 'success' && response['decision'] == 'approved') {
        final approvedLimit = double.tryParse(response['credit_limit']?.toString() ?? '0') ?? 0;
        final minLimit = double.tryParse(response['min_credit_limit']?.toString() ?? '0') ?? 0;
        
        // Store application number and card type from API response
        _applicationNumber = response['application_number'];
        _cardType = response['card_type'];
        print('DEBUG - Application Number from API: $_applicationNumber');
        print('DEBUG - Card Type from API: $_cardType');

        if (approvedLimit < 3000) {
          setState(() {
            _error = isArabic 
              ? 'عذراً، الحد الائتماني المتاح أقل من الحد الأدنى المطلوب (2,000 ريال)'
              : 'Sorry, the available credit limit is below the minimum requirement (2,000 SAR)';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          creditLimit = approvedLimit;
          _minCreditLimit = minLimit;
          _maxCreditLimit = approvedLimit;  // Set max to approved limit
          _hasApiResponse = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = isArabic 
            ? 'عذراً، لم نتمكن من الموافقة على طلب البطاقة الخاص بك في هذا الوقت'
            : 'Sorry, we could not approve your card application at this time';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = isArabic 
          ? 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى'
          : 'An error occurred while processing your request. Please try again';
        _isLoading = false;
      });
      print('Error fetching card decision: $e');
    }
  }

  void _showActiveCardDialog(dynamic applicationNo, String status, String message, String messageAr) async {
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
              isArabic ? 'طلب بطاقة نشط' : 'Active Card Application',
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
                      ? 'يمكنك متابعة حالة طلبك في صفحة البطاقات'
                      : 'You can track your application status in the Cards page',
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
                  
                  // Navigate to appropriate cards page based on language
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => isArabic 
                        ? const CardsPageAr()
                        : const CardsPage(),
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

  // Round to nearest 100
  double _roundToNearest100(double value) {
    return (value / 100).round() * 100;
  }

  void _showCongratulationsDialog() async {
    try {
      setState(() => _isLoading = true);

      // Update card application in database first
      final cardService = CardService();
      
      final cardData = {
        'national_id': widget.userData['national_id'],
        'card_limit': creditLimit.toStringAsFixed(2),
        'status': 'approved',
        'application_number': _applicationNumber,
        'customerDecision': 'ACCEPTED',
        'remarks': 'Card offer accepted by customer',
        'noteUser': widget.userData['username'] ?? 'Customer',
        'note': 'Customer accepted the card offer through mobile app',
        'card_type': _cardType,
      };

      print('DEBUG - Sending card data to API:');
      print(cardData);

      // Add debug log for application number
      print('DEBUG - Application Number Type: ${_applicationNumber.runtimeType}');
      print('DEBUG - Application Number Value: $_applicationNumber');

      final response = await cardService.updateCardApplication(cardData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update card application');
      }

      // Show congratulations dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
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
                        ? 'تم تقديم طلب البطاقة الخاص بك بنجاح!'
                        : 'Your card application has been submitted successfully!',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'رقم الطلب: $_applicationNumber'
                        : 'Application #: $_applicationNumber',
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
                        ? 'نوع البطاقة: $localizedCardType'
                        : 'Card Type: $localizedCardType',
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
                        ? 'الحد الائتماني: ${creditLimit.toStringAsFixed(2)} ريال'
                        : 'Credit Limit: SAR ${creditLimit.toStringAsFixed(2)}',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: Text(
                      isArabic 
                        ? 'يمكنك متابعة حالة طلبك في صفحة البطاقات'
                        : 'You can track your application status in the Cards page',
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
      print('Error processing card approval: $e');
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
              ? 'هل أنت متأكد من رفض عرض البطاقة؟'
              : 'Are you sure you want to decline the card offer?',
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

      // Update card application in database
      final cardService = CardService();
      
      final cardData = {
        'national_id': widget.userData['national_id'],
        'card_limit': '0',
        'status': 'declined',
        'application_number': _applicationNumber,
        'customerDecision': 'DECLINED',
        'remarks': 'Card offer declined by customer',
        'noteUser': widget.userData['username'] ?? 'Customer',
        'note': 'Customer declined the card offer through mobile app',
        'card_type': _cardType,
      };

      print('DEBUG - Sending decline data to API:');
      print(cardData);

      // Add debug log for application number
      print('DEBUG - Application Number Type: ${_applicationNumber.runtimeType}');
      print('DEBUG - Application Number Value: $_applicationNumber');

      final response = await cardService.updateCardApplication(cardData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update card application');
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
                ? 'تم رفض عرض البطاقة بنجاح'
                : 'The card offer has been declined successfully',
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
      print('Error processing card decline: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Round limits to nearest 100
    double maxLimit = _roundToNearest100(widget.maxCreditLimit);
    double minLimit = _roundToNearest100(widget.minCreditLimit);
    creditLimit = _roundToNearest100(creditLimit);

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
                        isArabic ? 'عرض البطاقة' : 'Card Offer',
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                      child: Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // Card Details Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'تفاصيل البطاقة' : 'Card Details',
                                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(Constants.primaryColorValue),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Credit Limit Section
                                if (_hasApiResponse) ...[
                                  Text(
                                    isArabic ? 'الحد الائتماني' : 'Credit Limit',
                                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          isArabic ? 'ريال ' : 'SAR ',
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(Constants.primaryColorValue),
                                          ),
                                        ),
                                        Text(
                                          creditLimit.toStringAsFixed(2),
                                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(Constants.primaryColorValue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor: Color(Constants.primaryColorValue),
                                        inactiveTrackColor: Color(Constants.primaryColorValue).withOpacity(0.1),
                                        thumbColor: Color(Constants.primaryColorValue),
                                        overlayColor: Color(Constants.primaryColorValue).withOpacity(0.2),
                                      ),
                                      child: Slider(
                                        value: creditLimit,
                                        min: _minCreditLimit,
                                        max: _maxCreditLimit,  // This will now be the approved limit
                                        divisions: ((_maxCreditLimit - _minCreditLimit) / 100).round(),
                                        label: isArabic ? 'ريال ${creditLimit.round()}' : 'SAR ${creditLimit.round()}',
                                        onChanged: (value) {
                                          setState(() {
                                            creditLimit = _roundToNearest100(value);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 16),
                                
                                // Card Type
                                if (_cardType != null) Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: <Widget>[
                                      if (!isArabic) Text(
                                        'Card Type: ',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Color(Constants.primaryColorValue),
                                        ),
                                      ),
                                      Text(
                                        localizedCardType,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(Constants.primaryColorValue),
                                        ),
                                      ),
                                      if (isArabic) Text(
                                        ' :نوع البطاقة',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Color(Constants.primaryColorValue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Accept/Decline Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: !_isLoading ? _showDeclineConfirmation : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            elevation: 5,
                                            shadowColor: Colors.red.withOpacity(0.5),
                                          ),
                                          child: Text(
                                            isArabic ? 'رفض' : 'Decline',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: !_isLoading ? _showCongratulationsDialog : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00A650),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            elevation: 5,
                                            shadowColor: const Color(0xFF00A650).withOpacity(0.5),
                                          ),
                                          child: Text(
                                            isArabic ? 'موافق' : 'Approve',
                                            style: const TextStyle(
                                              fontSize: 18,
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
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loading Overlay
          if (_isLoading) Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(Constants.primaryColorValue)),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 