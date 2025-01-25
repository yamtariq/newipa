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
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointValidateIdentity}'),
        headers: Constants.authHeaders,
        body: json.encode({
          'id': id,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Failed to validate identity'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Generate OTP
  Future<Map<String, dynamic>> generateOTP(String nationalId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}'),
        headers: Constants.authFormHeaders,
        body: {
          'national_id': nationalId,
        },
      );

      print('OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': 'error',
        'message': 'Failed to generate OTP',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(
      String nationalId, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPVerification}'),
        headers: Constants.authFormHeaders,
        body: {
          'national_id': nationalId.trim(),
          'otp_code': otpCode.trim(),
        },
      );

      print('Verify OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': 'error',
        'message': 'Failed to verify OTP',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Set password
  Future<Map<String, dynamic>> setPassword(String id, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointSetPassword}'),
        headers: Constants.authHeaders,
        body: json.encode({
          'id': id,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Failed to set password'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Set MPIN
  Future<Map<String, dynamic>> setMPIN(String id, String mpin) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointSetQuickAccessPin}'),
        headers: Constants.authHeaders,
        body: json.encode({
          'id': id,
          'mpin': mpin,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Failed to set MPIN'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Check if user is already registered
  Future<Map<String, dynamic>> checkRegistration(String nationalId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'),
        headers: Constants.userHeaders,
        body: json.encode({
          'national_id': nationalId,
          'check_only': true
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Failed to check registration'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Get government data
  Future<Map<String, dynamic>> getGovernmentData(String nationalId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}?national_id=$nationalId'),
        headers: Constants.userHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Failed to get government data'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
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
      if (userData['full_name'] == null || userData['arabic_name'] == null) {
        print('Missing required user data from government service');
        return false;
      }

      // Merge the stored email with government data
      userData['email'] = storedData['email'];

      final deviceInfo = await _getDeviceInfo();
      final requestBody = {
        'national_id': nationalId,
        'name': userData['full_name'],
        'arabic_name': userData['arabic_name'],
        'email': storedData['email'] ?? '',
        'password': password,
        'phone': storedData['phone'] ?? '',
        'dob': userData['dob'],
        'salary': userData['salary'],
        'employment_status': userData['employment_status'],
        'employer_name': userData['employer_name'],
        'employment_date': userData['employment_date'],
        'national_address': userData['national_address'],
        'device_info': deviceInfo,
        // Add Nafath data if available
        if (storedData['nafath_data'] != null) ...{
          'nafath_status': 'COMPLETED',
          'nafath_trans_id': storedData['nafath_data']['transId'],
          'nafath_random': storedData['nafath_data']['random'],
        },
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'),
        headers: Constants.userHeaders,
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Store MPIN and biometric settings locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_mpin', mpin);
          await prefs.setBool('biometric_enabled', enableBiometric);
          await prefs.setString('user_id', nationalId);

          print('Complete Registration - Storing MPIN and settings:');
          print(' - MPIN stored');
          print(' - Biometric enabled: $enableBiometric');
          print(' - User ID stored: $nationalId');

          // Initialize secure storage and store the complete user data
          final secureStorage = const FlutterSecureStorage();
          
          // Get the response user data and ensure email is included
          final responseUserData = responseData['data'] ?? userData;
          final finalUserData = {
            ...responseUserData,
            'email': storedData['email'],
            'isSessionActive': true
          };
          
          // Store in both secure storage and SharedPreferences
          print('Complete Registration - Final User Data being stored in Secure Storage: ${json.encode(finalUserData)}');
          await secureStorage.write(key: 'user_data', value: json.encode(finalUserData));
          await prefs.setString('email', storedData['email'] ?? '');

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error completing registration: $e');
      return false;
    }
  }
}
