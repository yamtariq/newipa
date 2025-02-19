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
import '../../screens/customer_service_screen.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:convert';

class CardOfferScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isArabic;
  final int maxCreditLimit;
  final int minCreditLimit;

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
  bool _isLoading = false;
  String? _error;
  bool _hasApiResponse = false;
  int _creditLimit = 0;
  String? _applicationNumber;
  String? _cardType;
  String? _cardTypeAr;
  bool _shouldContactSupport = false;

  @override
  void initState() {
    super.initState();
    
    print('\n=== CARD OFFER SCREEN INITIALIZATION - START ===');
    print('User Data: ${const JsonEncoder.withIndent('  ').convert(widget.userData)}');
    
    // 💡 First check for errors in the response
    if (widget.userData['success'] == false) {
      print('\nResponse indicates failure. Checking error details...');
      _shouldContactSupport = true; // All error cases need customer care link
      
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
          
          _error = widget.isArabic 
            ? 'لديك طلب نشط بالفعل في النظام برقم $applicationId. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
            : 'You already have an active application in pipeline (Application #$applicationId). Please contact customer care for more details.';
          print('=== CARD OFFER SCREEN INITIALIZATION - END (ACTIVE APPLICATION) ===\n');
          return;
        }
        
        // Case 2: Not eligible
        if (error['errorDesc']?.toString().toLowerCase().contains('not eligible') == true) {
          print('Detected not eligible case from error description');
          _error = widget.isArabic 
            ? 'عذراً، لم تتم الموافقة على طلبك في هذا الوقت. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
            : 'Unfortunately your application is not approved at this time. Please contact customer care for more details.';
          print('=== CARD OFFER SCREEN INITIALIZATION - END (NOT ELIGIBLE) ===\n');
          return;
        }
        
        // Case 3: Other errors
        print('Unhandled error case. Using generic error message');
        _error = widget.isArabic 
          ? 'حدث خطأ غير متوقع. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
          : 'An unexpected error occurred. Please contact customer care for more details.';
        print('=== CARD OFFER SCREEN INITIALIZATION - END (GENERIC ERROR) ===\n');
        return;
      }
      
      // If no specific error details, show generic error
      print('No specific error details found. Using generic error message');
      _error = widget.isArabic 
        ? 'حدث خطأ غير متوقع. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
        : 'An unexpected error occurred. Please contact customer care for more details.';
      print('=== CARD OFFER SCREEN INITIALIZATION - END (NO ERROR DETAILS) ===\n');
      return;
    }
    
    // Case 4: Approved with eligibleAmount - proceed with offer screen
    if (widget.userData['result']?['eligibleAmount'] != null) {
      print('\nProcessing approved case with eligible amount');
      _creditLimit = int.tryParse(widget.userData['result']['eligibleAmount'].toString()) ?? widget.maxCreditLimit;
      print('Initial credit limit: $_creditLimit');
      
      // 💡 Ensure credit limit is within bounds
      if (_creditLimit < 2000) _creditLimit = 2000;
      print('Adjusted credit limit: $_creditLimit');
      
      _cardType = widget.userData['card_type'];
      _cardTypeAr = widget.userData['card_type_ar'];
      _applicationNumber = widget.userData['result']['applicationId'];
      
      print('Card Type: $_cardType');
      print('Card Type (Arabic): $_cardTypeAr');
      print('Application Number: $_applicationNumber');
      print('=== CARD OFFER SCREEN INITIALIZATION - END (APPROVED) ===\n');
      return;
    }
    
    // If we reach here, something unexpected happened
    print('\nUnexpected case: No eligible amount found');
    _shouldContactSupport = true;
    _error = widget.isArabic 
      ? 'حدث خطأ غير متوقع. يرجى التواصل مع خدمة العملاء لمزيد من التفاصيل.'
      : 'An unexpected error occurred. Please contact customer care for more details.';
    print('=== CARD OFFER SCREEN INITIALIZATION - END (UNEXPECTED CASE) ===\n');
  }

  // 💡 Update credit limit method to respect new minimum
  void _updateCreditLimit(double value) {
    setState(() {
      _creditLimit = value.round();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showActiveCardDialog(dynamic applicationNo, String status, String message, String messageAr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(widget.isArabic ? 'طلب بطاقة نشط' : 'Active Card Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.isArabic ? messageAr : message),
            const SizedBox(height: 16),
            Text(widget.isArabic ? 'رقم الطلب: $applicationNo' : 'Application #: $applicationNo'),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => widget.isArabic ? const CardsPageAr() : const CardsPage(),
                ),
              );
            },
            child: Text(widget.isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _showCongratulationsDialog() async {
    try {
      setState(() => _isLoading = true);

      final cardService = CardService();
      
      // 💡 Log the card acceptance flow start
      print('\n=== CARD OFFER ACCEPTANCE FLOW - START ===');
      
      // 💡 Call updateCustomer endpoint and insert application
      final cardData = {
        'national_id': widget.userData['national_id'],
        'application_number': _applicationNumber,
        'customerDecision': 'ACCEPTED',
        'card_type': _cardType,
        'card_limit': _creditLimit,
        'nameOnCard': widget.userData['nameOnCard'] ?? '',
        'noteUser': widget.userData['username'] ?? 'Customer',
        'note': 'Customer accepted the card offer through mobile app with limit $_creditLimit SAR',
      };

      final response = await cardService.updateCustomerCardRequest(cardData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        print('\nERROR: Card acceptance request failed');
        print('Error Details: ${response['message']}');
        print('=== CARD OFFER ACCEPTANCE FLOW - END (WITH ERROR) ===\n');
        throw Exception(response['message'] ?? 'Failed to process card acceptance');
      }

      print('\n=== CARD OFFER ACCEPTANCE FLOW - END (SUCCESS) ===\n');

      // Show congratulations dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/celebration.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic ? 'مبروك!' : 'Congratulations!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic 
                  ? 'تم تقديم طلب البطاقة بنجاح!'
                  : 'Your card application has been submitted successfully!',
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic 
                  ? 'رقم الطلب: $_applicationNumber'
                  : 'Application #: $_applicationNumber',
              ),
              const SizedBox(height: 16),
              Text(
                widget.isArabic 
                  ? 'حد البطاقة: ${_creditLimit.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ريال'
                  : 'Card Limit: SAR ${_creditLimit.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => widget.isArabic ? const CardsPageAr() : const CardsPage(),
                  ),
                  (route) => false,
                );
              },
              child: Text(widget.isArabic ? 'تم' : 'Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(widget.isArabic 
        ? 'حدث خطأ أثناء معالجة طلبك'
        : 'Error processing your request: $e');
    }
  }

  void _showDeclineConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isArabic ? 'تأكيد الرفض' : 'Confirm Decline'),
        content: Text(
          widget.isArabic 
            ? 'هل أنت متأكد من رفض عرض البطاقة؟'
            : 'Are you sure you want to decline the card offer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processDecline();
            },
            child: Text(
              widget.isArabic ? 'تأكيد الرفض' : 'Confirm Decline',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processDecline() async {
    try {
      setState(() => _isLoading = true);

      final cardService = CardService();
      
      // 💡 Call updateCustomer endpoint and insert application
      final cardData = {
        'national_id': widget.userData['national_id'],
        'application_number': _applicationNumber,
        'customerDecision': 'DECLINED',
        'card_type': _cardType,
        'card_limit': 0,
        'nameOnCard': widget.userData['nameOnCard'] ?? '',
        'noteUser': widget.userData['username'] ?? 'Customer',
        'note': 'Customer declined the card offer through mobile app',
      };

      final response = await cardService.updateCustomerCardRequest(cardData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        print('\nERROR: Card decline request failed');
        print('Error Details: ${response['message']}');
        throw Exception(response['message'] ?? 'Failed to process card decline');
      }

      // Show success message and navigate back
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.isArabic ? 'تم الرفض' : 'Declined Successfully'),
          content: Text(
            widget.isArabic 
              ? 'تم رفض عرض البطاقة بنجاح'
              : 'The card offer has been declined successfully',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => widget.isArabic ? const CardsPageAr() : const CardsPage(),
                  ),
                  (route) => false,
                );
              },
              child: Text(widget.isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(widget.isArabic 
        ? 'حدث خطأ أثناء معالجة طلبك'
        : 'Error processing your request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Color(Constants.darkBackgroundColor) : Color(Constants.lightBackgroundColor),
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
                        widget.isArabic ? 'عرض البطاقة' : 'Card Offer',
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
                                              source: 'card_application',
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
                                  ],
                                ),
                              const SizedBox(height: 16),
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
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Opacity(
                          opacity: _isLoading ? 0.6 : 1.0,
                          child: IgnorePointer(
                            ignoring: _isLoading,
                            child: Column(
                              crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // Card Offer Details
                                Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  color: Color(isDarkMode ? Constants.darkSurfaceColor : Constants.lightSurfaceColor),
                                  elevation: 4,
                                  shadowColor: Color(isDarkMode ? Constants.darkPrimaryShadowColor : Constants.lightPrimaryShadowColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        // Card Type
                                        Text(
                                          widget.isArabic ? 'نوع البطاقة' : 'Card Type',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.isArabic 
                                            ? (_cardTypeAr ?? 'بطاقة المكافآت')
                                            : (_cardType ?? 'Rewards Card'),
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Card Limit
                                        Text(
                                          widget.isArabic ? 'الحد الائتماني للبطاقة' : 'Card Limit',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(Constants.primaryColorValue).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: widget.isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                widget.isArabic ? 'ريال ' : 'SAR ',
                                                textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00A650),
                                                ),
                                              ),
                                              Text(
                                                _creditLimit.toString().replaceAllMapped(
                                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                                  (Match m) => '${m[1]},'
                                                ),
                                                textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00A650),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // 💡 Add Credit Limit Slider
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              activeTrackColor: const Color(0xFF00A650),
                                              inactiveTrackColor: const Color(0xFF00A650).withOpacity(0.1),
                                              thumbColor: const Color(0xFF00A650),
                                              overlayColor: const Color(0xFF00A650).withOpacity(0.2),
                                              trackHeight: 4.0,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                                            ),
                                            child: Column(
                                              children: [
                                                Slider(
                                                  value: _creditLimit.toDouble(),
                                                  min: 2000,
                                                  max: widget.userData['result']?['eligibleAmount'] != null 
                                                    ? double.tryParse(widget.userData['result']['eligibleAmount'].toString()) ?? 50000 
                                                    : 50000,
                                                  onChanged: _updateCreditLimit,
                                                  divisions: 48, // (50000 - 2000) / 1000
                                                ),
                                                // 💡 Add min/max labels
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        widget.isArabic ? '2,000 ريال' : 'SAR 2,000',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        widget.isArabic 
                                                          ? '${widget.userData['result']?['eligibleAmount'] ?? "50,000"} ريال' 
                                                          : 'SAR ${widget.userData['result']?['eligibleAmount'] ?? "50,000"}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        onPressed: _isLoading ? null : _showDeclineConfirmation,
                                        text: widget.isArabic ? 'رفض' : 'Decline',
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomButton(
                                        onPressed: _isLoading ? null : _showCongratulationsDialog,
                                        text: widget.isArabic ? 'موافق' : 'Accept',
                                        backgroundColor: Colors.green,
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
                ],
              ),
            ),
            // Loading Overlay
            if (_isLoading)
              Container(
                color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(isDarkMode ? Constants.darkSurfaceColor : Constants.lightSurfaceColor),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Color(isDarkMode ? Constants.darkPrimaryShadowColor : Constants.lightPrimaryShadowColor),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isArabic ? 'جاري المعالجة...' : 'Processing...',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
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