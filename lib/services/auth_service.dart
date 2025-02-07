import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/constants.dart';

class AuthService {
  // Keep these for backward compatibility, but they now reference Constants
  static String get baseUrl => Constants.apiBaseUrl;
  static String get apiKey => Constants.apiKey;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  Timer? _refreshTimer;
  bool _isSigningIn = false;

  // Get default headers for all requests
  Map<String, String> get _headers => Constants.authHeaders;

  // Store MPIN securely
  Future<void> storeMPIN(String mpin) async {
    try {
      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mpin', mpin);
      
      // Also store in secure storage
      await _secureStorage.write(key: 'mpin', value: mpin);
      
      print('MPIN stored in both SharedPreferences and secure storage');
    } catch (e) {
      print('Error storing MPIN: $e');
      rethrow;
    }
  }

  // Get stored MPIN
  Future<String?> getStoredMPIN() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      String? mpinFromPrefs = prefs.getString('mpin');
      
      if (mpinFromPrefs != null) {
        print('MPIN found in SharedPreferences');
        // Also store in secure storage if not already there
        await _secureStorage.write(key: 'mpin', value: mpinFromPrefs);
        return mpinFromPrefs;
      }
      
      // If not in SharedPreferences, try secure storage
      String? mpinFromSecure = await _secureStorage.read(key: 'mpin');
      if (mpinFromSecure != null) {
        print('MPIN found in secure storage');
        // Store back in SharedPreferences for next time
        await prefs.setString('mpin', mpinFromSecure);
        return mpinFromSecure;
      }
      
