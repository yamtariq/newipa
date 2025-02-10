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
      
      // Get stack trace properly
      try {
        throw Exception();
      } catch (e, stackTrace) {
        print('\nCALL STACK:');
        print(stackTrace.toString().split('\n').take(3).join('\n'));
      }
      print('========================================================');

      // First log ALL storage contents
      print('\nCOMPLETE STORAGE DUMP:');
      await _logStorageContents();

      print('\n********************************************************');
      print('*            STARTING LOAN REQUEST CREATION              *');
      print('********************************************************');
      
      print('\n1. INPUT DATA CHECK:');
      print('   User Data Received:');
      userData.forEach((key, value) {
        print('   • $key: $value');
      });
      print('   Is Arabic: $isArabic');

      print('\n2. CHECKING STORAGE:');
      final storedUserDataStr = await _secureStorage.read(key: 'user_data');
      print('   • user_data exists: ${storedUserDataStr != null}');
      
      final selectedSalaryDataStr = await _secureStorage.read(key: 'selected_salary_data');
      print('   • selected_salary_data exists: ${selectedSalaryDataStr != null}');
      
      // 💡 Get registration data from SharedPreferences instead of secure storage
      final prefs = await SharedPreferences.getInstance();
      final registrationDataStr = prefs.getString('registration_data');
      print('   • registration_data exists: ${registrationDataStr != null}');
      print('   • Attempted to read registration_data from SharedPreferences');

      if (storedUserDataStr == null || selectedSalaryDataStr == null || registrationDataStr == null) {
        print('\nERROR: Missing required storage data:');
        print('   • user_data: ${storedUserDataStr == null ? "MISSING" : "PRESENT"}');
        print('   • selected_salary_data: ${selectedSalaryDataStr == null ? "MISSING" : "PRESENT"}');
        print('   • registration_data: ${registrationDataStr == null ? "MISSING" : "PRESENT"}');
        throw Exception('Required user data not found in storage');
      }

      print('\n3. PARSING STORED DATA:');
      // 💡 Parse stored data
      final storedUserData = jsonDecode(storedUserDataStr);
      final selectedSalaryData = jsonDecode(selectedSalaryDataStr);
      final registrationData = jsonDecode(registrationDataStr);
      final userRegistrationData = registrationData['userData'];

      // 💡 Combine data from storage with input userData
      final enrichedUserData = {
        'national_id': storedUserData['national_id'] ?? userData['national_id'],
        'phone': storedUserData['phone'],
        'email': storedUserData['email'] ?? userData['email'],
        'ibanNo': userData['ibanNo'],
        'employer': selectedSalaryData['employer'],
        'salary': selectedSalaryData['amount'],
        'loan_purpose': userData['loan_purpose'],
        'name': storedUserData['name'] ?? userData['name'],
        'name_ar': storedUserData['name_ar'] ?? userData['arabic_name'],
        'date_of_birth': userRegistrationData['dateOfBirth'],
        'id_expiry_date': userRegistrationData['idExpiryDate']
      };

      print('Enriched User Data:');
      print('National ID: ${enrichedUserData['national_id']}');
      print('Name: ${enrichedUserData['name']}');
      print('Arabic Name: ${enrichedUserData['name_ar']}');
      print('Original Phone: ${enrichedUserData['phone']}');
      print('Email: ${enrichedUserData['email']}');
      print('IBAN: ${enrichedUserData['ibanNo']}');
      print('Employer: ${enrichedUserData['employer']}');
      print('Salary: ${enrichedUserData['salary']}');
      print('Loan Purpose: ${enrichedUserData['loan_purpose']}');
      print('Date of Birth: ${enrichedUserData['date_of_birth']}');
      print('ID Expiry Date: ${enrichedUserData['id_expiry_date']}');
      print('Language: ${isArabic ? 'Arabic' : 'English'}');

      // 💡 Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // 💡 Format phone number
      String formattedPhone = enrichedUserData['phone']?.toString() ?? '';
      if (formattedPhone.startsWith('966')) {
        formattedPhone = '0${formattedPhone.substring(3)}';
        print('Phone number transformed:');
        print('Original: ${enrichedUserData['phone']}');
        print('Formatted: $formattedPhone');
      } else {
        print('Phone number unchanged: $formattedPhone');
      }

      // 💡 Format dates to match API requirements (yyyy/mm/dd)
      String formatHijriDate(String inputDate) {
        // Input format: dd-mm-yyyy
        final parts = inputDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';  // Convert to yyyy/mm/dd
        }
        return inputDate;
      }

      // 💡 Prepare request data with mandatory fields only
      final requestData = {
        "nationalID": enrichedUserData['national_id'],
        "dob": formatHijriDate(enrichedUserData['date_of_birth']),  // Convert date format
        "doe": formatHijriDate(enrichedUserData['id_expiry_date']), // Convert date format
        "finPurpose": enrichedUserData['loan_purpose'],
        "language": isArabic ? 1 : 0,
        "productType": 0,
        "mobileNo": formattedPhone,
        "emailId": enrichedUserData['email'],
        "finAmount": double.tryParse(enrichedUserData['salary'].toString()) ?? 10000,
        "tenure": 60,
        "propertyStatus": 1,
        "effRate": 1,
        "ibanNo": enrichedUserData['ibanNo']
      };

      print('\n');
      print('********************************************************');
      print('*                   API REQUEST DETAILS                  *');
      print('********************************************************');
      print('\n1. ENDPOINT:');
      print('   ${Constants.endpointCreateCustomer}');
      
      print('\n2. HEADERS:');
      final headers = Constants.bankApiHeaders;
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          print('   $key: [REDACTED FOR SECURITY]');
        } else {
          print('   $key: $value');
        }
      });

      print('\n3. REQUEST BODY DETAILS:');
      print('   National ID: ${requestData['nationalID']}');
      print('   Date of Birth (formatted): ${requestData['dob']} (Original: ${enrichedUserData['date_of_birth']})');
      print('   ID Expiry Date (formatted): ${requestData['doe']} (Original: ${enrichedUserData['id_expiry_date']})');
      print('   Loan Purpose: ${requestData['finPurpose']}');
      print('   Language: ${requestData['language']} (${isArabic ? 'Arabic' : 'English'})');
      print('   Product Type: ${requestData['productType']}');
      print('   Mobile Number: ${requestData['mobileNo']}');
      print('   Email: ${requestData['emailId']}');
      print('   Finance Amount: ${requestData['finAmount']} SAR');
      print('   Tenure: ${requestData['tenure']} months');
      print('   Property Status: ${requestData['propertyStatus']} (1 = Owned)');
      print('   Effective Rate: ${requestData['effRate']}');
      print('   IBAN: ${requestData['ibanNo']}');

      print('\n4. COMPLETE REQUEST JSON:');
      print(const JsonEncoder.withIndent('   ').convert(requestData));
      print('\n********************************************************\n');

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse(Constants.endpointCreateCustomer));
      
      // Add headers
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Add body
      request.write(jsonEncode(requestData));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\nAPI Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      // 💡 Enhanced error logging
      if (response.statusCode != 200) {
        print('\nDetailed Error Analysis:');
        try {
          final errorData = jsonDecode(responseBody);
          print('Error Type: ${errorData['type'] ?? 'Not specified'}');
          print('Error Title: ${errorData['title'] ?? 'Not specified'}');
          print('Error Status: ${errorData['status'] ?? 'Not specified'}');
          print('Trace ID: ${errorData['traceId'] ?? 'Not specified'}');
          
          if (errorData['errors'] != null) {
            print('\nValidation Errors:');
            (errorData['errors'] as Map<String, dynamic>).forEach((key, value) {
              print('$key: ${value is List ? value.join(', ') : value}');
            });
          }
        } catch (e) {
          print('Could not parse error response: $e');
          print('Raw error response: $responseBody');
        }
        print('\nError: Non-200 status code received');
        throw Exception('Failed to create customer: ${response.statusCode}');
      }

      final responseData = jsonDecode(responseBody);
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
      final mappedResponse = {
        'status': 'success',
        'decision': result['applicationStatus'] == 'APPROVED' ? 'approved' : 'rejected',
        'finance_amount': double.tryParse(result['eligibleAmount'] ?? '0') ?? 0,
        'emi': double.tryParse(result['eligibleEmi'] ?? '0') ?? 0,
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

  Future<Map<String, dynamic>> updateLoanApplication(
      Map<String, dynamic> loanData) async {
    try {
      await _logStorageContents();  // 💡 Log storage contents before updating loan application
      
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

  Future<Map<String, dynamic>> createLoanApplicationOffer({required bool isArabic}) async {
    try {
      print('\n=== LOAN APPLICATION OFFER REQUEST - START ===');
      print('Timestamp: ${DateTime.now()}');

      // Log all storage contents first
      print('\n1. CHECKING ALL STORAGE DATA:');
      print('--Secure Storage Contents--');
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

      // Get user data from secure storage
      final userDataStr = await _secureStorage.read(key: 'user_data');
      final selectedSalaryDataStr = await _secureStorage.read(key: 'selected_salary_data');
      final registrationDataStr = prefs.getString('registration_data');

      print('\n2. CHECKING REQUIRED DATA AVAILABILITY:');
      print('• user_data exists: ${userDataStr != null}');
      print('• selected_salary_data exists: ${selectedSalaryDataStr != null}');
      print('• registration_data exists: ${registrationDataStr != null}');

      if (userDataStr != null) {
        print('\nUser Data Content:');
        print(const JsonEncoder.withIndent('  ').convert(jsonDecode(userDataStr)));
      }

      if (selectedSalaryDataStr != null) {
        print('\nSelected Salary Data Content:');
        print(const JsonEncoder.withIndent('  ').convert(jsonDecode(selectedSalaryDataStr)));
      }

      // Continue with existing code...
      print('\n3. FETCHING REGISTRATION DATA');
      
      if (registrationDataStr == null) {
        throw Exception('Registration data not found');
      }

      // Parse registration data
      final registrationData = jsonDecode(registrationDataStr);
      final userData = registrationData['userData'];

      // Get user data from secure storage for missing fields
      final userDataContent = userDataStr != null ? jsonDecode(userDataStr) : null;

      // Format dates to match API requirements (yyyy/mm/dd)
      String formatHijriDate(String inputDate) {
        final parts = inputDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
        return inputDate;
      }

      // Format phone number if needed
      String formatPhone(String phone) {
        if (phone.startsWith('966')) {
          return '0${phone.substring(3)}';
        }
        return phone;
      }

      // Log all available data before preparing request
      print('\n4. AVAILABLE DATA FOR REQUEST:');
      print('National ID: ${userDataContent?['national_id']}');
      print('Date of Birth: ${userData['dateOfBirth']}');
      print('ID Expiry Date: ${userData['idExpiryDate']}');
      print('Phone: ${userDataContent?['phone']}');
      print('Email: ${userDataContent?['email']}');

      // 💡 Step 2: Prepare request data with default values and user data content
      final requestData = {
        "nationnalID": userDataContent?['national_id'],
        "dob": formatHijriDate(userData['dateOfBirth']),
        "doe": formatHijriDate(userData['idExpiryDate']),
        "finPurpose": "BUF",
        "language": isArabic ? 1 : 0,
        "productType": 0,
        "mobileNo": formatPhone(userDataContent?['phone'] ?? ''),
        "emailId": userDataContent?['email']?.toString().toLowerCase() ?? '',
        "finAmount": 10000,
        "tenure": 60,
        "propertyStatus": 1,
        "effRate": 1,
        // 💡 Adding extra parameters with dummy data
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

      print('\n5. PREPARED REQUEST DATA:');
      print('National ID: ${requestData['nationalID']}');
      print('Date of Birth (formatted): ${requestData['dob']} (Original: ${userData['dateOfBirth']})');
      print('ID Expiry Date (formatted): ${requestData['doe']} (Original: ${userData['idExpiryDate']})');
      print('Finance Purpose: ${requestData['finPurpose']}');
      print('Language: ${requestData['language']} (${isArabic ? 'Arabic' : 'English'})');
      print('Product Type: ${requestData['productType']}');
      print('Mobile Number: ${requestData['mobileNo']}');
      print('Email: ${requestData['emailId']}');
      print('Finance Amount: ${requestData['finAmount']} SAR');
      print('Tenure: ${requestData['tenure']} months');
      print('Property Status: ${requestData['propertyStatus']}');
      print('Effective Rate: ${requestData['effRate']}');

      print('\n6. REQUEST DETAILS:');
      print('Endpoint: ${Constants.endpointCreateCustomer}');
      print('Headers: ${Constants.bankApiHeaders.map((key, value) => MapEntry(key, key.toLowerCase() == 'authorization' ? '[REDACTED]' : value))}');
      print('Request Body (JSON):');
      print(const JsonEncoder.withIndent('  ').convert(requestData));

      // Step 3: Make API call
      print('\n7. MAKING API CALL');
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse(Constants.endpointCreateCustomer));
      
      // Add headers
      Constants.bankApiHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Add body
      request.write(jsonEncode(requestData));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n8. API RESPONSE:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((name, values) {
        print('  $name: ${values.join(', ')}');
      });
      print('Response Body:');
      try {
        print(const JsonEncoder.withIndent('  ').convert(jsonDecode(responseBody)));
      } catch (e) {
        print('Raw response: $responseBody');
      }

      if (response.statusCode != 200) {
        print('\nERROR: Non-200 status code received');
        throw Exception('Failed to create loan offer: ${response.statusCode}');
      }

      // Step 4: Parse and return response
      final responseData = jsonDecode(responseBody);
      
      // Save response for later use
      await _secureStorage.write(
        key: 'loan_offer_data',
        value: jsonEncode(responseData),
      );
      print('\n9. Response saved to secure storage with key: loan_offer_data');

      print('\n=== LOAN APPLICATION OFFER REQUEST - END ===\n');
      return responseData;

    } catch (e) {
      print('\nERROR in createLoanApplicationOffer:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:');
      try {
        throw Exception();
      } catch (_, stackTrace) {
        print(stackTrace.toString().split('\n').take(5).join('\n'));
      }
      print('\n=== LOAN APPLICATION OFFER REQUEST - END WITH ERROR ===\n');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
}
