import 'package:flutter/material.dart';

class CardOfferScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _CardOfferScreenState createState() => _CardOfferScreenState();
}

class _CardOfferScreenState extends State<CardOfferScreen> {
  // ... (existing code)

  Future<void> _handleNextButtonClick() async {
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
      print('Total Expenses: ${foodExpense + transportExpense}');
      print('Phone: ${userData['phone']}');

      final response = await cardService.createCustomerCardRequest(userData, isArabic);

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

      // ... (rest of the existing code)
    } catch (e) {
      // ... (rest of the existing code)
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
} 