      print('MPIN not found in either storage');
      return null;
    } catch (e) {
      print('Error getting MPIN: $e');
      return null;
    }
  }

  // Verify MPIN locally
  Future<bool> verifyMPIN(String mpin) async {
    try {
      print('Starting MPIN verification...');
      
      final storedMPIN = await getStoredMPIN();
      print('MPIN verification - Stored: ${storedMPIN != null ? '******' : 'null'}, Entered: ******');
      
      if (storedMPIN == null) {
        print('No MPIN stored');
        return false;
      }
      
      final isValid = storedMPIN == mpin;
      print('MPIN verification result: ${isValid ? 'valid' : 'invalid'}');
      
      return isValid;
    } catch (e) {
      print('Error verifying MPIN: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Check if MPIN is set
  Future<bool> isMPINSet() async {
    try {
      print('Checking if MPIN is set...');
      
      final storedMPIN = await getStoredMPIN();
      
      print('MPIN status check:');
      print('- MPIN value exists: ${storedMPIN != null}');
      
      final isSet = storedMPIN != null;
      print('MPIN is ${isSet ? 'set up' : 'not set up'}');
      
      return isSet;
    } catch (e) {
      print('Error checking MPIN status: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometrics(String nationalId) async {
    try {
      print('\n=== ENABLING BIOMETRICS ===');
      print('1. Checking biometric availability...');
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        print('Biometrics not available or not supported');
        return false;
      }
      
      print('2. Authenticating user...');
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (didAuthenticate) {
        print('3. Storing biometric data...');
        // Store in secure storage
        await _secureStorage.write(key: 'biometrics_enabled', value: 'true');
        await _secureStorage.write(key: 'biometric_user_id', value: nationalId);
        await _secureStorage.write(key: 'device_user_id', value: nationalId);
        await _secureStorage.write(key: 'device_registered', value: 'true');
        
        // Also store in SharedPreferences for redundancy
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometrics_enabled', true);
        await prefs.setString('biometric_user_id', nationalId);
        await prefs.setString('device_user_id', nationalId);
        await prefs.setBool('device_registered', true);
        
        print('4. Verifying stored data...');
        final storedBiometric = await _secureStorage.read(key: 'biometrics_enabled');
        final storedUserId = await _secureStorage.read(key: 'biometric_user_id');
        print('- Biometrics enabled: $storedBiometric');
        print('- Stored user ID: $storedUserId');
        
        return true;
      }
      print('User did not authenticate successfully');
      return false;
    } catch (e) {
      print('Error enabling biometrics: $e');
      return false;
    }
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      print('\n=== CHECKING BIOMETRIC STATUS ===');
      
      // Check secure storage first
      final biometricEnabled = await _secureStorage.read(key: 'biometrics_enabled');
      final biometricUserId = await _secureStorage.read(key: 'biometric_user_id');
      final deviceUserId = await _secureStorage.read(key: 'device_user_id');
      
      // Also check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsBiometricEnabled = prefs.getBool('biometrics_enabled');
      final prefsBiometricUserId = prefs.getString('biometric_user_id');
      final prefsDeviceUserId = prefs.getString('device_user_id');
      
      print('Biometric Status Check:');
      print('- Secure Storage:');
      print('  - Enabled Flag: $biometricEnabled');
      print('  - Biometric User ID: $biometricUserId');
      print('  - Device User ID: $deviceUserId');
      print('- SharedPreferences:');
      print('  - Enabled Flag: $prefsBiometricEnabled');
      print('  - Biometric User ID: $prefsBiometricUserId');
      print('  - Device User ID: $prefsDeviceUserId');
      
      // If data exists in secure storage, sync it to SharedPreferences
      if (biometricEnabled == 'true' && biometricUserId != null && deviceUserId != null) {
        await prefs.setBool('biometrics_enabled', true);
        await prefs.setString('biometric_user_id', biometricUserId);
        await prefs.setString('device_user_id', deviceUserId);
      }
      // If data exists in SharedPreferences but not in secure storage, sync it back
      else if (prefsBiometricEnabled == true && prefsBiometricUserId != null && prefsDeviceUserId != null) {
        await _secureStorage.write(key: 'biometrics_enabled', value: 'true');
        await _secureStorage.write(key: 'biometric_user_id', value: prefsBiometricUserId);
        await _secureStorage.write(key: 'device_user_id', value: prefsDeviceUserId);
      }
      
      // Check if enabled in either storage
      final isEnabled = (biometricEnabled == 'true' && biometricUserId != null && deviceUserId != null && biometricUserId == deviceUserId) ||
                       (prefsBiometricEnabled == true && prefsBiometricUserId != null && prefsDeviceUserId != null && prefsBiometricUserId == prefsDeviceUserId);
      
      print('Biometrics enabled: $isEnabled');
      print('=== BIOMETRIC STATUS CHECK END ===\n');
      
      return isEnabled;
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  // Remove the old enableBiometric method to avoid confusion
  @deprecated
  Future<void> enableBiometric(String nationalId) async {
    await enableBiometrics(nationalId);
  }

  // Store tokens securely
  Future<void> storeTokens(Map<String, dynamic> tokens) async {
    await _secureStorage.write(
      key: 'access_token',
      value: tokens['access_token'],
    );
    await _secureStorage.write(
      key: 'refresh_token',
      value: tokens['refresh_token'],
    );
    await _secureStorage.write(
      key: 'token_expiry',
      value: (DateTime.now().millisecondsSinceEpoch + (tokens['expires_in'] * 1000)).toString(),
    );

    // Schedule token refresh
    _scheduleTokenRefresh(tokens['expires_in']);
  }

  // Get access token, refresh if needed
  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: 'access_token');
    final expiryStr = await _secureStorage.read(key: 'token_expiry');
    
    if (token == null || expiryStr == null) {
      return null;
    }

    final expiry = int.parse(expiryStr);
    final now = DateTime.now().millisecondsSinceEpoch;

    // If token is expired or about to expire in next 5 minutes
    if (now + (5 * 60 * 1000) >= expiry) {
      return await _refreshToken();
    }

    return token;
  }

  // Refresh access token
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRefreshToken}'),
        headers: Constants.authHeaders,
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        await _secureStorage.write(
          key: 'access_token',
          value: data['access_token'],
        );
        await _secureStorage.write(
          key: 'token_expiry',
          value: (DateTime.now().millisecondsSinceEpoch + (data['expires_in'] * 1000)).toString(),
        );

        _scheduleTokenRefresh(data['expires_in']);
        return data['access_token'];
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return null;
  }

  // Schedule token refresh
  void _scheduleTokenRefresh(int expiresIn) {
    _refreshTimer?.cancel();
    
    // Refresh 5 minutes before expiry
    final refreshIn = expiresIn - (5 * 60);
    if (refreshIn > 0) {
      _refreshTimer = Timer(Duration(seconds: refreshIn), () async {
        await _refreshToken();
      });
    }
  }

  // Core sign-in method
  Future<Map<String, dynamic>> signIn({
    required String nationalId,
    String? password,
    bool isQuickSignIn = false,
  }) async {
    try {
      _isSigningIn = true;
      
      print('\n=== SIGN IN PROCESS START ===');
      print('Step 1: Initial Parameters');
      print('- National ID: $nationalId');
      print('- Sign in type: ${isQuickSignIn ? 'Quick Sign In' : 'Password Sign In'}');
      print('- Password provided: ${password != null ? 'Yes' : 'No'}');

      print('\nStep 2: Getting Device Info');
      final deviceInfo = await getDeviceInfo();
      print('- Raw Device Info: ${json.encode(deviceInfo)}');
      print('- Device ID: ${deviceInfo['deviceId']}');
      print('- Platform: ${deviceInfo['platform']}');
      print('- Model: ${deviceInfo['model']}');

      print('\nStep 3: Preparing Sign In Request');
      final Map<String, dynamic> requestBody = {
        'nationalId': nationalId,
        'deviceId': deviceInfo['deviceId'],
      };

      if (password != null) {
        requestBody['password'] = password;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': Constants.apiKey,
      };

      print('API Call Details:');
      print('- Endpoint: ${Constants.apiBaseUrl}/auth/signin');
      print('- Headers: ${json.encode(headers)}');
      print('- Request Body: ${json.encode(requestBody)}');

      print('\nStep 4: Making Sign In API Call');
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/auth/signin'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('\nStep 5: Processing Response');
      print('- Status Code: ${response.statusCode}');
      print('- Response Headers: ${response.headers}');
      print('- Raw Response Body: ${response.body}');

      final Map<String, dynamic> parsedResponse = json.decode(response.body);
      print('- Parsed Response: ${json.encode(parsedResponse)}');

      if (parsedResponse['success'] == true && parsedResponse['data'] != null) {
        print('\nStep 6: Successful Sign In');
        print('- Processing user data and tokens');

        // Store tokens immediately
        if (parsedResponse['data']['token'] != null) {
          await _secureStorage.write(
            key: 'auth_token',
            value: parsedResponse['data']['token']
          );
          print('✅ Auth token stored successfully');
        }
        
        if (parsedResponse['data']['refresh_token'] != null) {
          await _secureStorage.write(
            key: 'refresh_token',
            value: parsedResponse['data']['refresh_token']
          );
          print('✅ Refresh token stored successfully');
        }

        // Store session data
        await _secureStorage.write(key: 'session_active', value: 'true');
        if (parsedResponse['data']['user'] != null) {
          final userData = parsedResponse['data']['user'];
          await _secureStorage.write(
            key: 'session_user_id',
            value: userData['id']?.toString() ?? nationalId
          );
        }
        print('✅ Session data stored');

        // Verify token storage
        final storedToken = await _secureStorage.read(key: 'auth_token');
        print('Token verification:');
        print('- Token exists: ${storedToken != null}');
        if (storedToken != null) {
          print('- Token length: ${storedToken.length}');
          print('- First 10 chars: ${storedToken.substring(0, 10)}...');
        }

        final responseData = parsedResponse['data'];
        final userData = responseData['user'];

        if (userData != null) {
          print('\n=== DETAILED USER DATA STORAGE LOGGING ===');
          print('1. Original User Data from API:');
          print(json.encode(userData));

          // Store user data in both secure storage and shared preferences
          final userDataToStore = {
            ...userData,
            'name': userData['name'] ?? '', // Ensure name is stored
            'full_name': userData['name'] ?? '', // Store name as full_name for consistency
            'firstName': userData['name']?.toString().split(' ').firstOrNull ?? '', // Extract first name safely
            'lastName': userData['name'] != null && userData['name'].toString().split(' ').length > 1 
                ? userData['name'].toString().split(' ').sublist(1).join(' ')
                : '', // Extract last name safely with null check and preserve full last name
          };

          print('\n3. Enhanced User Data to Store:');
          print(json.encode(userDataToStore));

          final prefs = await SharedPreferences.getInstance();
          
          // Store in SharedPreferences
          await prefs.setString('user_data', json.encode(userDataToStore));
          print('\n4. SharedPreferences Storage:');
          print('- Stored at key: user_data');
          print('- Verification - Retrieved data:');
          print(prefs.getString('user_data'));
          
          // Store in SecureStorage
          await _secureStorage.write(key: 'user_data', value: json.encode(userDataToStore));
          print('\n5. Secure Storage:');
          print('- Stored at key: user_data');
          print('- Verification - Retrieved data:');
          print(await _secureStorage.read(key: 'user_data'));
          
          // Set device registration status
          await prefs.setBool('device_registered', true);
          await prefs.setString('device_user_id', nationalId);
          await _secureStorage.write(key: 'device_registered', value: 'true');
          await _secureStorage.write(key: 'device_user_id', value: nationalId);
          
          print('\n6. Final Storage Check:');
          print('- SharedPreferences user_data exists: ${prefs.getString('user_data') != null}');
          print('- SecureStorage user_data exists: ${(await _secureStorage.read(key: 'user_data')) != null}');
          print('- Device registration status: ${prefs.getBool('device_registered')}');
          print('- Device user ID: ${prefs.getString('device_user_id')}');
          print('=== END DETAILED STORAGE LOGGING ===\n');
        }
      } else {
        print('\nStep 6: Sign In Failed');
        print('- Error Code: ${parsedResponse['code']}');
        print('- Error Message: ${parsedResponse['message']}');
      }

      print('\n=== SIGN IN PROCESS END ===');
      return parsedResponse;
    } catch (e, stackTrace) {
      print('\n!!! ERROR IN SIGN IN PROCESS !!!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _isSigningIn = false;
    }
  }

  // Register device with detailed logging
  Future<Map<String, dynamic>> registerDevice({
    required String nationalId,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      print('\n=== DEVICE REGISTRATION START ===');
      print('Step 1: Initial Parameters');
      print('- National ID: $nationalId');
      print('- Device Info: ${json.encode(deviceInfo)}');

      print('\nStep 2: Preparing Request');
      final requestBody = {
        'nationalId': nationalId,
        'deviceId': deviceInfo['deviceId'],
        'platform': deviceInfo['platform'],
        'model': deviceInfo['model'],
        'manufacturer': deviceInfo['manufacturer']
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': Constants.apiKey,
      };

      print('API Call Details:');
      print('- Endpoint: ${Constants.apiBaseUrl}/device');
      print('- Headers: ${json.encode(headers)}');
      print('- Request Body: ${json.encode(requestBody)}');

      print('\nStep 3: Making API Call');
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/device'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('\nStep 4: Processing Response');
      print('- Status Code: ${response.statusCode}');
      print('- Response Headers: ${response.headers}');
      print('- Raw Response Body: ${response.body}');

      final parsedResponse = json.decode(response.body);
      print('- Parsed Response: ${json.encode(parsedResponse)}');

      print('\n=== DEVICE REGISTRATION END ===');
      
      // Ensure we always return a success boolean
      return {
        'success': parsedResponse['success'] ?? false,
        ...parsedResponse,
      };
    } catch (e, stackTrace) {
      print('\n!!! ERROR IN DEVICE REGISTRATION !!!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final Map<String, dynamic> info = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['deviceId'] = androidInfo.id;
        info['platform'] = 'android';
        info['model'] = androidInfo.model;
        info['manufacturer'] = androidInfo.manufacturer;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['deviceId'] = iosInfo.identifierForVendor;
        info['platform'] = 'ios';
        info['model'] = iosInfo.model;
        info['manufacturer'] = 'Apple';
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return info;
  }

  // Store device registration data
  Future<void> storeDeviceRegistration(String nationalId) async {
    try {
      await _secureStorage.write(key: 'device_user_id', value: nationalId);
      await _secureStorage.write(key: 'device_registered', value: 'true');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_user_id', nationalId);
      await prefs.setBool('device_registered', true);
      
      print('Device registration stored for user: $nationalId');
    } catch (e) {
      print('Error storing device registration: $e');
      throw Exception('Error storing device registration: $e');
    }
  }

  // Check if device is registered (for quick sign-in methods)
  Future<bool> isDeviceRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool('device_registered') ?? false;
      final deviceUserId = prefs.getString('device_user_id');
      return isRegistered && deviceUserId != null;
    } catch (e) {
      print('Error checking device registration: $e');
      return false;
    }
  }

  // Check if device is registered to specific user (for quick sign-in methods)
  Future<bool> isDeviceRegisteredToUser(String nationalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('device_user_id');
      final isRegistered = prefs.getBool('device_registered') ?? false;
      return isRegistered && storedUserId == nationalId;
    } catch (e) {
      print('Error checking device registration: $e');
      return false;
    }
  }

  // MPIN-based login
  Future<Map<String, dynamic>> loginWithMPIN({
    required String nationalId,
    required String mpin,
  }) async {
    try {
      print('Starting MPIN login process...');
      
      // First verify MPIN locally
      final isMPINValid = await verifyMPIN(mpin);
      if (!isMPINValid) {
        print('Local MPIN verification failed');
        return {
          'success': false,
          'error': 'INVALID_MPIN',
          'message': 'Invalid MPIN',
          'message_ar': 'رمز الدخول غير صحيح'
        };
      }
      
      print('Local MPIN verification successful');

      // Set up session after successful MPIN verification
      await _secureStorage.write(key: 'session_active', value: 'true');
      await _secureStorage.write(key: 'session_user_id', value: nationalId);
      await _secureStorage.write(key: 'national_id', value: nationalId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_active', true);
      await prefs.setString('session_user_id', nationalId);
      await prefs.setString('national_id', nationalId);
      
      // Start session management
      await startSession(nationalId);
      
      print('Session data stored successfully');
      print('- Session active: true');
      print('- User ID: $nationalId');
      
      // Return success response with session data
      return {
        'success': true,
        'data': {
          'user': {
            'id': nationalId,
            'national_id': nationalId
          },
          'session_active': true,
          'auth_method': 'mpin'
        }
      };
    } catch (e) {
      print('Error during MPIN login: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error during MPIN login',
        'message_ar': 'حدث خطأ أثناء تسجيل الدخول'
      };
    }
  }

  // Biometric verification
  Future<Map<String, dynamic>> verifyBiometric({
    required String nationalId,
  }) async {
    try {
      // First check if biometrics are enabled locally
      final isBioEnabled = await isBiometricEnabled();
      if (!isBioEnabled) {
        throw Exception('Biometric authentication is not enabled for this device');
      }

      // Authenticate using biometrics
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) {
        return {
          'success': false,
          'error': 'BIOMETRIC_FAILED',
          'message': 'Biometric authentication failed',
          'message_ar': 'فشل التحقق من البصمة'
        };
      }

      // Set up session after successful biometric verification
      await _secureStorage.write(key: 'session_active', value: 'true');
      await _secureStorage.write(key: 'session_user_id', value: nationalId);
      await _secureStorage.write(key: 'national_id', value: nationalId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_active', true);
      await prefs.setString('session_user_id', nationalId);
      await prefs.setString('national_id', nationalId);
      
      // Start session management
      await startSession(nationalId);
      
      print('Session data stored successfully');
      print('- Session active: true');
      print('- User ID: $nationalId');
      
      // Return success response with session data
      return {
        'success': true,
        'data': {
          'user': {
            'id': nationalId,
            'national_id': nationalId
          },
          'session_active': true,
          'auth_method': 'biometric'
        }
      };
    } catch (e) {
      print('Error during biometric verification: $e');
      throw Exception('Error during biometric verification: $e');
    }
  }

  Future<Map<String, dynamic>> checkRegistrationStatus(String nationalId) async {
    try {
      final requestBody = {
        'national_id': nationalId
      };
      
      print('Checking registration status for ID: $nationalId');
      
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'),
        headers: Constants.userHeaders,
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response: $data');
        return data;
      } else {
        throw Exception('Failed to check registration status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking registration status: $e');
      throw Exception('Error checking registration status: $e');
    }
  }

  // Get government data
  Future<Map<String, dynamic>> getGovernmentData(String nationalId) async {
    try {
      print('=== GOVERNMENT API CALL START ===');
      print('Calling government API for ID: $nationalId');
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}?national_id=$nationalId'),
        headers: Constants.userHeaders,
      );

      print('Government API response status: ${response.statusCode}');
      print('Government API raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Government API parsed response: $data');
        
        if (data['status'] == 'success') {
          print('Government API success data: ${data['data']}');
          print('Available fields in response:');
          data['data'].forEach((key, value) => print('$key: $value'));
          print('=== GOVERNMENT API CALL END ===');
          return data['data'];
        } else {
          print('Government API returned error status: ${data['status']}');
          print('Error message if any: ${data['message']}');
          print('=== GOVERNMENT API CALL END ===');
          // If government data is not found, use arabic name for both fields
          return {
            'name': 'User $nationalId',  // Default English name
            'arabic_name': 'مستخدم $nationalId',  // Default Arabic name
          };
        }
      } else {
        print('Government API failed with status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('=== GOVERNMENT API CALL END ===');
        throw Exception('Failed to get government data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting government data: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return default values if there's an error
      return {
        'name': 'User $nationalId',  // Default English name
        'arabic_name': 'مستخدم $nationalId',  // Default Arabic name
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final deviceInfo = await getDeviceInfo();
      
      final requestBody = {
        'national_id': nationalId,
        'email': email,
        'phone': phone,
        'password': password,
        'device_info': deviceInfo,
      };

      print('Registration Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'),
        headers: Constants.userHeaders,
        body: jsonEncode(requestBody),
      );

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Body: ${response.body}');

      // If response contains HTML error, extract the JSON part
      String jsonStr = response.body;
      if (jsonStr.contains('<br />')) {
        jsonStr = jsonStr.substring(jsonStr.lastIndexOf('{'));
      }

      final data = jsonDecode(jsonStr);
      return data;
    } catch (e) {
      print('Error registering user: $e');
      // Return a map that won't trigger an error in the UI
      return {
        'status': 'continue',
        'message': 'Proceeding to next step'
      };
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'deviceId': androidInfo.id,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'os_version': androidInfo.version.release,
        'platform': 'android',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'deviceId': iosInfo.identifierForVendor,
        'manufacturer': 'Apple',
        'model': iosInfo.model,
        'brand': 'Apple',
        'os_version': iosInfo.systemVersion,
        'platform': 'ios',
      };
    }
    
    throw Exception('Unsupported platform');
  }

  // Store auth token in secure storage
  Future<void> storeToken(String token) async {
    await _secureStorage.write(
      key: 'auth_token',
      value: token,
    );
  }

  // Get auth token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Check if session is active
  Future<bool> isSessionActive() async {
    try {
      print('\n=== CHECKING SESSION STATUS ===');
      
      // Check session flags
      final sessionActive = await _secureStorage.read(key: 'session_active');
      final userId = await _secureStorage.read(key: 'session_user_id');
      
      print('\nSession Flags:');
      print('- Session Active flag: $sessionActive');
      print('- User ID: ${userId ?? 'not found'}');
      
      // For MPIN/biometric sessions, we only need session_active and user_id
      final isActive = sessionActive == 'true' && userId != null;
      
      print('\nFinal Status:');
      print('- Session active: $isActive');
      print('=== SESSION CHECK END ===\n');
      
      return isActive;
    } catch (e) {
      print('❌ Error checking session status: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('\n=== SIGN OUT PROCESS START ===');
      
      // 1. Cancel refresh timer first to prevent re-initialization
      _refreshTimer?.cancel();
      _refreshTimer = null;
      
      // 2. Clear session data
      await signOff();
      
      // 3. Sign out device (this includes server call)
      await signOutDevice();
      
      // 4. Get storage instances
      final prefs = await SharedPreferences.getInstance();
      
      // Store temporary values we want to keep
      final isArabic = prefs.getBool('isArabic') ?? false;
      final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      
      // 5. Clear user-specific data from SharedPreferences
      print('Clearing user-specific data from SharedPreferences...');
      final keysToRemove = [
        'user_data',
        'registration_data',  // Added registration data
        'national_id',
        'device_user_id',
        'auth_token',
        'refresh_token',
        'session_data',
        'biometrics_enabled',
        'mpin_set',
        'last_sign_in',
        'user_preferences',
        'session_active',
        'session_user_id',
        'biometric_user_id',
        'device_registered',
        'mpin',
      ];
      
      for (var key in keysToRemove) {
        await prefs.remove(key);
      }
      
      // 6. Clear user-specific data from SecureStorage
      print('Clearing user-specific data from SecureStorage...');
      final secureKeysToRemove = [
        'user_data',
        'registration_data',  // Added registration data
        'auth_token',
        'refresh_token',
        'device_user_id',
        'mpin',
        'biometrics_enabled',
        'device_registered',
        'session_data',
        'session_active',
        'session_user_id',
        'biometric_user_id',
        'national_id',
        'user_password',
      ];
      
      for (var key in secureKeysToRemove) {
        await _secureStorage.delete(key: key);
      }
      
      // 7. Reset device registration and biometric flags
      await _secureStorage.write(key: 'device_registered', value: 'false');
      await _secureStorage.write(key: 'biometrics_enabled', value: 'false');
      
      // 8. Restore app settings
      await prefs.setBool('isArabic', isArabic);
      await prefs.setBool('is_dark_mode', isDarkMode);
      
      print('=== SIGN OUT PROCESS COMPLETE ===\n');
    } catch (e) {
      print('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Modify signOutDevice to not throw on 404
  Future<void> signOutDevice() async {
    try {
      print('Signing out device completely...');
      
      // Get the user ID before clearing storage
      final userId = await _secureStorage.read(key: 'device_user_id');
      if (userId != null) {
        final deviceInfo = await getDeviceInfo();
        
        try {
          // Call server to unregister device
          final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUnregisterDevice}'),
            headers: Constants.deviceHeaders,
            body: jsonEncode({
              'national_id': userId,
              'device_info': deviceInfo,
            }),
          );

          print('Device unregister response: ${response.body}');
          // Don't throw on 404, just log it
          if (response.statusCode != 200 && response.statusCode != 404) {
            print('Server returned status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Error calling unregister endpoint: $e');
          // Continue with local cleanup even if server call fails
        }
      }
      
      print('Device signed out successfully');
    } catch (e) {
      print('Error during device sign out: $e');
      // Don't throw, just log the error
    }
  }

  // Session Management Methods
  Future<void> signOff() async {
    try {
      print('\n=== AUTH SERVICE SIGN OFF START ===');
      print('1. Attempting to clear session token');
      
      // Check current token before clearing
      final currentToken = await _secureStorage.read(key: 'auth_token');
      print('2. Current auth token exists: ${currentToken != null}');
      
      // Only clear session token
      await _secureStorage.delete(key: 'auth_token');
      print('3. Auth token deleted from secure storage');
      
      // Verify token is cleared
      final tokenAfterDelete = await _secureStorage.read(key: 'auth_token');
      print('4. Auth token after deletion exists: ${tokenAfterDelete != null}');
      
      print('5. Session signed off successfully');
      print('=== AUTH SERVICE SIGN OFF END ===\n');
    } catch (e) {
      print('ERROR in AuthService.signOff(): $e');
      throw Exception('Failed to sign off: $e');
    }
  }

  String getFirstName(String fullName, {bool isArabic = false}) {
    if (fullName.isEmpty) return '';
    return fullName.split(' ')[0];
  }

  Future<String?> getRegisteredUserName({bool isArabic = false}) async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        final fullName = isArabic ? userData['arabic_name'] : userData['name'];
        if (fullName != null && fullName.isNotEmpty) {
          return getFirstName(fullName, isArabic: isArabic);
        }
      }
      return 'Guest';
    } catch (e) {
      print('Error getting registered user name: $e');
      return 'Guest';
    }
  }

  // Device validation method
  Future<Map<String, dynamic>> validateDeviceRegistration(String nationalId) async {
    try {
      print('Validating device registration for user: $nationalId');
      
      final deviceUserId = await _secureStorage.read(key: 'device_user_id');
      final deviceRegistered = await _secureStorage.read(key: 'device_registered');
      final deviceInfo = await getDeviceInfo();
      
      // Check local registration
      if (deviceRegistered != 'true' || deviceUserId != nationalId) {
        return {
          'isValid': false,
          'reason': 'Device not registered locally',
          'requiresAction': 'registration'
        };
      }

      // Verify with server
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointCheckDeviceRegistration}'),
        headers: Constants.deviceHeaders,
        body: jsonEncode({
          'national_id': nationalId,
          'device_info': deviceInfo,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'isValid': false,
          'reason': 'Server validation failed',
          'requiresAction': 'server_error'
        };
      }

      final data = jsonDecode(response.body);
      
      if (data['status'] == 'device_mismatch') {
        return {
          'isValid': false,
          'reason': 'Device registered to different user',
          'requiresAction': 'unregister',
          'currentUser': data['registered_user']
        };
      }

      if (data['status'] == 'user_has_device') {
        return {
          'isValid': false,
          'reason': 'User has another registered device',
          'requiresAction': 'transition',
          'existingDevice': data['existing_device']
        };
      }

      print('Device validation completed: ${data['status']}');
      return {
        'isValid': data['status'] == 'registered',
        'reason': data['message'],
        'requiresAction': data['status'] == 'registered' ? null : 'registration'
      };
    } catch (e) {
      print('Error validating device registration: $e');
      throw Exception('Failed to validate device registration: $e');
    }
  }

  // Device cleanup method
  Future<void> clearDeviceRegistration() async {
    try {
      print('Clearing device registration data...');
      
      // First clear secure storage
      await _secureStorage.delete(key: 'device_user_id');
      await _secureStorage.delete(key: 'device_registered');
      await _secureStorage.delete(key: 'biometrics_enabled');
      await _secureStorage.delete(key: 'biometric_user_id');
      
      print('Secure storage cleared');
      
      // Then clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_user_id');
      await prefs.remove('device_registered');
      
      print('SharedPreferences cleared');
      print('Device registration data cleared successfully');
    } catch (e) {
      print('Error clearing device registration: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to clear device registration: $e');
    }
  }

  // Device transition method
  Future<Map<String, dynamic>> initiateDeviceTransition({
    required String nationalId,
  }) async {
    try {
      print('Initiating device transition for user: $nationalId');
      
      // First verify credentials before proceeding
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointVerifyCredentials}'),
        headers: Constants.authHeaders,
        body: jsonEncode({
          'national_id': nationalId,
          'device_info': await getDeviceInfo(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify credentials');
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Invalid credentials');
      }

      // Clear old device data
      await clearDeviceRegistration();
      
      // Register new device with server
      final deviceInfo = await getDeviceInfo();
      final registerResponse = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegisterDevice}'),
        headers: Constants.deviceHeaders,
        body: jsonEncode({
          'register_device_only': true,
          'national_id': nationalId,
          'device_info': deviceInfo,
        }),
      );

      if (registerResponse.statusCode != 200) {
        throw Exception('Failed to register new device');
      }

      final registerData = jsonDecode(registerResponse.body);
      if (registerData['status'] != 'success') {
        throw Exception(registerData['message'] ?? 'Device registration failed');
      }

      // Store new device registration locally
      await storeDeviceRegistration(nationalId);
      
      print('Device transition completed successfully');
      return {
        'success': true,
        'message': 'Device transition completed successfully',
        'device_info': deviceInfo,
      };
    } catch (e) {
      print('Error during device transition: $e');
      throw Exception('Device transition failed: $e');
    }
  }

  // Unregister current device for a user
  Future<Map<String, dynamic>> unregisterCurrentDevice(String nationalId) async {
    try {
      print('Unregistering current device for user: $nationalId');
      
      final deviceInfo = await getDeviceInfo();
      
      // Send unregister request to server
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUnregisterDevice}'),
        headers: Constants.deviceHeaders,
        body: jsonEncode({
          'national_id': nationalId,
          'device_info': deviceInfo,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unregister device with server');
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Device unregistration failed');
      }

      // Clear local device data
      await clearDeviceRegistration();
      
      print('Device unregistered successfully');
      return {
        'success': true,
        'message': 'Device unregistered successfully'
      };
    } catch (e) {
      print('Error unregistering device: $e');
      throw Exception('Failed to unregister device: $e');
    }
  }

  // Check if ID exists
  Future<Map<String, dynamic>> checkIdExists(String nationalId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'),
        headers: Constants.userHeaders,
        body: jsonEncode({
          'national_id': nationalId,
          'check_only': true  // Flag to indicate we only want to check ID
        }),
      );

      print('ID Check Response Status: ${response.statusCode}');
      print('ID Check Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to check ID: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking ID: $e');
      throw Exception('Error checking ID: $e');
    }
  }

  // Store password for biometric authentication
  Future<void> storePassword(String password) async {
    try {
      await _secureStorage.write(key: 'user_password', value: password);
    } catch (e) {
      print('Error storing password: $e');
      throw Exception('Error storing password for biometric authentication');
    }
  }

  // Clear stored password
  Future<void> clearStoredPassword() async {
    try {
      await _secureStorage.delete(key: 'user_password');
    } catch (e) {
      print('Error clearing stored password: $e');
    }
  }

  // Get user data from secure storage or fetch from server
  Future<Map<String, dynamic>?> getUserData([String? nationalId]) async {
    try {
      // If no national ID provided, try to get from secure storage
      if (nationalId == null) {
        final userDataStr = await _secureStorage.read(key: 'user_data');
        if (userDataStr != null) {
          return jsonDecode(userDataStr) as Map<String, dynamic>;
        }
        return null;
      }

      // If national ID provided, fetch from server
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSignIn}'),
        headers: Constants.authHeaders,
        body: jsonEncode({
          'national_id': nationalId,
          'get_user_data': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['user'] != null) {
          return data['user'];
        }
      }
      throw Exception('Failed to get user data');
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  // Store user data in secure storage
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      print('Storing user data: $userData');
      await _secureStorage.write(
        key: 'user_data',
        value: json.encode(userData),
      );
      print('User data stored successfully');
    } catch (e) {
      print('Error storing user data: $e');
      throw Exception('Failed to store user data: $e');
    }
  }

  // Get auth headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': apiKey,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Clear all stored data (for logout)
  Future<void> clearStoredData() async {
    await _secureStorage.deleteAll();
  }

  // Store registration data locally
  Future<void> storeRegistrationData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registration_data', jsonEncode(data));
    } catch (e) {
      print('Error storing registration data: $e');
      throw Exception('Failed to store registration data: $e');
    }
  }

  // Get stored registration data
  Future<Map<String, dynamic>?> getStoredRegistrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('registration_data');
      if (data != null) {
        return jsonDecode(data);
      }
      return null;
    } catch (e) {
      print('Error getting registration data: $e');
      return null;
    }
  }

  // Clear registration data
  Future<void> clearRegistrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('registration_data');
    } catch (e) {
      print('Error clearing registration data: $e');
    }
  }

  // Get government services data
  Future<Map<String, dynamic>> getGovernmentServices(String nationalId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}?national_id=$nationalId'),
        headers: Constants.userHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get government services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting government services: $e');
      return {
        'status': 'error',
        'message': 'Failed to get government services',
      };
    }
  }

  // Check if biometrics are available
  Future<bool> checkBiometricsAvailable() async {
    try {
      final localAuth = LocalAuthentication();
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  // Start a new session
  Future<void> startSession(String nationalId, {String? userId}) async {
    try {
      print('Starting session for user: $nationalId');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_active', true);
      await prefs.setString('session_user_id', userId ?? nationalId);
      await prefs.setString('national_id', nationalId);
      
      // Store in secure storage as well
      await _secureStorage.write(key: 'session_active', value: 'true');
      await _secureStorage.write(key: 'session_user_id', value: userId ?? nationalId);
      await _secureStorage.write(key: 'national_id', value: nationalId);
      
      // Set up session refresh timer
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(Duration(minutes: 15), (timer) async {
        await refreshSession();
      });
      
      print('Session started successfully');
    } catch (e) {
      print('Error starting session: $e');
      throw Exception('Failed to start session: $e');
    }
  }

  // Refresh the session
  Future<void> refreshSession() async {
    try {
      final sessionActive = await _secureStorage.read(key: 'session_active');
      
      if (sessionActive == 'true') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('session_active', true);
        print('Session refreshed successfully');
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        print('Session refresh cancelled - session not active');
      }
    } catch (e) {
      print('Error refreshing session: $e');
    }
  }

  // Get user's mobile number from stored data
  Future<String?> getStoredMobileNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        print('Retrieved user data for mobile number: ${json.encode(userData)}');
        
        // Try different possible keys for mobile number
        String? mobileNo = userData['mobile_no'] ?? 
                         userData['mobileNo'] ?? 
                         userData['phone'] ?? 
                         userData['phoneNumber'] ??
                         userData['mobile'];
                         
        if (mobileNo != null) {
          // Clean the number: remove any non-digit characters and ensure it starts with 966
          String cleanNumber = mobileNo.toString().replaceAll(RegExp(r'[^\d]'), '');
          
          // Remove leading zeros
          cleanNumber = cleanNumber.replaceAll(RegExp(r'^0+'), '');
          
          // Remove 966 if it exists at the start
          if (cleanNumber.startsWith('966')) {
            cleanNumber = cleanNumber.substring(3);
          }
          
          // Add 966 prefix
          final formattedNumber = '966$cleanNumber';
          
          print('Formatted mobile number: $formattedNumber');
          return formattedNumber;
        } else {
          print('No mobile number found in user data. Available keys: ${userData.keys.toList()}');
        }
      } else {
        print('No user data found in SharedPreferences');
      }
      return null;
    } catch (e) {
      print('Error getting stored mobile number: $e');
      return null;
    }
  }

  // Generate OTP
  Future<Map<String, dynamic>> generateOTP(String nationalId) async {
    try {
      final mobileNo = await getStoredMobileNumber();
      
      if (mobileNo == null) {
        throw Exception('Mobile number not found in stored user data');
      }

      final requestBody = Constants.otpGenerateRequestBody(
        nationalId, 
        mobileNo,
        purpose: 'Login'
      );
      
      print('Generating OTP for:');
      print('National ID: $nationalId');
      print('Mobile Number: $mobileNo');

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final uri = Uri.parse(Constants.proxyOtpGenerateUrl);
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add body
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('OTP Generation Response Status: ${response.statusCode}');
      print('OTP Generation Response Body: $responseBody');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        print('OTP Generation Response: $responseData');
        return responseData;
      } else {
        throw Exception('Failed to generate OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating OTP: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String nationalId, String otp) async {
    print('\n=== VERIFY OTP ===');
    print('📤 National ID: $nationalId');
    print('📤 OTP: $otp');

    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      final client = HttpClient()
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

  // Add this getter for the session provider to check
  bool get isSigningIn => _isSigningIn;

  // Get user data from secure storage
  Future<String?> getSecureUserData() async {
    try {
      return await _secureStorage.read(key: 'user_data');
    } catch (e) {
      print('Error reading from secure storage: $e');
      return null;
    }
  }

  // Get device ID from storage
  Future<String?> getDeviceId() async {
    try {
      print('\n=== GETTING DEVICE ID ===');
      
      // Try secure storage first
      String? deviceId = await _secureStorage.read(key: 'device_user_id');
      print('Secure Storage Device ID: $deviceId');
      
      if (deviceId != null) {
        print('Device ID found in secure storage');
        return deviceId;
      }
      
      // Fall back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('device_user_id');
      print('SharedPreferences Device ID: $deviceId');
      
      if (deviceId != null) {
        print('Device ID found in SharedPreferences');
        // Sync to secure storage for next time
        await _secureStorage.write(key: 'device_user_id', value: deviceId);
      }
      
      print('=== GET DEVICE ID END ===\n');
      return deviceId;
    } catch (e) {
      print('Error getting device ID: $e');
      return null;
    }
  }
}