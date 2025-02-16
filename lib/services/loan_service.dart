import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan.dart';
import 'auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../services/content_update_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class LoanService {
  final _secureStorage = const FlutterSecureStorage();
  final _authService = AuthService();
  final _dio = Dio();
  
  // 💡 Helper function to log storage contents
  Future<void> _logStorageContents() async {
    try {
      print('\n--Secure Storage Contents--');
      final allSecureItems = await _secureStorage.readAll();
      allSecureItems.forEach((key, value) {
        print('$key: $value');
      });

      print('\n--Shared Preferences Contents--');
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      for (String key in allKeys) {
        print('$key: ${prefs.get(key)}');
      }
      print('\n');
    } catch (e) {
      print('Error logging storage contents: $e');
    }
  }
  
  Future<Map<String, dynamic>> getLoanDecision({
    required double salary,
    required double liabilities,
    required double expenses,
    required int requestedTenure,
  }) async {
    try {
      await _logStorageContents();  // 💡 Log storage contents before getting loan decision

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

  Future<Map<String, dynamic>> createCustomerLoanRequest(Map<String, dynamic> userData, bool isArabic) async {
    try {
      print('\n\n');
      print('========================================================');
      print('FUNCTION TRIGGERED: createCustomerLoanRequest');
      print('TIMESTAMP: ${DateTime.now()}');
      
      print('\n=== CREATE CUSTOMER LOAN REQUEST - START ===');
      print('1. Input User Data:');
      print(const JsonEncoder.withIndent('  ').convert(userData));
      
      // 💡 Get stored data from SharedPreferences only
      final prefs = await SharedPreferences.getInstance();
      final storedUserDataStr = prefs.getString('user_data');
      
      if (storedUserDataStr == null) {
        throw Exception('User data not found in storage');
      }

      final storedUserData = jsonDecode(storedUserDataStr);

      // 💡 Format phone number
      String formattedPhone = storedUserData['phone']?.toString() ?? '';
      if (formattedPhone.startsWith('966')) {
        formattedPhone = '0${formattedPhone.substring(3)}';
      }

      // 💡 Format dates to match API requirements (yyyy/mm/dd)
      String formatHijriDate(String? inputDate) {
        if (inputDate == null) return '1444/01/01';
        final parts = inputDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
        return inputDate;
      }

      // 💡 Prepare request data with existing data structure
      final requestData = {
        "nationnalID": storedUserData['national_id'],
        "dob": formatHijriDate(storedUserData['date_of_birth']),
        "doe": formatHijriDate(storedUserData['id_expiry_date']),
        "finPurpose": "BUF", //userData['loan_purpose'] ?? 
        "language": isArabic ? 1 : 0,
        "productType": 0,
        "mobileNo": formattedPhone,
        "emailId": storedUserData['email']?.toString().toLowerCase() ?? '',
        "finAmount": 10000,  // 💡 Fixed finance amount
        "tenure": 60,
        "propertyStatus": 1,
        "effRate": 1,
        "ibanNo": storedUserData['iban'] ?? "SA9750000000000555551111",
        "param1": "TEST001",           // string max 20
        "param2": "TEST002",           // string max 20
        "param3": "TEST003",           // string max 20
        "param4": "TEST004",           // string max 50
        "param5": "TEST005",           // string max 100
        "param6": "TEST006",           // string max 500
        "param7": 1234567.89,          // decimal 10 digits with 2 decimal points
        "param8": 9876543.21,          // decimal 10 digits with 2 decimal points
        "param9": "2025-02-10T10:02:34.269Z",  // datetime
        "param10": "2025-02-10T10:02:34.269Z", // datetime
        "param11": 123456,             // integer max 6 digits
        "param12": 654321,             // integer max 6 digits
        "param13": true,               // boolean
        "param14": false               // boolean
      };

      // Add debug logging for date fields
      print('\n2. Date Fields Debug:');
      print('Date of Birth: ${storedUserData['date_of_birth']}');
      print('Formatted DOB: ${formatHijriDate(storedUserData['date_of_birth'])}');
      print('ID Expiry Date: ${storedUserData['id_expiry_date']}');
      print('Formatted DOE: ${formatHijriDate(storedUserData['id_expiry_date'])}');

      print('\n3. Prepared Request Data:');
      print(const JsonEncoder.withIndent('  ').convert(requestData));

      print('\n');
      print('********************************************************');
      print('*                   API REQUEST DETAILS                  *');
      print('********************************************************');
      print('\n1. ENDPOINT:');
      print('   ${Constants.endpointCreateCustomer}');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse(Constants.endpointCreateCustomer));
      
      // 💡 Combine both proxy and bank headers
      final headers = {
        ...Constants.defaultHeaders,  // Proxy headers with api-key
        'bank-headers': base64.encode(utf8.encode(json.encode(Constants.bankApiHeaders))),  // Bank headers encoded for proxy
      };
      
      print('\n2. Request Headers:');
      print('Headers: ${headers.map((key, value) => MapEntry(key, key.toLowerCase() == 'authorization' || key.toLowerCase() == 'bank-headers' ? '[REDACTED]' : value))}');

      print('\n3. REQUEST BODY DETAILS:');
      print('   National ID: ${requestData['nationnalID']}');

      // Add headers
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      request.write(jsonEncode(requestData));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n5. API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: "$responseBody"');  // Added quotes to see if empty
      print('Response Body Length: ${responseBody.length}');
      print('Response Headers:');
      response.headers.forEach((name, values) {
        print('$name: $values');
      });

      // 💡 Handle empty response
      if (responseBody.isEmpty) {
        print('\nEmpty response body received');
        throw Exception('Empty response received from server');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }

      // 💡 Add try-catch for JSON parsing
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(responseBody);
      } catch (e) {
        print('\nError parsing JSON response: $e');
        print('Raw response body: "$responseBody"');
        throw Exception('Invalid response format from server');
      }

      print('\nParsed Response Data:');
      print('Success: ${responseData['success']}');
      if (responseData['errors'] != null) {
        print('Errors: ${responseData['errors']}');
      }
      if (responseData['result'] != null) {
        print('Result:');
        responseData['result'].forEach((key, value) {
          print('$key: $value');
        });
      }

      // Save response for later use
      await _secureStorage.write(
        key: 'loan_offer_data',
        value: jsonEncode(responseData),
      );
      print('\nResponse saved to secure storage with key: loan_offer_data');

      if (!responseData['success']) {
        print('\nRequest unsuccessful');
        return {
          'status': 'error',
          'message': responseData['errors']?.join(', ') ?? 'Unknown error occurred',
        };
      }

      final result = responseData['result'];
      
      // 💡 Calculate flat rate
      double financeAmount = double.tryParse(result['eligibleAmount'] ?? '0') ?? 0;
      double emi = double.tryParse(result['eligibleEmi'] ?? '0') ?? 0;
      int tenure = 60; // Default tenure from request
      
      // Calculate flat rate only if we have valid values
      double flatRate = 0;
      if (financeAmount > 0 && emi > 0 && tenure > 0) {
        flatRate = ((emi * tenure) - financeAmount) / (financeAmount * (tenure/12));
        // Round to 4 decimal places
        flatRate = double.parse(flatRate.toStringAsFixed(4));
        print('\nFlat Rate Calculation:');
        print('Finance Amount: $financeAmount');
        print('EMI: $emi');
        print('Tenure: $tenure');
        print('Calculated Flat Rate: $flatRate');
      }

      final mappedResponse = {
        'status': 'success',
        'decision': result['applicationStatus'] == 'APPROVED' ? 'approved' : 'rejected',
        'finance_amount': financeAmount,
        'emi': emi,
        'flat_rate': flatRate,
        'application_number': result['applicationId'],
        'request_id': result['requestId'],
        'customer_id': result['customerId'],
      };

      print('\nFinal Mapped Response:');
      mappedResponse.forEach((key, value) {
        print('$key: $value');
      });

      print('\n=== CREATE CUSTOMER LOAN REQUEST - END ===\n');
      return mappedResponse;

    } catch (e) {
      print('\nERROR in createCustomerLoanRequest:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('\n=== CREATE CUSTOMER LOAN REQUEST - END WITH ERROR ===\n');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<List<Loan>> getUserLoans() async {
    await _logStorageContents();  // 💡 Log storage contents before getting user loans
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
    ];
  }

  Future<String> getCurrentApplicationStatus({bool isArabic = false}) async {
    try {
      await _logStorageContents();  // 💡 Log storage contents before getting application status
      
      final userDataStr = await _secureStorage.read(key: 'user_data');
      print('DEBUG - User Data String: $userDataStr'); // Debug log

      if (userDataStr == null) {
        print('DEBUG - No user data found in storage'); // Debug log
        return isArabic ? 'لا توجد طلبات نشطة' : 'No active applications';
      }

      final userData = jsonDecode(userDataStr);
      final nationalId = userData['nationalId'];
      print('DEBUG - National ID: $nationalId'); // Debug log

      if (nationalId == null) {
        print('DEBUG - No national ID found in user data'); // Debug log
        return isArabic ? 'لا توجد طلبات نشطة' : 'No active applications';
      }

      final url = '${Constants.apiBaseUrl}/loan-application/latest-status/$nationalId';
      print('DEBUG - API URL: $url'); // Debug log
      print('DEBUG - Headers: ${Constants.defaultHeaders}'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: Constants.defaultHeaders,
      );
      
      print('DEBUG - Response Status Code: ${response.statusCode}'); // Debug log
      print('DEBUG - Response Body: ${response.body}'); // Debug log
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get application status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final status = data['data']['status'] as String;
      print('DEBUG - Parsed Status: $status'); // Debug log

      // Map the status to user-friendly messages
      switch (status.toUpperCase()) {
        case 'PENDING':
          return isArabic ? 'قيد المراجعة' : 'Under Review';
        case 'APPROVED':
          return isArabic ? 'تمت الموافقة' : 'Approved';
        case 'REJECTED':
          return isArabic ? 'مرفوض' : 'Rejected';
        case 'NO_APPLICATIONS':
          return isArabic ? 'لا توجد طلبات نشطة' : 'No active applications';
        default:
          return isArabic ? 'حالة غير معروفة' : 'Unknown Status';
      }
    } catch (e) {
      print('DEBUG - Error getting application status: $e'); // Debug log
      return isArabic ? 'لا توجد طلبات نشطة' : 'No active applications';
    }
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

  Future<Map<String, dynamic>> updateLoanApplication(Map<String, dynamic> loanData) async {
    try {
      await _logStorageContents();  // 💡 Log storage contents before updating loan application
      
      print('DEBUG - Updating loan application:');
      print('URL: ${Constants.apiBaseUrl}${Constants.endpointUpdateLoanApplication}');
      print('Data being sent: $loanData');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUpdateLoanApplication}'),
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

  Future<Map<String, dynamic>> insertLoanApplication(Map<String, dynamic> loanData) async {
    try {
      print('\n=== INSERT LOAN APPLICATION - START ===');
      print('Request Data:');
      print(const JsonEncoder.withIndent('  ').convert(loanData));

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointInsertLoanApplication}'));
      
      // Add headers
      final headers = {
        ...Constants.defaultHeaders,
        'api-key': Constants.apiKey,
      };
      
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      request.write(jsonEncode(loanData));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\nAPI Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode != 200) {
        throw Exception('Failed to insert loan application: ${response.statusCode}');
      }

      // Parse response
      final responseData = jsonDecode(responseBody);
      
      print('\n=== INSERT LOAN APPLICATION - END (SUCCESS) ===\n');
      return responseData;

    } catch (e) {
      print('\nERROR in insertLoanApplication:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('\n=== INSERT LOAN APPLICATION - END (WITH ERROR) ===\n');
      return {
        'status': 'error',
        'message': 'Failed to insert loan application: $e',
      };
    }
  }
}
