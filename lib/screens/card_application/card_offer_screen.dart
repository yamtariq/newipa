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
    
    // 💡 First check for errors in the response
    if (widget.userData['success'] == false) {
      _error = widget.isArabic 
        ? 'عذراً، لا يمكن المتابعة'
        : 'Sorry, cannot proceed';
      
      // Check if there are any errors in the response
      if (widget.userData['errors'] != null && widget.userData['errors'] is List && widget.userData['errors'].isNotEmpty) {
        final error = widget.userData['errors'][0];
        if (error['errorCode'] == '2-201') {
          // This is a case where card request is already in process
          _error = widget.isArabic 
            ? 'طلب البطاقة قيد المعالجة بالفعل. يرجى التواصل مع خدمة العملاء لمزيد من المعلومات.'
            : 'Card request is already in process. Please contact customer support for more information.';
          _shouldContactSupport = true;
        } else {
          // Handle other error cases
          _error = widget.isArabic 
            ? (error['errorDesc'] ?? 'حدث خطأ غير متوقع')
            : (error['errorDesc'] ?? 'An unexpected error occurred');
        }
      }
      return;
    }
    
    // 💡 If no errors, proceed with normal initialization
    _creditLimit = widget.userData['eligibleAmount'] != null 
      ? int.tryParse(widget.userData['eligibleAmount'].toString()) ?? widget.maxCreditLimit
      : widget.maxCreditLimit;
    
    // 💡 Ensure credit limit is within bounds
    if (_creditLimit < 2000) _creditLimit = 2000;
    if (_creditLimit > 50000) _creditLimit = 50000;
    
    _cardType = widget.userData['card_type']; // Get card type from userData
    _cardTypeAr = widget.userData['card_type_ar']; // Get Arabic card type from userData
    _applicationNumber = widget.userData['application_number'];
  }

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
            Text(widget.isArabic ? 'الحالة: $status' : 'Status: $status'),
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
                  ? 'حد الائتمان المقدم: ${_creditLimit.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ريال'
                  : 'Offered Credit Limit: SAR ${_creditLimit.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
      body: Stack(
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
                // Back Button and Title Row
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: widget.isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            icon: Icon(
                              widget.isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                              color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
                            ),
                          ),
                        ],
                      ),
                      // Title
                      Text(
                        widget.isArabic ? 'عرض البطاقة' : 'Card Offer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(isDarkMode ? Constants.darkPrimaryColor : Constants.lightPrimaryColor),
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
                                  Text(
                                    widget.isArabic 
                                      ? 'يرجى التواصل مع خدمة العملاء للمزيد من المعلومات'
                                      : 'Please contact customer service for more information',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
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
                                    ),
                                    child: Text(
                                      widget.isArabic ? 'تواصل مع خدمة العملاء' : 'Contact Customer Service',
                                      style: const TextStyle(fontSize: 16),
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
                              ),
                              child: Text(widget.isArabic ? 'رجوع' : 'Go Back'),
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
                                        widget.isArabic ? 'حد الائتمان المقدم' : 'Offered Credit Limit',
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
                                                max: 50000,
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
                                                      widget.isArabic ? '50,000 ريال' : 'SAR 50,000',
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
    );
  }
} 