import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/registration/registration_constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import 'dart:io';

class RegistrationService {
  // Check if user exists and validate identity
  Future<Map<String, dynamic>> validateIdentity(String id, String phone) async {
    HttpClient? client;
    try {
      print('🚀 Checking if ID already registered...');
      
      // Get device info
      final deviceInfo = await _getDeviceInfo();
      print('📱 Device Info: $deviceInfo');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.authBaseUrl}/signin'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      request.headers.add('x-api-key', Constants.apiKey);
      request.write(json.encode({
        'nationalId': id,
        'deviceId': deviceInfo['deviceId']
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Check registration response: ${response.statusCode}');
      print('📥 Check registration body: $responseBody');

      if (response.statusCode == 401) {
        final errorResponse = json.decode(responseBody);
        if (errorResponse['details']?['code'] == 'CUSTOMER_NOT_FOUND') {
          print('✅ ID is valid and not registered');
          return {
            'status': 'success',
            'message': 'ID is valid and not registered'
          };
        }
      }
      
      print('❌ This ID is already registered');
      return {
        'status': 'error',
        'message': 'This ID is already registered'
      };
    } catch (e) {
      print('❌ Error validating identity: $e');
      return {
        'status': 'error',
        'message': 'Connection error. Please check your internet connection.'
      };
    } finally {
      client?.close();
    }
  }

  // Generate OTP
  Future<Map<String, dynamic>> generateOTP(String nationalId, {String? mobileNo}) async {
    HttpClient? client;
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      // Format phone number: Add 966 prefix and remove any existing prefix
      final formattedPhone = mobileNo != null 
          ? '966${mobileNo.replaceAll('+', '').replaceAll('966', '')}'
          : '';
      
      final uri = Uri.parse(Constants.proxyOtpGenerateUrl);
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      final requestBody = Constants.otpGenerateRequestBody(
        nationalId, 
        formattedPhone,
        purpose: 'Registration'
      );
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n=== GENERATE OTP RESPONSE ===');
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
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
      client?.close();
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String nationalId, String otp) async {
    HttpClient? client;
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final uri = Uri.parse(Constants.proxyOtpVerifyUrl);
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      final requestBody = Constants.otpVerifyRequestBody(nationalId, otp);
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\n=== VERIFY OTP RESPONSE ===');
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
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
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'message_ar': 'حدث خطأ أثناء التحقق من رمز التحقق'
      };
    } finally {
      client?.close();
    }
  }

