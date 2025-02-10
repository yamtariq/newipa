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
  bool _isLoading = false;
  String? _error;
  bool _hasApiResponse = false;
  double _creditLimit = 0;
  String? _applicationNumber;
  String? _cardType;

  @override
  void initState() {
    super.initState();
    _creditLimit = widget.maxCreditLimit;
    _cardType = 'REWARD'; // Default card type
    _applicationNumber = widget.userData['application_number']; // Store application number from the response
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
      
      final cardData = {
        'national_id': widget.userData['national_id'],
        'card_limit': _creditLimit.toStringAsFixed(2),
        'status': 'approved',
        'application_number': _applicationNumber,
        'customerDecision': 'ACCEPTED',
        'remarks': 'Card offer accepted by customer',
        'noteUser': widget.userData['username'] ?? 'Customer',
        'note': 'Customer accepted the card offer through mobile app',
        'card_type': _cardType,
      };

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
                  ? 'حد البطاقة: ${_creditLimit.toStringAsFixed(2)} ريال'
                  : 'Card Limit: SAR ${_creditLimit.toStringAsFixed(2)}',
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

      final response = await cardService.updateCardApplication(cardData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update card application');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? 'عرض البطاقة' : 'Card Offer'),
        leading: IconButton(
          icon: Icon(widget.isArabic ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Offer Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isArabic ? 'حد البطاقة' : 'Card Limit',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.isArabic ? 'ريال ' : 'SAR '}${_creditLimit.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.green,
                          ),
                        ),
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
} 