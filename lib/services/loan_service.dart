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

      final userData = jsonDecode(userDataStr);
      final nationalId = userData['national_id'];

      // Prepare the Finnone request body according to the API documentation
      final requestBody = {
        'Header': {
          'Type': 'LOAN_APPLICATION',
          'RequestId': DateTime.now().millisecondsSinceEpoch
        },
        'Body': {
          'ApplicationId': 'LOAN_${DateTime.now().millisecondsSinceEpoch}',
          'CustomerInfo': [{
            'NationalId': nationalId,
            'FinancialAmount': salary.round().toString(),
            'Tenure': requestedTenure.toString(),
          }],
          'IncomeDetails': [{
            'Amount': salary.round().toString(),
            'Frequency': 'MONTHLY',
          }],
          'FinancialEMI': liabilities.round().toString(),
          'InstallmentNumbers': requestedTenure.toString(),
        }
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
      
      // Transform Finnone response to match the expected format
      if (data['status'] == 'error' || data['Status'] == 'error') {
        return {
          'status': 'error',
          'code': data['code'] ?? data['Code'] ?? 'SYSTEM_ERROR',
          'message': data['message'] ?? data['Message'] ?? 'An error occurred',
          'message_ar': data['message_ar'] ?? data['MessageAr'] ?? 'حدث خطأ',
        };
      }

      // Generate application number if not provided by Finnone
      final applicationNumber = data['ApplicationNumber'] ?? 
        data['application_number'] ?? 
        'LOAN_${DateTime.now().millisecondsSinceEpoch}';

      return {
        'status': 'success',
        'decision': 'approved',
        'finance_amount': data['FinanceAmount'] ?? data['finance_amount'] ?? 0,
        'tenure': data['Tenure'] ?? data['tenure'] ?? requestedTenure,
        'emi': data['Emi'] ?? data['emi'] ?? 0,
        'flat_rate': data['FlatRate'] ?? data['flat_rate'] ?? 0.16,
        'total_repayment': data['TotalRepayment'] ?? data['total_repayment'] ?? 0,
        'interest': data['Interest'] ?? data['interest'] ?? 0,
        'application_number': applicationNumber,
        'debug': data['Debug'] ?? data['debug'] ?? {},
      };
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
