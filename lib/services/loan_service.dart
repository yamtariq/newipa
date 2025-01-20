import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan.dart';
import 'auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../services/content_update_service.dart';

class LoanService {
  final _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getLoanDecision({
    required double salary,
    required double liabilities,
    required double expenses,
    required int requestedTenure,
  }) async {
    try {
      // Get user data from secure storage
      final userDataStr = await _secureStorage.read(key: 'user_data');
      if (userDataStr == null) {
        throw Exception('User data not found');
      }

      final requestBody = {
        'salary': salary.round(),
        'liabilities': liabilities.round(),
        'expenses': expenses.round(),
        'requested_tenure': requestedTenure,
        'national_id': jsonDecode(userDataStr)['national_id'],
      };

      print('DEBUG - API Request:');
      print('URL: ${Constants.apiBaseUrl}${Constants.endpointLoanDecision}');
      print('Headers: ${Constants.defaultHeaders}');
      print('Body: $requestBody');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointLoanDecision}'),
        headers: Constants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('DEBUG - API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to get loan decision: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['status'] == 'error') {
        if (data['code'] == 'ACTIVE_APPLICATION_EXISTS') {
          return data;
        }
        throw Exception(data['message']);
      }

      return data;
    } catch (e) {
      print('Error getting loan decision: $e');
      rethrow;
    }
  }

  Future<List<Loan>> getUserLoans() async {
    // Dummy data for loans
    return [
      Loan(
        id: "L001",
        amount: 100000,
        monthlyPayment: 2500,
        tenureMonths: 48,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 1410)),
        status: "Active",
        interestRate: 12.5,
        remainingAmount: 97500,
        nextPaymentDate: DateTime.now().add(const Duration(days: 15)),
      ),
      Loan(
        id: "L002",
        amount: 50000,
        monthlyPayment: 1500,
        tenureMonths: 36,
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        endDate: DateTime.now().add(const Duration(days: 900)),
        status: "Active",
        interestRate: 11.75,
        remainingAmount: 42000,
        nextPaymentDate: DateTime.now().add(const Duration(days: 10)),
      ),
    ];
  }

  Future<String> getCurrentApplicationStatus({bool isArabic = false}) async {
    // Dummy application status with language support
    return isArabic ? "قيد المراجعة" : "Under process";
  }

  Future<Map<String, dynamic>> getLoanAd({bool isArabic = false}) async {
    try {
      final adData = await ContentUpdateService().getLoanAd(isArabic: isArabic);
      if (adData != null) {
        return adData;
      }
      throw Exception('Failed to get loan advertisement');
    } catch (e) {
      print('Error in getLoanAd: $e');
      throw Exception('Failed to get loan advertisement');
    }
  }

  Future<Map<String, dynamic>> updateLoanApplication(
      Map<String, dynamic> loanData) async {
    try {
      print('DEBUG - Updating loan application:');
      print(
          'URL: ${Constants.apiBaseUrl}${Constants.endpointUpdateLoanApplication}');
      print('Data being sent: $loanData');

      final response = await http.post(
        Uri.parse(
            '${Constants.apiBaseUrl}${Constants.endpointUpdateLoanApplication}'),
        headers: Constants.defaultHeaders,
        body: jsonEncode(loanData),
      );

      print('DEBUG - API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData;
        } catch (e) {
          print('Error decoding JSON response: $e');
          print('Raw response: ${response.body}');
          throw Exception('Invalid response format from server');
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating loan application: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
}
