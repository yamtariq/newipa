import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/content_update_service.dart';

class CardService {
  Future<Map<String, dynamic>> getCardDecision({
    required double salary,
    required double liabilities,
    required double expenses,
    required String nationalId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointCardDecision}'),
        headers: Constants.defaultHeaders,
        body: json.encode({
          'salary': salary,
          'liabilities': liabilities,
          'expenses': expenses,
          'national_id': nationalId,
        }),
      );

      print('DEBUG - API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // If decision is approved, determine card type based on credit limit
        if (responseData['status'] == 'success' && responseData['decision'] == 'approved') {
          final creditLimit = double.tryParse(responseData['credit_limit']?.toString() ?? '0') ?? 0;
          final cardType = creditLimit >= 17500 ? 'GOLD' : 'REWARD';
          responseData['card_type'] = cardType;
        }
        
        return responseData;
      } else {
        throw Exception('Failed to get card decision');
      }
    } catch (e) {
      print('Error getting card decision: $e');
      return {
        'status': 'error',
        'message': 'Failed to get card decision: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateCardApplication(Map<String, dynamic> cardData) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUpdateCardApplication}'),
        headers: Constants.defaultHeaders,
        body: json.encode(cardData),
      );

      print('DEBUG - API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update card application');
      }
    } catch (e) {
      print('Error updating card application: $e');
      return {
        'status': 'error',
        'message': 'Failed to update card application: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCardAd({bool isArabic = false}) async {
    try {
      final adData = ContentUpdateService().getCardAd(isArabic: isArabic);
      if (adData != null) {
        return adData;
      }
      throw Exception('Failed to get card advertisement');
    } catch (e) {
      print('Error in getCardAd: $e');
      throw Exception('Failed to get card advertisement');
    }
  }

  Future<List<Map<String, dynamic>>> getUserCards() async {
    // Dummy data for cards - replace with actual API call later
    return [
      {
        'card_number': '**** **** **** 1234',
        'card_type': 'Visa',
        'credit_limit': 20000,
        'available_credit': 15000,
        'status': 'Active',
      }
    ];
  }

  Future<String> getCurrentApplicationStatus({bool isArabic = false}) async {
    // Dummy application status with language support
    return isArabic 
      ? "قيد المراجعة"
      : "Under process";
  }
} 