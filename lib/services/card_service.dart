import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/content_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class CardService {
  final _secureStorage = const FlutterSecureStorage();
  final _authService = AuthService();
  
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

  Future<Map<String, dynamic>> createCustomerCardRequest(Map<String, dynamic> userData, bool isArabic) async {
    try {
      print('\n=== CREATE CUSTOMER CARD REQUEST - START ===');
      print('1. Input User Data:');
      print(const JsonEncoder.withIndent('  ').convert(userData));
      
      // 💡 First get all required data from storage
      final prefs = await SharedPreferences.getInstance();
      final registrationDataStr = prefs.getString('registration_data');
      final storedUserDataStr = await _secureStorage.read(key: 'user_data');
      
      if (registrationDataStr == null || storedUserDataStr == null) {
        throw Exception('Required user data not found in storage');
      }

      final registrationData = jsonDecode(registrationDataStr);
      final storedUserData = jsonDecode(storedUserDataStr);
      final userRegistrationData = registrationData['userData'];

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

      // 💡 Prepare request data with mandatory fields only
      final requestData = {
        "nationnalID": storedUserData['national_id'],
        "dob": formatHijriDate(userRegistrationData['dateOfBirth']),
        "doe": formatHijriDate(userRegistrationData['idExpiryDate']),
        "finPurpose": "BUF",
        "language": isArabic ? 1 : 0,
        "productType": 1,
        "mobileNo": formattedPhone,
        "emailId": storedUserData['email']?.toString().toLowerCase() ?? '',
        "finAmount": (double.tryParse(userData['salary'].toString()) ?? 10000).round(),
        "tenure": 60,
        "propertyStatus": 1,
        "effRate": 1,
        "ibanNo": userData['iban'] ?? "SA9750000000000555551111"
      };

      print('\n2. Prepared Request Data:');
      print(const JsonEncoder.withIndent('  ').convert(requestData));

      // Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse(Constants.endpointCreateCustomer));
      
      // Add headers
      final headers = Constants.bankApiHeaders;
      print('\n3. Request Headers:');
      print('Headers: ${headers.map((key, value) => MapEntry(key, key.toLowerCase() == 'authorization' ? '[REDACTED]' : value))}');

      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Add body
      request.write(jsonEncode(requestData));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n4. API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode != 200) {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }

      final responseData = jsonDecode(responseBody);

      if (!responseData['success']) {
        return {
          'status': 'error',
          'message': responseData['errors']?.join(', ') ?? 'Unknown error occurred',
        };
      }

      final result = responseData['result'];
      final mappedResponse = {
        'status': 'success',
        'decision': result['applicationStatus'] == 'APPROVED' ? 'approved' : 'rejected',
        'credit_limit': double.tryParse(result['eligibleAmount'] ?? '0') ?? 0,
        'application_number': result['applicationId'],
        'request_id': result['requestId'],
        'customer_id': result['customerId'],
      };

      // Save response for later use
      await _secureStorage.write(
        key: 'card_offer_data',
        value: jsonEncode(responseData),
      );

      print('\n=== CREATE CUSTOMER CARD REQUEST - END ===\n');
      return mappedResponse;

    } catch (e) {
      print('\nERROR in createCustomerCardRequest:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('\n=== CREATE CUSTOMER CARD REQUEST - END WITH ERROR ===\n');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateCardApplication(Map<String, dynamic> cardData) async {
    try {
      print('\n=== UPDATE CARD APPLICATION - START ===');
      print('1. Input Card Data:');
      print(const JsonEncoder.withIndent('  ').convert(cardData));

      print('\n2. API Request Details:');
      print('Endpoint: ${Constants.apiBaseUrl}${Constants.endpointUpdateCardApplication}');
      print('Headers: ${Constants.defaultHeaders}');
      print('Request Body:');
      print(const JsonEncoder.withIndent('  ').convert(cardData));

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUpdateCardApplication}'),
        headers: Constants.defaultHeaders,
        body: json.encode(cardData),
      );

      print('\n3. API Response:');
      print('Status Code: ${response.statusCode}');
      print('Headers:');
      response.headers.forEach((key, value) {
        print('$key: $value');
      });
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('\n4. Parsed Response:');
        print(const JsonEncoder.withIndent('  ').convert(responseData));
        print('\n=== UPDATE CARD APPLICATION - END (SUCCESS) ===\n');
        return responseData;
      } else {
        print('\nERROR: Non-200 status code received');
        print('=== UPDATE CARD APPLICATION - END (ERROR) ===\n');
        throw Exception('Failed to update card application');
      }
    } catch (e) {
      print('\nERROR in updateCardApplication:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: ${StackTrace.current}');
      print('\n=== UPDATE CARD APPLICATION - END (WITH EXCEPTION) ===\n');
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
    try {
      print('\n=== GET CURRENT APPLICATION STATUS - START ===');
      
      final storage = await SharedPreferences.getInstance();
      final userData = storage.getString('user_data');
      
      print('\n1. Checking user data in SharedPreferences:');
      print('User Data exists: ${userData != null}');
      
      if (userData == null) {
        print('No user data found in SharedPreferences');
        return isArabic ? 'لا توجد طلبات نشطة' : 'No active applications';
      }

      final userDataMap = json.decode(userData);
      print('\n2. Parsed User Data:');
      print(const JsonEncoder.withIndent('  ').convert(userDataMap));
      
      final nationalId = userDataMap['national_id'];
      print('National ID: $nationalId');

      if (nationalId == null) {
        print('No National ID found in user data');
        return isArabic ? 'لا توجد طلبات نشطة' : 'No active applications';
      }

      print('\n3. API Request Details:');
      print('Endpoint: ${Constants.apiBaseUrl}/card-application/latest-status/$nationalId');
      print('Headers: ${Constants.defaultHeaders}');

      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/card-application/latest-status/$nationalId'),
        headers: Constants.defaultHeaders,
      );

      print('\n4. API Response:');
      print('Status Code: ${response.statusCode}');
      print('Headers:');
      response.headers.forEach((key, value) {
        print('$key: $value');
      });
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('\n5. Parsed Response:');
        print(const JsonEncoder.withIndent('  ').convert(responseData));
        
        if (!responseData['success']) {
          print('Response indicates failure');
          return isArabic ? 'حدث خطأ' : 'Error occurred';
        }
        
        final status = responseData['data']['status'] as String?;
        print('\n6. Application Status: $status');
        
        if (status == null) {
          print('No status found in response');
          return isArabic ? 'حدث خطأ' : 'Error occurred';
        }

        // Map status to user-friendly messages
        final String mappedStatus = switch (status.toUpperCase()) {
          'PENDING' => isArabic ? 'قيد المراجعة' : 'Under review',
          'APPROVED' => isArabic ? 'تمت الموافقة' : 'Approved',
          'REJECTED' => isArabic ? 'تم الرفض' : 'Rejected',
          'FULFILLED' => isArabic ? 'تم التنفيذ' : 'Fulfilled',
          'MISSING' => isArabic ? 'معلومات ناقصة' : 'Missing information',
          'FOLLOWUP' => isArabic ? 'قيد المتابعة' : 'Follow up required',
          'DECLINED' => isArabic ? 'تم الرفض من قبل العميل' : 'Declined by customer',
          'NO_APPLICATIONS' => isArabic ? 'لا توجد طلبات نشطة' : 'No active applications',
          _ => isArabic ? 'قيد المعالجة' : 'Processing',
        };

        print('\n7. Mapped Status: $mappedStatus');
        print('\n=== GET CURRENT APPLICATION STATUS - END (SUCCESS) ===\n');
        return mappedStatus;
      }
      
      print('\nERROR: Non-200 status code received');
      print('=== GET CURRENT APPLICATION STATUS - END (ERROR) ===\n');
      throw Exception('Failed to get application status');
    } catch (e) {
      print('\nERROR in getCurrentApplicationStatus:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: ${StackTrace.current}');
      print('\n=== GET CURRENT APPLICATION STATUS - END (WITH EXCEPTION) ===\n');
      return isArabic ? 'حدث خطأ' : 'Error occurred';
    }
  }
} 