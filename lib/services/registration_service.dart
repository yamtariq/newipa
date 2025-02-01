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
      print('Checking if ID already registered...');
      
      // Get device info
      final deviceInfo = await _getDeviceInfo();
      
      // First, check if ID is already registered
      final checkResponse = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/Registration/register'),
        headers: Constants.defaultHeaders,
        body: json.encode({
          'checkOnly': true,
          'nationalId': id,
          'deviceInfo': deviceInfo
        }),
      );

      print('Check registration response: ${checkResponse.statusCode}');
      print('Check registration body: ${checkResponse.body}');

      if (checkResponse.statusCode == 200) {
        final checkResult = json.decode(checkResponse.body);
        
        // If user is already registered
        if (checkResult['isRegistered'] == true) {
          return {
            'status': 'error',
            'message': 'This ID is already registered'
          };
        }
        
        // If not registered, proceed with validation
        return {
          'status': 'success',
          'message': 'ID is valid and not registered'
        };
      }
      
      // Add more detailed error information
      if (checkResponse.statusCode == 400) {
        final errorResponse = json.decode(checkResponse.body);
        return {
          'status': 'error',
          'message': errorResponse['error'] ?? 'Failed to validate identity',
          'details': 'Status code: ${checkResponse.statusCode}, Body: ${checkResponse.body}'
        };
      }
      
      return {
        'status': 'error',
        'message': 'Failed to validate identity. Please try again later.',
        'details': 'Status code: ${checkResponse.statusCode}'
      };
    } catch (e) {
      print('Error validating identity: $e');
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
      print('URL: $url');
      
      // Format phone number: Add 966 prefix and remove any existing prefix
      final formattedPhone = mobileNo != null 
          ? '966${mobileNo.replaceAll('+', '').replaceAll('966', '')}'
          : '';
      
      final headers = Constants.defaultHeaders;
      print('Headers: $headers');
      
      final requestBody = Constants.otpGenerateRequestBody(nationalId, formattedPhone);
      print('Request Body: ${json.encode(requestBody)}');

      // Create a client that follows redirects
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(requestBody),
        );

        print('\n=== GENERATE OTP RESPONSE ===');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Parsed Response Data: $data');
          
          if (data['success'] == true) {
            print('OTP Generation Successful');
            final successResponse = {
              'status': 'success',
              'message': 'OTP sent successfully',
              'message_ar': 'تم إرسال رمز التحقق بنجاح',
              'data': data['result']
            };
            print('Returning Success Response: $successResponse');
            return successResponse;
          }
          
          print('OTP Generation Failed with Error: ${data['message']}');
          final errorResponse = {
            'status': 'error',
            'message': data['message'] ?? 'Failed to generate OTP',
            'message_ar': 'فشل في إرسال رمز التحقق'
          };
          print('Returning Error Response: $errorResponse');
          return errorResponse;
        }

        print('HTTP Request Failed with Status: ${response.statusCode}');
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
      print('Error: $e');
      print('Stack Trace: $stackTrace');
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
      print('URL: $url');
      
      final headers = Constants.defaultHeaders;
      print('Headers: $headers');
      
      final requestBody = Constants.otpVerifyRequestBody(nationalId, otpCode);
      print('Request Body: ${json.encode(requestBody)}');

      // Create a client that follows redirects
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(requestBody),
        );

        print('\n=== VERIFY OTP RESPONSE ===');
        print('Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Parsed Response Data: $data');
          
          if (data['success'] == true) {
            print('OTP Verification Successful');
            final successResponse = {
              'status': 'success',
              'message': 'OTP verified successfully',
              'message_ar': 'تم التحقق من رمز التحقق بنجاح',
              'data': data['result']
            };
            print('Returning Success Response: $successResponse');
            return successResponse;
          }
          
          print('OTP Verification Failed with Error: ${data['message']}');
          final errorResponse = {
            'status': 'error',
            'message': data['message'] ?? 'Failed to verify OTP',
            'message_ar': 'فشل في التحقق من رمز التحقق'
          };
          print('Returning Error Response: $errorResponse');
          return errorResponse;
        }

        print('HTTP Request Failed with Status: ${response.statusCode}');
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
      print('Error: $e');
      print('Stack Trace: $stackTrace');
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
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSetPassword}'),
        headers: Constants.defaultHeaders,
        body: json.encode({
          'national_id': id,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': 'error',
        'message': 'Failed to set password'
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Set MPIN
  Future<Map<String, dynamic>> setMPIN(String id, String mpin) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSetQuickAccessPin}'),
        headers: Constants.defaultHeaders,
        body: json.encode({
          'national_id': id,
          'mpin': mpin,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': 'error',
        'message': 'Failed to set MPIN'
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Check if user is already registered
  Future<Map<String, dynamic>> checkRegistration(String nationalId) async {
    try {
      final url = Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegistration}');
      
      // Get device info for the request
      final deviceInfo = await _getDeviceInfo();

      final requestBody = {
        'checkOnly': true,
        'nationalId': nationalId,
        'deviceInfo': deviceInfo
      };

      print('Registration Check URL: $url');
      print('Registration Check Headers: ${Constants.defaultHeaders}');
      print('Registration Check Body: ${json.encode(requestBody)}');

      final response = await http.post(
        url,
        headers: Constants.defaultHeaders,
        body: json.encode(requestBody),
      );

      print('Registration Check Status Code: ${response.statusCode}');
      print('Registration Check Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      // Add more detailed error information
      if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        return {
          'status': 'error',
          'message': errorResponse['error'] ?? 'ID already registered',
          'details': 'Status code: ${response.statusCode}, Body: ${response.body}'
        };
      }
      
      return {
        'status': 'error',
        'message': 'Failed to check registration',
        'details': 'Status code: ${response.statusCode}, Body: ${response.body}'
      };
    } catch (e) {
      print('Registration Check Error: $e');
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
      print('National ID: $nationalId');
      print('URL: ${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}'),
        headers: Constants.defaultHeaders,
        body: json.encode({
          'iqamaNumber': nationalId,
          'dateOfBirthHijri': dateOfBirthHijri ?? '1398-07-01',
          'idExpiryDate': idExpiryDate ?? '1-1-1'
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'data': json.decode(response.body)
        };
      }

      return {
        'status': 'error',
        'message': 'Failed to get government data'
      };
    } catch (e) {
      print('Error getting government data: $e');
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
    
    print('Initial Registration - Storing in Secure Storage: ${json.encode(secureData)}');
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
    print('Initial Registration - Storing in SharedPreferences: ${json.encode(registrationData)}');
    await prefs.setString('registration_data', json.encode(registrationData));
  }

  // Get stored registration data
  Future<Map<String, dynamic>?> getStoredRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('registration_data');
    if (storedData != null) {
      return json.decode(storedData);
    }
    return null;
  }

  // Clear registration data
  Future<void> clearRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('registration_data');
  }

  Future<bool> completeRegistration({
    required String nationalId,
    required String password,
    required String mpin,
    required bool enableBiometric,
  }) async {
    try {
      print('Starting complete registration...');
      
      // Get stored registration data for email and phone
      final storedData = await getStoredRegistrationData();
      if (storedData == null) {
        print('Stored registration data not found');
        return false;
      }

      // Get government data for name and arabic_name
      final govData = await getGovernmentData(nationalId);
      if (govData['status'] != 'success' || govData['data'] == null) {
        print('Failed to get government data: ${govData['message']}');
        return false;
      }

      final userData = govData['data'];
      if (userData['first_name'] == null || userData['last_name'] == null) {
        print('Missing required user data from government service');
        return false;
      }

      final deviceInfo = await _getDeviceInfo();
      final requestBody = {
        'nationalId': nationalId,
        'name': '${userData['first_name']} ${userData['last_name']}',
        'arabicName': '${userData['first_name_ar']} ${userData['last_name_ar']}',
        'email': storedData['email'] ?? '',
        'password': password,
        'phone': storedData['phone'] ?? '',
        'dateOfBirth': userData['date_of_birth_hijri'],
        'deviceInfo': deviceInfo,
        'checkOnly': false
      };

      print('Registration request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/Registration/register'),
        headers: Constants.defaultHeaders,
        body: json.encode(requestBody),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error completing registration: $e');
      return false;
    }
  }
}
