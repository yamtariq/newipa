import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/registration/registration_constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class RegistrationService {
  // Check if user exists and validate identity
  Future<Map<String, dynamic>> validateIdentity(String id, String phone) async {
    try {
      print('🚀 Checking if ID already registered...');
      
      // Get device info
      final deviceInfo = await _getDeviceInfo();
      print('📱 Device Info: $deviceInfo');
      
      // Check if ID exists using signin endpoint
      final checkResponse = await http.post(
        Uri.parse('${Constants.authBaseUrl}/signin'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': Constants.apiKey
        },
        body: json.encode({
          'nationalId': id,
          'deviceId': deviceInfo['deviceId']
        }),
      );

      print('📥 Check registration response: ${checkResponse.statusCode}');
      print('📥 Check registration body: ${checkResponse.body}');

      if (checkResponse.statusCode == 401) {
        final errorResponse = json.decode(checkResponse.body);
        
        // If error code is CUSTOMER_NOT_FOUND, it means user is not registered
        if (errorResponse['details']?['code'] == 'CUSTOMER_NOT_FOUND') {
          print('✅ ID is valid and not registered');
          return {
            'status': 'success',
            'message': 'ID is valid and not registered'
          };
        }
      }
      
      // If we get here, user exists
      print('❌ This ID is already registered');
      return {
        'status': 'error',
        'message': 'This ID is already registered'
      };
      
      // Add more detailed error information
      if (checkResponse.statusCode == 400) {
        final errorResponse = json.decode(checkResponse.body);
        print('❌ Error: ${errorResponse['error'] ?? 'Failed to validate identity'}');
        return {
          'status': 'error',
          'message': errorResponse['error'] ?? 'Failed to validate identity',
          'details': 'Status code: ${checkResponse.statusCode}, Body: ${checkResponse.body}'
        };
      }
      
      print('❌ Failed to validate identity');
      return {
        'status': 'error',
        'message': 'Failed to validate identity. Please try again later.',
        'details': 'Status code: ${checkResponse.statusCode}'
      };
    } catch (e) {
      print('❌ Error validating identity: $e');
      return {
        'status': 'error',
        'message': 'Connection error. Please check your internet connection.'
      };
    }
  }

  // Generate OTP
  Future<Map<String, dynamic>> generateOTP(String nationalId, {String? mobileNo}) async {
    try {
      print('\n=== GENERATE OTP REQUEST ===');
      final url = '${Constants.apiBaseUrl}/proxy/forward?url=${Constants.proxyOtpGenerateUrl}';
      print('🌐 URL: $url');
      
      // Format phone number: Add 966 prefix and remove any existing prefix
      final formattedPhone = mobileNo != null 
          ? '966${mobileNo.replaceAll('+', '').replaceAll('966', '')}'
          : '';
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': Constants.apiKey
      };
      print('📤 Headers: $headers');
      
      final requestBody = Constants.otpGenerateRequestBody(
        nationalId, 
        formattedPhone,
        purpose: 'Registration'
      );
      print('📤 Request Body: ${json.encode(requestBody)}');

      // Create a client that follows redirects
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(requestBody),
        );

        print('\n=== GENERATE OTP RESPONSE ===');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Headers: ${response.headers}');
        print('📥 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ Parsed Response Data: $data');
          
          if (data['success'] == true) {
            print('✅ OTP Generation Successful');
            final successResponse = {
              'status': 'success',
              'message': 'OTP sent successfully',
              'message_ar': 'تم إرسال رمز التحقق بنجاح',
              'data': data['result']
            };
            print('✅ Returning Success Response: $successResponse');
            return successResponse;
          }
          
          print('❌ OTP Generation Failed with Error: ${data['message']}');
          final errorResponse = {
            'status': 'error',
            'message': data['message'] ?? 'Failed to generate OTP',
            'message_ar': 'فشل في إرسال رمز التحقق'
          };
          print('❌ Returning Error Response: $errorResponse');
          return errorResponse;
        }

        print('❌ HTTP Request Failed with Status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'Failed to generate OTP',
          'message_ar': 'فشل في إرسال رمز التحقق'
        };
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      print('\n=== GENERATE OTP ERROR ===');
      print('❌ Error: $e');
      print('❌ Stack Trace: $stackTrace');
      return {
        'status': 'error',
        'message': e.toString(),
        'message_ar': 'حدث خطأ أثناء إرسال رمز التحقق'
      };
    } finally {
      print('=== END GENERATE OTP ===\n');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String nationalId, String otpCode) async {
    try {
      print('\n=== VERIFY OTP REQUEST ===');
      final url = '${Constants.apiBaseUrl}/proxy/forward?url=${Constants.proxyOtpVerifyUrl}';
      print('🌐 URL: $url');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': Constants.apiKey
      };
      print('📤 Headers: $headers');
      
      final requestBody = Constants.otpVerifyRequestBody(nationalId, otpCode);
      print('📤 Request Body: ${json.encode(requestBody)}');

      // Create a client that follows redirects
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(requestBody),
        );

        print('\n=== VERIFY OTP RESPONSE ===');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Headers: ${response.headers}');
        print('📥 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ Parsed Response Data: $data');
          
          if (data['success'] == true) {
            print('✅ OTP Verification Successful');
            final successResponse = {
              'status': 'success',
              'message': 'OTP verified successfully',
              'message_ar': 'تم التحقق من رمز التحقق بنجاح',
              'data': data['result']
            };
            print('✅ Returning Success Response: $successResponse');
            return successResponse;
          }
          
          print('❌ OTP Verification Failed with Error: ${data['message']}');
          final errorResponse = {
            'status': 'error',
            'message': data['message'] ?? 'Failed to verify OTP',
            'message_ar': 'فشل في التحقق من رمز التحقق'
          };
          print('❌ Returning Error Response: $errorResponse');
          return errorResponse;
        }

        print('❌ HTTP Request Failed with Status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'Failed to verify OTP',
          'message_ar': 'فشل في التحقق من رمز التحقق'
        };
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      print('\n=== VERIFY OTP ERROR ===');
      print('❌ Error: $e');
      print('❌ Stack Trace: $stackTrace');
      return {
        'status': 'error',
        'message': e.toString(),
        'message_ar': 'حدث خطأ أثناء التحقق من رمز التحقق'
      };
    } finally {
      print('=== END VERIFY OTP ===\n');
    }
  }

  // Set password
  Future<Map<String, dynamic>> setPassword(String id, String password) async {
    try {
      print('🔒 Setting password...');
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSetPassword}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': Constants.apiKey
        },
        body: json.encode({
          'national_id': id,
          'password': password,
        }),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Password set successfully');
        return json.decode(response.body);
      }
      print('❌ Failed to set password');
      return {
        'status': 'error',
        'message': 'Failed to set password'
      };
    } catch (e) {
      print('❌ Error setting password: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Set MPIN
  Future<Map<String, dynamic>> setMPIN(String id, String mpin) async {
    try {
      print('🔒 Setting MPIN...');
      final secureStorage = const FlutterSecureStorage();
      await secureStorage.write(key: 'mpin', value: mpin);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mpin', mpin);

      print('✅ MPIN set successfully');
      return {
        'status': 'success',
        'message': 'MPIN set successfully'
      };
    } catch (e) {
      print('❌ Error storing MPIN locally: $e');
      return {
        'status': 'error',
        'message': 'Failed to store MPIN locally'
      };
    }
  }

  // Check if user is already registered
  Future<Map<String, dynamic>> checkRegistration(String nationalId) async {
    try {
      print('🔍 Checking if user is already registered...');
      final url = Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegistration}');
      
      // Get device info for the request
      final deviceInfo = await _getDeviceInfo();
      print('📱 Device Info: $deviceInfo');

      final requestBody = {
        'checkOnly': true,
        'nationalId': nationalId,
        'deviceInfo': deviceInfo
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': Constants.apiKey
        },
        body: json.encode(requestBody),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ User is not registered');
        return json.decode(response.body);
      }
      
      // Add more detailed error information
      if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        print('❌ Error: ${errorResponse['error'] ?? 'ID already registered'}');
        return {
          'status': 'error',
          'message': errorResponse['error'] ?? 'ID already registered',
          'details': 'Status code: ${response.statusCode}, Body: ${response.body}'
        };
      }
      
      print('❌ Failed to check registration');
      return {
        'status': 'error',
        'message': 'Failed to check registration',
        'details': 'Status code: ${response.statusCode}, Body: ${response.body}'
      };
    } catch (e) {
      print('❌ Registration Check Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Get government data
  Future<Map<String, dynamic>> getGovernmentData(String nationalId, {
    String? dateOfBirthHijri,
    String? idExpiryDate,
  }) async {
    try {
      print('\n=== GETTING GOVERNMENT DATA ===');
      print('🔍 National ID: $nationalId');
      print('🌐 URL: ${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': Constants.apiKey
        },
        body: json.encode({
          'iqamaNumber': nationalId,
          'dateOfBirthHijri': dateOfBirthHijri ?? '1398-07-01',
          'idExpiryDate': idExpiryDate ?? '1-1-1'
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Government data retrieved successfully');
        return {
          'status': 'success',
          'data': json.decode(response.body)
        };
      }

      print('❌ Failed to get government data');
      return {
        'status': 'error',
        'message': 'Failed to get government data'
      };
    } catch (e) {
      print('❌ Error getting government data: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    return {
      'deviceId': androidInfo.id,
      'platform': 'Android',
      'model': androidInfo.model,
      'manufacturer': androidInfo.manufacturer,
    };
  }

  // Store registration data locally
  Future<void> storeRegistrationData({
    required String nationalId,
    required String email,
    required String phone,
    required Map<String, dynamic> userData,
    String? password,
    Map<String, dynamic>? nafathData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage();
    
    final secureData = {
      'national_id': nationalId,
      'full_name': userData['full_name'],
      'arabic_name': userData['arabic_name'],
      'email': email,
      'dob': userData['dob'],
      'salary': userData['salary'],
      'employment_status': userData['employment_status'],
      'employer_name': userData['employer_name'],
      'employment_date': userData['employment_date'],
      'national_address': userData['national_address'],
      'updated_at': userData['updated_at'],
      if (nafathData != null) 'nafath_data': nafathData,
    };
    
    print('🔒 Initial Registration - Storing in Secure Storage: ${json.encode(secureData)}');
    await secureStorage.write(key: 'user_data', value: json.encode(secureData));

    final registrationData = {
      'national_id': nationalId,
      'email': email,
      'phone': phone,
      'userData': userData,
      if (password != null) 'password': password,
      if (nafathData != null) 'nafath_data': nafathData,
      'registration_timestamp': DateTime.now().toIso8601String(),
    };
    print('📝 Initial Registration - Storing in SharedPreferences: ${json.encode(registrationData)}');
    await prefs.setString('registration_data', json.encode(registrationData));
  }

  // Get stored registration data
  Future<Map<String, dynamic>?> getStoredRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('registration_data');
    if (storedData != null) {
      print('📊 Stored registration data: ${json.decode(storedData)}');
      return json.decode(storedData);
    }
    print('❌ No stored registration data found');
    return null;
  }

  // Clear registration data
  Future<void> clearRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('registration_data');
    print('🚮 Registration data cleared');
  }

  Future<bool> completeRegistration({
    required String nationalId,
    required String password,
    required String mpin,
    required bool enableBiometric,
  }) async {
    try {
      print('🔒 Starting complete registration...');
      
      // Get stored registration data for email and phone
      final storedData = await getStoredRegistrationData();
      if (storedData == null) {
        print('❌ Stored registration data not found');
        return false;
      }

      // Get government data for name and arabic_name
      final govData = await getGovernmentData(nationalId);
      if (govData['status'] != 'success' || govData['data'] == null) {
        print('❌ Failed to get government data: ${govData['message']}');
        return false;
      }

      final userData = govData['data'];
      if (userData['englishFirstName'] == null || userData['englishLastName'] == null) {
        print('❌ Missing required user data from government service');
        return false;
      }

      final deviceInfo = await _getDeviceInfo();
      print('📱 Device Info: $deviceInfo');

      final requestBody = {
        'NationalId': nationalId,
        'DeviceInfo': deviceInfo,
        // Required Name fields (English)
        'FirstNameEn': userData['englishFirstName'],
        'SecondNameEn': userData['englishSecondName'] ?? '',
        'ThirdNameEn': userData['englishThirdName'] ?? '',
        'FamilyNameEn': userData['englishLastName'],
        // Required Name fields (Arabic)
        'FirstNameAr': userData['firstName'],
        'SecondNameAr': userData['fatherName'] ?? '',
        'ThirdNameAr': userData['grandFatherName'] ?? '',
        'FamilyNameAr': userData['familyName'],
        // Required fields
        'Email': storedData['email'],  // Required, no null fallback
        'Phone': storedData['phone'],  // Required, no null fallback
        'Password': password,
        // Optional fields
        'DateOfBirth': userData['dateOfBirth'],
        'IdExpiryDate': userData['idExpiryDate'],
        'Mpin': mpin,
        'MpinEnabled': enableBiometric,
        'RegistrationDate': DateTime.now().toIso8601String(),
        'Consent': true,
        'ConsentDate': DateTime.now().toIso8601String(),
      };

      print('📝 Preparing registration request...');
      print('📤 Request Body: ${json.encode(requestBody)}');

      // Validate required fields
      final requiredFields = ['NationalId', 'FirstNameEn', 'FamilyNameEn', 'FirstNameAr', 'FamilyNameAr', 'Email', 'Phone', 'Password'];
      for (final field in requiredFields) {
        if (requestBody[field] == null || requestBody[field].toString().isEmpty) {
          final error = 'Required field $field is missing or empty';
          print('❌ Validation Error: $error');
          throw Exception(error);
        }
        print('✅ Field $field is valid: ${requestBody[field]}');
      }

      print('🌐 Registration Endpoint: ${Constants.apiBaseUrl}${Constants.endpointRegistration}');
      print('📤 Request Headers: ${json.encode({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': Constants.apiKey
      })}');

      final client = http.Client();
      try {
        // Try up to 3 times with exponential backoff
        for (int i = 0; i < 3; i++) {
          try {
            final response = await client.post(
              Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegistration}'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-API-Key': Constants.apiKey
              },
              body: json.encode(requestBody),
            ).timeout(const Duration(seconds: 30)); // 30 second timeout

            print('📥 Response Status: ${response.statusCode}');
            print('📥 Response Body: ${response.body}');

            if (response.statusCode == 200) {
              print('✅ Registration successful!');
              return true;
            }
            
            // Add more detailed error information
            if (response.statusCode == 400) {
              final errorResponse = json.decode(response.body);
              print('❌ Registration Error: ${errorResponse['error'] ?? 'Failed to complete registration'}');
              return false;
            }
            
            // If we get here, it's a 500 error or other server error
            print('❌ Registration request failed (Attempt ${i + 1}/3). Retrying in ${(i + 1) * 2} seconds...');
            if (i < 2) { // Don't delay on the last attempt
              await Future.delayed(Duration(seconds: (i + 1) * 2)); // 2s, 4s, 6s
            }
          } catch (e) {
            print('❌ Registration request failed: $e');
            if (i < 2) { // Don't delay on the last attempt
              await Future.delayed(Duration(seconds: (i + 1) * 2)); // 2s, 4s, 6s
            }
          }
        }
        return false;
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Error completing registration: $e');
      return false;
    }
  }
}