  // Set password
  Future<Map<String, dynamic>> setPassword(String id, String password) async {
    HttpClient? client;
    try {
      print('🔒 Setting password...');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSetPassword}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      request.headers.add('x-api-key', Constants.apiKey);
      
      request.write(json.encode({
        'national_id': id,
        'password': password,
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Password set successfully');
        return json.decode(responseBody);
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
    } finally {
      client?.close();
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
    HttpClient? client;
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

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      request.headers.add('x-api-key', Constants.apiKey);
      request.write(json.encode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        print('✅ User is not registered');
        return json.decode(responseBody);
      }
      
      // Add more detailed error information
      if (response.statusCode == 400) {
        final errorResponse = json.decode(responseBody);
        print('❌ Error: ${errorResponse['error'] ?? 'ID already registered'}');
        return {
          'status': 'error',
          'message': errorResponse['error'] ?? 'ID already registered',
          'details': 'Status code: ${response.statusCode}, Body: $responseBody'
        };
      }
      
      print('❌ Failed to check registration');
      return {
        'status': 'error',
        'message': 'Failed to check registration',
        'details': 'Status code: ${response.statusCode}, Body: $responseBody'
      };
    } catch (e) {
      print('❌ Registration Check Error: $e');
      return {'status': 'error', 'message': e.toString()};
    } finally {
      client?.close();
    }
  }

  // Get government data
  Future<Map<String, dynamic>> getGovernmentData(String nationalId, {
    String? dateOfBirthHijri,
    String? idExpiryDate,
  }) async {
    HttpClient? client;
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      print('\n=== GETTING GOVERNMENT DATA ===');
      print('🔍 National ID: $nationalId');
      print('🔍 Date of Birth Hijri: ${dateOfBirthHijri ?? '1398-07-01'}');
      print('🔍 ID Expiry Date: ${idExpiryDate ?? '1-1-1'}');
      print('🌐 URL: ${Constants.endpointGetGovernmentData}');

      final requestBody = {
        'iqamaNumber': nationalId,
        'dateOfBirthHijri': dateOfBirthHijri?.replaceAll(' هـ', '').replaceAll('/', '-') ?? '1398-07-01',
        'idExpiryDate': idExpiryDate?.replaceAll(' هـ', '').replaceAll('/', '-') ?? '1-1-1'
      };
      print('📤 Request Body: ${json.encode(requestBody)}');
      print('📤 Request Headers: ${Constants.defaultHeaders}');

      final uri = Uri.parse('${Constants.endpointGetGovernmentData}');
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        print('✅ Government data retrieved successfully');
        return {
          'status': 'success',
          'data': json.decode(responseBody)
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
    } finally {
      client?.close();
    }
  }

  // Get government address data
  Future<Map<String, dynamic>> getGovernmentAddress(String nationalId, {
    String? dateOfBirthHijri,
    String addressLanguage = 'ar',
  }) async {
    HttpClient? client;
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      print('\n=== GETTING GOVERNMENT ADDRESS DATA ===');
      print('🔍 National ID: $nationalId');
      print('🔍 Date of Birth Hijri: ${dateOfBirthHijri ?? '1398-07-01'}');
      print('🔍 Address Language: $addressLanguage');
      print('🌐 URL: ${Constants.endpointGetGovernmentAddress}');

      final requestBody = {
        'iqamaNumber': nationalId,
        'dateOfBirthHijri': dateOfBirthHijri?.replaceAll(' هـ', '').replaceAll('/', '-') ?? '1398-07-01',
        'addressLanguage': addressLanguage
      };
      print('📤 Request Body: ${json.encode(requestBody)}');
      print('📤 Request Headers: ${Constants.defaultHeaders}');

      final uri = Uri.parse('${Constants.endpointGetGovernmentAddress}');
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        print('✅ Government address data retrieved successfully');
        return {
          'status': 'success',
          'data': json.decode(responseBody)
        };
      }

      print('❌ Failed to get government address data');
      return {
        'status': 'error',
        'message': 'Failed to get government address data'
      };
    } catch (e) {
      print('❌ Error getting government address data: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    } finally {
      client?.close();
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
    Map<String, dynamic>? addressData,
    String? password,
    Map<String, dynamic>? nafathData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage();
    
    final secureData = {
      'national_id': nationalId,
      'full_name': '${userData['englishFirstName']} ${userData['englishLastName']}',
      'arabic_name': '${userData['firstName']} ${userData['familyName']}',
      'email': email,
      'dob': userData['dateOfBirth'],
      'salary': userData['salary'],
      'employment_status': userData['employmentStatus'],
      'employer_name': userData['employerName'],
      'employment_date': userData['employmentDate'],
      'national_address': addressData?['citizenaddresslists']?[0] ?? userData['nationalAddress'],
      'updated_at': DateTime.now().toIso8601String(),
      if (nafathData != null) 'nafath_data': nafathData,
    };
    
    print('🔒 Initial Registration - Storing in Secure Storage: ${json.encode(secureData)}');
    await secureStorage.write(key: 'user_data', value: json.encode(secureData));

    final registrationData = {
      'national_id': nationalId,
      'email': email,
      'phone': '966' + phone,
      'userData': userData,
      if (addressData != null) 'addressData': addressData,
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
    HttpClient? client;
    try {
      print('🔒 Starting complete registration...');
      
      // Get stored registration data for email and phone
      final storedData = await getStoredRegistrationData();
      if (storedData == null) {
        print('❌ Stored registration data not found');
        return false;
      }

      // 💡 Use stored government data instead of making a new API call
      final userData = storedData['userData'];
      if (userData == null || 
          userData['englishFirstName'] == null || 
          userData['englishLastName'] == null) {
        print('❌ Missing required user data from stored data');
        return false;
      }

      final deviceInfo = await _getDeviceInfo();
      print('📱 Device Info: $deviceInfo');

      // 💡 Format dates to match API requirements (yyyy-MM-dd)
      String formatDate(String? hijriDate) {
        if (hijriDate == null) return '';
        // Convert from dd-MM-yyyy to yyyy-MM-dd
        final parts = hijriDate.split('-');
        if (parts.length != 3) return hijriDate;
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }

      // 💡 Format phone number (ensure it starts with 966 and no +)
      String formatPhone(String phone) {
        phone = phone.replaceAll('+', '').replaceAll(' ', '');
        if (!phone.startsWith('966')) {
          phone = '966${phone.startsWith('0') ? phone.substring(1) : phone}';
        }
        return phone;
      }

      // 💡 Format the request according to API requirements
      final registrationRequest = {
        "nationalId": nationalId.trim(),
        "firstNameEn": (userData['englishFirstName'] as String).trim().toUpperCase(),
        "secondNameEn": (userData['englishSecondName'] as String? ?? '').trim().toUpperCase(),
        "thirdNameEn": (userData['englishThirdName'] as String? ?? '').trim().toUpperCase(),
        "familyNameEn": (userData['englishLastName'] as String).trim().toUpperCase(),
        "firstNameAr": (userData['firstName'] as String).trim(),
        "secondNameAr": (userData['fatherName'] as String? ?? '').trim(),
        "thirdNameAr": (userData['grandFatherName'] as String? ?? '').trim(),
        "familyNameAr": (userData['familyName'] as String).trim(),
        "email": (storedData['email'] as String).trim().toLowerCase(),
        "phone": formatPhone(storedData['phone'] as String),
        "password": password,
        "dateOfBirth": formatDate(userData['dateOfBirth']),
        "idExpiryDate": formatDate(userData['idExpiryDate']),
        "mpin": mpin,
        "mpinEnabled": enableBiometric,
        "registrationDate": DateTime.now().toIso8601String(),
        "consent": true,
        "consentDate": DateTime.now().toIso8601String(),
        "Dependents": userData['totalNumberOfCurrentDependents'] as int? ?? 0,
        "deviceInfo": {
          "deviceId": deviceInfo['deviceId'],
          "platform": deviceInfo['platform'],
          "model": deviceInfo['model'],
          "manufacturer": deviceInfo['manufacturer']
        }
      };

      print('📝 Preparing registration request...');
      print('📤 Request Body: ${json.encode(registrationRequest)}');

      // Validate required fields
      final requiredFields = [
        'nationalId', 'firstNameEn', 'familyNameEn', 'firstNameAr', 
        'familyNameAr', 'email', 'phone', 'password'
      ];
      
      for (final field in requiredFields) {
        if (registrationRequest[field] == null || registrationRequest[field].toString().trim().isEmpty) {
          final error = 'Required field $field is missing or empty';
          print('❌ Validation Error: $error');
          throw Exception(error);
        }
        print('✅ Field $field is valid: ${registrationRequest[field]}');
      }

      // 💡 Additional validations
      final email = registrationRequest['email'] as String;
      if (!email.contains('@') || !email.contains('.')) {
        print('❌ Invalid email format: $email');
        return false;
      }

      final phone = registrationRequest['phone'] as String;
      if (!phone.startsWith('966') || phone.length != 12) {
        print('❌ Invalid phone format: $phone');
        return false;
      }

      print('🌐 Registration Endpoint: ${Constants.apiBaseUrl}${Constants.endpointRegistration}');
      print('📤 Request Headers: ${json.encode({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': Constants.apiKey
      })}');

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      // Try up to 3 times with exponential backoff
      for (int i = 0; i < 3; i++) {
        try {
          final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegistration}'));
          request.headers.contentType = ContentType.json;
          request.headers.add('Accept', 'application/json');
          request.headers.add('x-api-key', Constants.apiKey);
          request.write(json.encode(registrationRequest));
          
          final response = await request.close().timeout(const Duration(seconds: 30));
          final responseBody = await response.transform(utf8.decoder).join();

          print('📥 Response Status: ${response.statusCode}');
          print('📥 Response Body: $responseBody');

          if (response.statusCode == 200) {
            print('✅ Registration successful!');
            return true;
          }
          
          // Add more detailed error information
          if (response.statusCode == 400) {
            final errorResponse = json.decode(responseBody);
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
    } catch (e) {
      print('❌ Error completing registration: $e');
      return false;
    } finally {
      client?.close();
    }
  }

  // 💡 Get expat info from Yakeen API
  Future<Map<String, dynamic>> getExpatInfo(String iqamaNumber, String sponsorId) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      print('\n=== GETTING EXPAT INFO ===');
      print('🔍 IQAMA Number: $iqamaNumber');
      print('🔍 Sponsor ID: $sponsorId');
      print('🌐 URL: ${Constants.endpointGetAlienInfo}');

      final requestBody = {
        'iqamaNumber': iqamaNumber,
        'sponsorID': sponsorId
      };
      print('📤 Request Body: ${json.encode(requestBody)}');

      final uri = Uri.parse('${Constants.endpointGetAlienInfo}');
      final request = await client.postUrl(uri);
      
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        print('✅ Expat info retrieved successfully');
        return {
          'status': 'success',
          'data': json.decode(responseBody)
        };
      }

      print('❌ Failed to get expat info');
      return {
        'status': 'error',
        'message': 'Failed to get expat info'
      };

    } catch (e) {
      print('❌ Error getting expat info: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    } finally {
      client?.close();
    }
  }

  // 💡 Get expat address from Yakeen API
  Future<Map<String, dynamic>> getExpatAddress(String iqamaNumber, String dateOfBirthHijri, {String addressLanguage = 'A'}) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      print('\n=== GETTING EXPAT ADDRESS ===');
      print('🔍 IQAMA Number: $iqamaNumber');
      print('🔍 Date of Birth Hijri: $dateOfBirthHijri');
      print('🔍 Address Language: $addressLanguage');
      print('🌐 URL: ${Constants.endpointGetAlienAddress}');

      final requestBody = {
        'iqamaIDNumber': iqamaNumber,
        'dateOfBirthHijri': dateOfBirthHijri,
        'addressLanguage': addressLanguage
      };
      print('📤 Request Body: ${json.encode(requestBody)}');

      final uri = Uri.parse('${Constants.endpointGetAlienAddress}');
      final request = await client.postUrl(uri);
      
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: $responseBody');

      if (response.statusCode == 200) {
        print('✅ Expat address retrieved successfully');
        return {
          'status': 'success',
          'data': json.decode(responseBody)
        };
      }

      print('❌ Failed to get expat address');
      return {
        'status': 'error',
        'message': 'Failed to get expat address'
      };

    } catch (e) {
      print('❌ Error getting expat address: $e');
      return {
        'status': 'error',
        'message': e.toString()
      };
    } finally {
      client?.close();
    }
  }

  // 💡 Store registration data in local storage only
  Future<void> saveRegistrationDataLocally({
    required String nationalId,
    required String email,
    required String phone,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? addressData,
    String? password,
    Map<String, dynamic>? nafathData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage();
    
    final secureData = {
      'national_id': nationalId,
      'full_name': '${userData['englishFirstName']} ${userData['englishLastName']}',
      'arabic_name': '${userData['firstName']} ${userData['familyName']}',
      'email': email,
      'dob': userData['dateOfBirth'],
      'salary': userData['salary'],
      'employment_status': userData['employmentStatus'],
      'employer_name': userData['employerName'],
      'employment_date': userData['employmentDate'],
      'national_address': addressData?['citizenaddresslists']?[0] ?? userData['nationalAddress'],
      'updated_at': DateTime.now().toIso8601String(),
      if (nafathData != null) 'nafath_data': nafathData,
    };
    
    print('🔒 Storing in Secure Storage: ${json.encode(secureData)}');
    await secureStorage.write(key: 'user_data', value: json.encode(secureData));

    final registrationData = {
      'national_id': nationalId,
      'email': email,
      'phone': '966' + phone,
      'userData': userData,
      if (addressData != null) 'addressData': addressData,
      if (password != null) 'password': password,
      if (nafathData != null) 'nafath_data': nafathData,
      'registration_timestamp': DateTime.now().toIso8601String(),
    };
    print('📝 Storing in SharedPreferences: ${json.encode(registrationData)}');
    await prefs.setString('registration_data', json.encode(registrationData));
  }
}
