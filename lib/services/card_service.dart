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

  // 💡 Add method to fetch card types and limits
  Future<Map<String, dynamic>> _getCardTypeForAmount(double amount) async {
    try {
      print('\n=== GET CARD TYPE FOR AMOUNT - START ===');
      print('Requested Amount: $amount');
      
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/constants'),
        headers: Constants.defaultHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch card types');
      }

      final responseData = json.decode(response.body);
      if (!responseData['success']) {
        throw Exception('Failed to get card types from response');
      }

      final constants = responseData['data'] as List;
      
      // Filter for card types and their limits
      final cardTypes = constants.where((c) => 
        c['name'] == 'CardType' || c['name'].toString().endsWith('_Limit')
      ).toList();

      print('\nAvailable Card Types and Limits:');
      print(const JsonEncoder.withIndent('  ').convert(cardTypes));

      // Find matching card type based on amount
      String? selectedType;
      String? selectedTypeAr;
      
      for (final constant in cardTypes) {
        if (constant['name'].toString().endsWith('_Limit')) {
          final cardType = constant['name'].toString().replaceAll('_Limit', '');
          // 💡 Remove all spaces and handle different dash formats
          final limitRange = constant['value'].toString().replaceAll(' ', '').split('-');
          
          if (limitRange.length == 2) {
            final minLimit = double.tryParse(limitRange[0].trim()) ?? 0;
            final maxLimit = double.tryParse(limitRange[1].trim()) ?? double.infinity;
            
            print('\nChecking range for $cardType:');
            print('Amount: $amount');
            print('Min: $minLimit, Max: $maxLimit');
            
            if (amount >= minLimit && amount <= maxLimit) {
              // Find corresponding card type name
              final typeData = cardTypes.firstWhere(
                (c) => c['name'] == 'CardType' && c['value'] == cardType,
                orElse: () => {'value': cardType, 'valueAr': cardType},
              );
              
              selectedType = typeData['value'];
              selectedTypeAr = typeData['valueAr'];
              break;
            }
          }
        }
      }

      print('\nSelected Card Type:');
      print('Type: $selectedType');
      print('Type (Arabic): $selectedTypeAr');
      print('=== GET CARD TYPE FOR AMOUNT - END ===\n');

      if (selectedType == null) {
        throw Exception('No matching card type found for amount: $amount');
      }

      return {
        'type': selectedType,
        'typeAr': selectedTypeAr,
      };
    } catch (e) {
      print('Error determining card type: $e');
      throw Exception('Failed to determine card type: $e');
    }
  }

  Future<Map<String, dynamic>> createCustomerCardRequest(Map<String, dynamic> userData, bool isArabic) async {
    try {
      print('\n=== CREATE CUSTOMER CARD REQUEST - START ===');
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

      // 💡 Get card type based on amount (for display only)
      final requestedAmount = (double.tryParse(userData['salary'].toString()) ?? 10000).round();
      final cardTypeData = await _getCardTypeForAmount(requestedAmount.toDouble());
      
      // 💡 Log card type information for user
      print('\n=== CARD TYPE INFORMATION ===');
      print('Based on the requested amount of SAR $requestedAmount:');
      print('Eligible Card Type: ${cardTypeData['type']}');
      print('نوع البطاقة المؤهل: ${cardTypeData['typeAr']}');
      print('===============================\n');

      // 💡 Prepare request data with existing data structure
      final requestData = {
        "nationnalID": storedUserData['national_id'],
        "dob": formatHijriDate(storedUserData['date_of_birth']),
        "doe": formatHijriDate(storedUserData['id_expiry_date']),
        "finPurpose": "BUF",
        "language": isArabic ? 1 : 0,
        "productType": 1,
        "mobileNo": formattedPhone,
        "emailId": storedUserData['email']?.toString().toLowerCase() ?? '',
        "finAmount": 10000, // 💡 Hardcoded high limit for initial request
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

      // Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse(Constants.endpointCreateCustomer));
      
      // 💡 Combine both proxy and bank headers
      final headers = {
        ...Constants.defaultHeaders,  // Proxy headers with api-key
        'bank-headers': base64.encode(utf8.encode(json.encode(Constants.bankApiHeaders))),  // Bank headers encoded for proxy
      };
      
      // 💡 Log complete request details
      print('\n=== CREATE CUSTOMER REQUEST DETAILS ===');
      print('Endpoint: ${Constants.endpointCreateCustomer}');
      print('Headers:');
      headers.forEach((key, value) {
        print('$key: ${key.toLowerCase() == 'authorization' || key.toLowerCase() == 'bank-headers' ? '[REDACTED]' : value}');
      });
      print('\nRequest Body:');
      print(const JsonEncoder.withIndent('  ').convert(requestData));

      // Set headers and send request
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.write(jsonEncode(requestData));
      
      // Get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      // 💡 Log complete response details
      print('\n=== CREATE CUSTOMER RESPONSE DETAILS ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((name, values) {
        print('$name: $values');
      });
      print('\nResponse Body:');
      if (responseBody.isNotEmpty) {
        try {
          print(const JsonEncoder.withIndent('  ').convert(json.decode(responseBody)));
        } catch (e) {
          print('Raw response: $responseBody');
          print('(Could not parse as JSON: $e)');
        }
      } else {
        print('(Empty response body)');
      }
      print('=== END CREATE CUSTOMER DETAILS ===\n');

      // Handle empty response
      if (responseBody.isEmpty) {
        throw Exception('Empty response received from server');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }

      // Parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(responseBody);
      } catch (e) {
        throw Exception('Invalid response format from server: $e');
      }

      if (!responseData['success']) {
        // 💡 Special handling for NOT ELIGIBLE error
        final errorMessage = responseData['errors']?.join(', ') ?? responseData['message'] ?? 'Unknown error occurred';
        if (errorMessage.toUpperCase().contains('NOT ELIGIBLE')) {
          return {
            'status': 'error',
            'error_type': 'NOT_ELIGIBLE',
            'message': isArabic 
              ? 'عذراً، أنت غير مؤهل للحصول على البطاقة في الوقت الحالي'
              : 'Sorry, you are not eligible for a card at this time',
            'message_ar': 'عذراً، أنت غير مؤهل للحصول على البطاقة في الوقت الحالي',
            'should_contact_support': true
          };
        }

        // Get card type for rejected application
        final cardTypeData = await _getCardTypeForAmount(requestedAmount.toDouble());
        final selectedCardType = cardTypeData['type'] ?? 'REWARDS';
        final result = responseData['result'];

        // 💡 If createCustomer is rejected, insert a rejected application
        final cardData = {
          'national_id': storedUserData['national_id'],
          'application_no': DateTime.now().millisecondsSinceEpoch,
          'customerDecision': 'PENDING',
          'card_type': selectedCardType,
          'card_limit': 0,
          'status': 'rejected',
          'status_date': DateTime.now().toIso8601String(),
          'remarks': 'Application rejected by bank',
          'noteUser': 'SYSTEM',
          'note': responseData['errors']?.join(', ') ?? responseData['message'] ?? 'Unknown error occurred',
          'NameOnCard': storedUserData['nameOnCard'] ?? '',
        };

        await insertCardApplication(cardData);

        return {
          'status': 'error',
          'error_type': 'GENERAL',
          'message': responseData['errors']?.join(', ') ?? responseData['message'] ?? 'Unknown error occurred',
          'message_ar': 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى',
          'should_contact_support': false
        };
      }

      final result = responseData['result'];
      print('\nDEBUG - Credit Limit Parsing:');
      print('Raw eligibleAmount: ${result['eligibleAmount']}');
      print('Type of eligibleAmount: ${result['eligibleAmount']?.runtimeType}');
      
      // 💡 1. Get and save the eligible amount from createCustomer response
      final eligibleAmount = double.tryParse(result['eligibleAmount'] ?? '0') ?? 0;
      print('Parsed Eligible Amount: $eligibleAmount');

      // 💡 2. Get all card type limits from constants
      final constantsResponse = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/constants'),
        headers: Constants.defaultHeaders,
      );

      if (constantsResponse.statusCode != 200) {
        throw Exception('Failed to fetch constants');
      }

      final constantsData = json.decode(constantsResponse.body);
      if (!constantsData['success']) {
        throw Exception('Failed to get constants from response');
      }

      // 💡 3. Save all limits with their card types
      final constants = constantsData['data'] as List;
      final cardLimits = <Map<String, dynamic>>[];
      
      for (final constant in constants) {
        if (constant['name'].toString().endsWith('_Limit')) {
          final cardType = constant['name'].toString().replaceAll('_Limit', '');
          final limitRange = constant['value'].toString().split(' - ');
          
          if (limitRange.length == 2) {
            cardLimits.add({
              'cardType': cardType,
              'minLimit': double.tryParse(limitRange[0]) ?? 0,
              'maxLimit': double.tryParse(limitRange[1]) ?? double.infinity,
            });
          }
        }
      }

      print('\nCard Limits:');
      print(const JsonEncoder.withIndent('  ').convert(cardLimits));

      // 💡 4. Determine card type based on eligible amount
      var selectedCardType = 'REWARDS'; // Default type
      for (final limit in cardLimits) {
        if (eligibleAmount >= limit['minLimit'] && eligibleAmount <= limit['maxLimit']) {
          selectedCardType = limit['cardType'];
          print('\nSelected Card Type: $selectedCardType');
          print('Eligible Amount: $eligibleAmount falls in range:');
          print('Min: ${limit['minLimit']}, Max: ${limit['maxLimit']}');
          break;
        }
      }

      // Get Arabic name for selected card type
      final selectedTypeData = constants.firstWhere(
        (c) => c['name'] == 'CardType' && c['value'] == selectedCardType,
        orElse: () => {'valueAr': 'المكافآت'},
      );

      final mappedResponse = {
        'status': 'success',
        'decision': result['applicationStatus'] == 'APPROVED' ? 'approved' : 'rejected',
        'credit_limit': eligibleAmount.round(),
        'application_number': result['applicationId'],
        'request_id': result['requestId'],
        'customer_id': result['customerId'],
        'card_type': selectedCardType,
        'card_type_ar': selectedTypeData['valueAr'],
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

  Future<Map<String, dynamic>> updateCustomerCardRequest(Map<String, dynamic> cardData) async {
    try {
      print('\n=== UPDATE CUSTOMER CARD REQUEST - START ===');
      print('1. Input Card Data:');
      print(const JsonEncoder.withIndent('  ').convert(cardData));

      // Validate required fields
      if (cardData['national_id'] == null || cardData['national_id'].toString().isEmpty) {
        throw Exception('National ID is required');
      }

      if (cardData['application_number'] == null || cardData['application_number'].toString().isEmpty) {
        throw Exception('Application number is required');
      }

      // 💡 First call Finnone UpdateAmount endpoint
      final finnoneUpdateData = {
        'AgreementId': cardData['application_number'].toString(),
        'Amount': cardData['card_limit'],
        'Tenure': 0,
        'FinEmi': 0,
        'RateEliGible': 0
      };

      print('\n2. Calling Finnone UpdateAmount API:');
      print('URL: ${Constants.endpointFinnoneUpdateAmount}');
      print('Data: $finnoneUpdateData');

      final finnoneClient = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final finnoneRequest = await finnoneClient.postUrl(Uri.parse(Constants.endpointFinnoneUpdateAmount));
      
      // Add headers
      final headers = {
        ...Constants.bankApiHeaders,
        'api-key': Constants.apiKey,
      };
      
      headers.forEach((key, value) {
        finnoneRequest.headers.set(key, value);
      });

      // Add body
      finnoneRequest.write(jsonEncode(finnoneUpdateData));
      
      final finnoneResponse = await finnoneRequest.close();
      final finnoneResponseBody = await finnoneResponse.transform(utf8.decoder).join();

      print('\n3. Finnone UpdateAmount Response:');
      print('Status Code: ${finnoneResponse.statusCode}');
      print('Response Body: $finnoneResponseBody');

      if (finnoneResponse.statusCode != 200) {
        throw Exception('Failed to update amount in Finnone: ${finnoneResponse.statusCode}');
      }

      // Parse Finnone response
      final finnoneUpdateResponse = jsonDecode(finnoneResponseBody);
      if (finnoneUpdateResponse['success'].toString().toLowerCase() != 'record updated successfully') {
        throw Exception('Finnone update failed: ${finnoneUpdateResponse['message'] ?? 'Unknown error'}');
      }

      // Now proceed with the original UpdateCustomer endpoint call
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse(Constants.endpointUpdateCustomer));
      
      // 💡 Combine both proxy and bank headers
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // 💡 Prepare request body
      final requestBody = {
        'nationnalID': cardData['national_id'],
        'applicationID': cardData['application_number'],
        'acceptFlag': cardData['customerDecision'] == 'ACCEPTED' ? 1 : 0,
        'nameOnCard': cardData['nameOnCard'],
      };

      print('\n4. UpdateCustomer Request Body:');
      print(const JsonEncoder.withIndent('  ').convert(requestBody));

      // Add body
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n5. UpdateCustomer Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${responseBody}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update customer: HTTP ${response.statusCode}');
      }

      // 💡 Handle empty response
      if (responseBody.isEmpty) {
        print('\nEmpty response body received');
        throw Exception('Empty response received from server');
      }

      // 💡 Parse response with error handling
      Map<String, dynamic> updateCustomerData;
      try {
        updateCustomerData = jsonDecode(responseBody);
      } catch (e) {
        print('\nError parsing JSON response: $e');
        print('Raw response body: "$responseBody"');
        throw Exception('Invalid response format from server');
      }

      if (!updateCustomerData['success']) {
        final errors = updateCustomerData['errors'] ?? [];
        final errMsg = updateCustomerData['result']?['errMsg'] ?? '';
        throw Exception('Failed to update customer: ${errors.isNotEmpty ? errors.join(', ') : errMsg}');
      }

      // 💡 After successful updateCustomer, insert the final application status
      final insertResponse = await insertCardApplication({
        'national_id': cardData['national_id'],
        'application_no': cardData['application_number'],
        'customerDecision': cardData['customerDecision'],
        'card_type': cardData['card_type'],
        'card_limit': cardData['card_limit'],
        'status': cardData['customerDecision'] == 'ACCEPTED' ? 'approved' : 'declined',
        'status_date': DateTime.now().toIso8601String(),
        'remarks': cardData['customerDecision'] == 'ACCEPTED' ? 'Card offer accepted by customer' : 'Card offer declined by customer',
        'noteUser': cardData['noteUser'] ?? 'CUSTOMER',
        'note': cardData['note'] ?? 'Application ${cardData['customerDecision'].toLowerCase()} via mobile app',
        'NameOnCard': cardData['nameOnCard'],
      });

      print('\n3. Insert Card Application Response:');
      print('Response Data: ${const JsonEncoder.withIndent('  ').convert(insertResponse)}');

      if (!insertResponse['success']) {
        throw Exception('Failed to save card application: ${insertResponse['data']?['message'] ?? 'Unknown error'}');
      }

      print('\n=== UPDATE CUSTOMER CARD REQUEST - END (SUCCESS) ===\n');
      return {
        'status': 'success',
        'message': insertResponse['data']['message'],
        'details': insertResponse['data']['details']
      };
    } catch (e) {
      print('\nERROR in updateCustomerCardRequest:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: ${StackTrace.current}');
      print('\n=== UPDATE CUSTOMER CARD REQUEST - END (WITH EXCEPTION) ===\n');
      return {
        'status': 'error',
        'message': 'Failed to update customer card request: $e',
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

  Future<Map<String, dynamic>> insertCardApplication(Map<String, dynamic> cardData) async {
    try {
      print('\n=== INSERT CARD APPLICATION - START ===');
      print('1. Input Card Data:');
      print(const JsonEncoder.withIndent('  ').convert(cardData));

      // Validate required fields
      final requiredFields = [
        'national_id',
        'application_no',
        'customerDecision',
        'card_type',
        'card_limit',
        'status',
        'NameOnCard'
      ];

      for (final field in requiredFields) {
        if (cardData[field] == null || cardData[field].toString().isEmpty) {
          throw Exception('Required field missing: $field');
        }
      }

      // Validate National ID format (10 digits starting with 1 or 2)
      final nationalId = cardData['national_id'].toString();
      if (!RegExp(r'^[12]\d{9}$').hasMatch(nationalId)) {
        throw Exception('Invalid National ID format');
      }

      print('\n2. API Request Details:');
      print('Endpoint: ${Constants.apiBaseUrl}${Constants.endpointInsertCardApplication}');
      print('Headers: ${Constants.defaultHeaders}');

      // 💡 Format request body according to API schema
      final requestBody = {
        'nationalId': cardData['national_id'].toString(),
        'applicationNo': int.parse(cardData['application_no'].toString()),
        'cardType': cardData['card_type'].toString(),
        'cardLimit': int.parse(cardData['card_limit'].toString()),
        'status': cardData['status'].toString(),
        'customerDecision': cardData['customerDecision'].toString(),
        'nameOnCard': (cardData['NameOnCard'] ?? '').toString(),
        'remarks': (cardData['remarks'] ?? '').toString(),
        'noteUser': (cardData['noteUser'] ?? '').toString(),
        'note': (cardData['note'] ?? '').toString()
      };

      print('\n3. Request Body:');
      print(const JsonEncoder.withIndent('  ').convert(requestBody));

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointInsertCardApplication}'));
      
      // Add headers
      final headers = {
        ...Constants.defaultHeaders,
        'Accept': 'application/json',
      };
      
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Add body
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n4. API Response:');
      print('Status Code: ${response.statusCode}');
      print('Headers:');
      response.headers.forEach((name, values) {
        print('$name: $values');
      });
      print('Response Body: ${responseBody}');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        print('\n5. Parsed Response:');
        print(const JsonEncoder.withIndent('  ').convert(responseData));
        print('\n=== INSERT CARD APPLICATION - END (SUCCESS) ===\n');
        return responseData;
      } else {
        print('\nERROR: Non-200 status code received');
        print('=== INSERT CARD APPLICATION - END (ERROR) ===\n');
        
        // Try to parse error response for more details
        try {
          final errorData = json.decode(responseBody);
          final errorMessage = errorData['errors']?.values
              ?.expand((e) => e as List)
              ?.join(', ') ?? 
              errorData['title'] ??
              'Failed to insert card application';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to insert card application: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('\nERROR in insertCardApplication:');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: ${StackTrace.current}');
      print('\n=== INSERT CARD APPLICATION - END (WITH EXCEPTION) ===\n');
      return {
        'status': 'error',
        'message': 'Failed to insert card application: $e',
      };
    }
  }
} 