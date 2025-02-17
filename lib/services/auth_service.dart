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
    required String password,
  }) async {
    HttpClient? client;
    try {
      print('\n=== SIGN IN PROCESS START ===');
      print('Step 1: Initial Parameters');
      print('- National ID: $nationalId');
      print('- Sign in type: Password Sign In');
      print('- Password provided: ${password.isNotEmpty}');

      // Step 2: Get device info
      print('Step 2: Getting Device Info');
      final deviceInfo = await getDeviceInfo();
      print('- Raw Device Info: ${json.encode(deviceInfo)}');
      print('- Device ID: ${deviceInfo['deviceId']}');
      print('- Platform: ${deviceInfo['platform']}');
      print('- Model: ${deviceInfo['model']}');

      // Step 3: Prepare request
      print('Step 3: Preparing Sign In Request');
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSignIn}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.authHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });

      final requestBody = {
        'nationalId': nationalId,
        'deviceId': deviceInfo['deviceId'],
        'password': password,
      };

      print('API Call Details:');
      print('- Endpoint: ${Constants.apiBaseUrl}${Constants.endpointSignIn}');
      print('- Headers: ${json.encode(Constants.authHeaders)}');
      print('- Request Body: ${json.encode(requestBody)}');

      // Step 4: Make API call
      print('Step 4: Making Sign In API Call');
      request.write(json.encode(requestBody));
      final response = await request.close();

      // Step 5: Process response
      print('Step 5: Processing Response');
      final responseBody = await response.transform(utf8.decoder).join();
      print('- Status Code: ${response.statusCode}');
      print('- Response Headers: ${response.headers}');
      print('- Raw Response Body: $responseBody');

      final parsedResponse = json.decode(responseBody);
      print('- Parsed Response: ${json.encode(parsedResponse)}');

      if (parsedResponse['success'] == true && parsedResponse['data'] != null) {
        print('\nStep 6: Successful Sign In');
        print('- Processing user data and tokens');

        // 💡 Set sign-in flags in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_signed_in', true);
        await prefs.setBool('device_registered', true);
        await prefs.setString('device_user_id', nationalId);
        
        // 💡 Set sign-in flags in SecureStorage
        await _secureStorage.write(key: 'device_registered', value: 'true');
        await _secureStorage.write(key: 'device_user_id', value: nationalId);

        // Return the response without storing any data
        return parsedResponse;
      }

      return parsedResponse;
    } catch (e) {
      print('Error during sign in: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error during sign in',
        'message_ar': 'حدث خطأ أثناء تسجيل الدخول'
      };
    } finally {
      client?.close();
    }
  }

  // Register device with detailed logging
  Future<Map<String, dynamic>> registerDevice({
    required String nationalId,
    required Map<String, dynamic> deviceInfo,
  }) async {
    HttpClient? client;
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

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}/device'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      request.headers.add('x-api-key', Constants.apiKey);
      
      request.write(jsonEncode(requestBody));
      
      print('\nStep 3: Making API Call');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('\nStep 4: Processing Response');
      print('- Status Code: ${response.statusCode}');
      print('- Response Body: $responseBody');

      final parsedResponse = json.decode(responseBody);
      print('- Parsed Response: ${json.encode(parsedResponse)}');

      print('\n=== DEVICE REGISTRATION END ===');
      
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
    } finally {
      client?.close();
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
      print('\n=== CHECKING DEVICE REGISTRATION ===');
      
      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isRegisteredPrefs = prefs.getBool('device_registered') ?? false;
      final deviceUserIdPrefs = prefs.getString('device_user_id');
      
      print('SharedPreferences Check:');
      print('- device_registered: $isRegisteredPrefs');
      print('- device_user_id: $deviceUserIdPrefs');
      
      // Check SecureStorage
      final isRegisteredSecure = await _secureStorage.read(key: 'device_registered');
      final deviceUserIdSecure = await _secureStorage.read(key: 'device_user_id');
      
      print('SecureStorage Check:');
      print('- device_registered: $isRegisteredSecure');
      print('- device_user_id: $deviceUserIdSecure');
      
      // 💡 Check both storages and ensure we have both flags and IDs
      final isRegistered = (isRegisteredPrefs && deviceUserIdPrefs != null) || 
                         (isRegisteredSecure == 'true' && deviceUserIdSecure != null);
      
      print('Final Registration Status: $isRegistered');
      print('=== DEVICE REGISTRATION CHECK END ===\n');
      
      return isRegistered;
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

  // Check registration status
  Future<Map<String, dynamic>> checkRegistrationStatus(String nationalId) async {
    HttpClient? client;
    try {
      final requestBody = {
        'national_id': nationalId
      };
      
      print('Checking registration status for ID: $nationalId');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.userHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        print('API Response: $data');
        return data;
      } else {
        throw Exception('Failed to check registration status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking registration status: $e');
      throw Exception('Error checking registration status: $e');
    } finally {
      client?.close();
    }
  }

  // Get government data
  Future<Map<String, dynamic>> getGovernmentData(String nationalId) async {
    HttpClient? client;
    try {
      print('=== GOVERNMENT API CALL START ===');
      print('Calling government API for ID: $nationalId');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.getUrl(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}?national_id=$nationalId')
      );
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.userHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('Government API response status: ${response.statusCode}');
      print('Government API raw response body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
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
          return {
            'name': 'User $nationalId',
            'arabic_name': 'مستخدم $nationalId',
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
      return {
        'name': 'User $nationalId',
        'arabic_name': 'مستخدم $nationalId',
      };
    } finally {
      client?.close();
    }
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    HttpClient? client;
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
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.userHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode(requestBody));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Body: $responseBody');

      // If response contains HTML error, extract the JSON part
      String jsonStr = responseBody;
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
    } finally {
      client?.close();
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
      print('\n=== AUTH SERVICE SIGN OUT START ===');
      print('1. Starting to clear specific data from both storages');
      
      final prefs = await SharedPreferences.getInstance();
      
      // 💡 Clear specific data from SharedPreferences
      print('2. Clearing SharedPreferences data:');
      final spKeysToRemove = [
        'device_id',
        'device_registered',
        'mpin',
        'national_id',
        'device_user_id',
        'user_phone',
        'is_signed_in',
        'user_data',
        'session_active',
        'session_user_id',
        'isSessionActive',
        'biometrics_enabled',
        'biometric_user_id',
        'last_login',
        'dakhli_salary_data',
        'user_settings',
        'user_preferences',
        'registration_data'
      ];
      
      for (var key in spKeysToRemove) {
        await prefs.remove(key);
        print('   - Removed SP: $key');
      }
      
      // 💡 Clear specific data from SecureStorage
      print('3. Clearing SecureStorage data:');
      final ssKeysToRemove = [
        'device_id',
        'device_registered',
        'mpin',
        'national_id',
        'device_user_id',
        'user_data',
        'session_active',
        'session_user_id',
        'biometrics_enabled',
        'biometric_user_id',
        'auth_token',
        'refresh_token',
        'token_expiry',
        'card_offer_data',
        'loan_offer_data',
        'selected_salary_data',
        'dakhli_salary_data',
        'selected_card_type',
        'user_phone',
        'application_data'
      ];
      
      for (var key in ssKeysToRemove) {
        await _secureStorage.delete(key: key);
        print('   - Removed SS: $key');
      }
      
      // Cancel refresh timer if active
      _refreshTimer?.cancel();
      _refreshTimer = null;
      
      print('4. All specified data cleared successfully');
      print('=== AUTH SERVICE SIGN OUT END ===\n');
    } catch (e) {
      print('ERROR in AuthService.signOut(): $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Modify signOutDevice to not throw on 404
  Future<void> signOutDevice() async {
    HttpClient? client;
    try {
      print('\n=== DEVICE SIGN OUT START ===');
      print('1. Starting device sign out process');
      
      // Get the user ID before clearing storage
      final userId = await _secureStorage.read(key: 'device_user_id');
      if (userId != null) {
        final deviceInfo = await getDeviceInfo();
        
        try {
          // 💡 Create a custom HttpClient that accepts self-signed certificates
          client = HttpClient()
            ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
          
          final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUnregisterDevice}'));
          request.headers.contentType = ContentType.json;
          request.headers.add('Accept', 'application/json');
          Constants.deviceHeaders.forEach((key, value) {
            request.headers.add(key, value);
          });
          
          request.write(jsonEncode({
            'national_id': userId,
            'device_info': deviceInfo,
          }));
          
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();

          print('2. Device unregister response: $responseBody');
          // Don't throw on 404, just log it
          if (response.statusCode != 200 && response.statusCode != 404) {
            print('Server returned status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Error calling unregister endpoint: $e');
          // Continue with local cleanup even if server call fails
        } finally {
          client?.close();
        }
      }
      
      // 💡 Clear ALL data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // This removes everything
      
      // 💡 Clear ALL data from SecureStorage
      await _secureStorage.deleteAll();
      
      print('3. All local data cleared');
      print('=== DEVICE SIGN OUT COMPLETE ===\n');
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

      // 💡 Clear only session flags, keep is_signed_in as true
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_active', false);
      await _secureStorage.write(key: 'session_active', value: 'false');
      
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
    HttpClient? client;
    try {
      print('Validating device registration for user: $nationalId');
      
      final deviceUserId = await _secureStorage.read(key: 'device_user_id');
      final deviceRegistered = await _secureStorage.read(key: 'device_registered');
      final deviceInfo = await getDeviceInfo();
      
      if (deviceRegistered != 'true' || deviceUserId != nationalId) {
        return {
          'isValid': false,
          'reason': 'Device not registered locally',
          'requiresAction': 'registration'
        };
      }

      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointCheckDeviceRegistration}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.deviceHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode({
        'national_id': nationalId,
        'device_info': deviceInfo,
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        return {
          'isValid': false,
          'reason': 'Server validation failed',
          'requiresAction': 'server_error'
        };
      }

      final data = jsonDecode(responseBody);
      
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
    } finally {
      client?.close();
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
      await prefs.remove('is_signed_in');  // 💡 Also clear is_signed_in flag
      
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
    HttpClient? client;
    try {
      print('Initiating device transition for user: $nationalId');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      // First verify credentials
      final verifyRequest = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointVerifyCredentials}'));
      verifyRequest.headers.contentType = ContentType.json;
      verifyRequest.headers.add('Accept', 'application/json');
      Constants.authHeaders.forEach((key, value) {
        verifyRequest.headers.add(key, value);
      });
      
      verifyRequest.write(jsonEncode({
        'national_id': nationalId,
        'device_info': await getDeviceInfo(),
      }));
      
      final verifyResponse = await verifyRequest.close();
      final verifyResponseBody = await verifyResponse.transform(utf8.decoder).join();

      if (verifyResponse.statusCode != 200) {
        throw Exception('Failed to verify credentials');
      }

      final verifyData = jsonDecode(verifyResponseBody);
      if (verifyData['status'] != 'success') {
        throw Exception(verifyData['message'] ?? 'Invalid credentials');
      }

      // Clear old device data
      await clearDeviceRegistration();
      
      // Register new device
      final deviceInfo = await getDeviceInfo();
      final registerRequest = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegisterDevice}'));
      registerRequest.headers.contentType = ContentType.json;
      registerRequest.headers.add('Accept', 'application/json');
      Constants.deviceHeaders.forEach((key, value) {
        registerRequest.headers.add(key, value);
      });
      
      registerRequest.write(jsonEncode({
        'register_device_only': true,
        'national_id': nationalId,
        'device_info': deviceInfo,
      }));
      
      final registerResponse = await registerRequest.close();
      final registerResponseBody = await registerResponse.transform(utf8.decoder).join();

      if (registerResponse.statusCode != 200) {
        throw Exception('Failed to register new device');
      }

      final registerData = jsonDecode(registerResponseBody);
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
    } finally {
      client?.close();
    }
  }

  // Unregister current device
  Future<Map<String, dynamic>> unregisterCurrentDevice(String nationalId) async {
    HttpClient? client;
    try {
      print('Unregistering current device for user: $nationalId');
      
      final deviceInfo = await getDeviceInfo();
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUnregisterDevice}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.deviceHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode({
        'national_id': nationalId,
        'device_info': deviceInfo,
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('Failed to unregister device with server');
      }

      final data = jsonDecode(responseBody);
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
    } finally {
      client?.close();
    }
  }

  // Check if ID exists
  Future<Map<String, dynamic>> checkIdExists(String nationalId) async {
    HttpClient? client;
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointUserRegistration}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.userHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode({
        'national_id': nationalId,
        'check_only': true
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('ID Check Response Status: ${response.statusCode}');
      print('ID Check Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data;
      } else {
        throw Exception('Failed to check ID: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking ID: $e');
      throw Exception('Error checking ID: $e');
    } finally {
      client?.close();
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
    HttpClient? client;
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
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSignIn}'));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.authHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode({
        'national_id': nationalId,
        'get_user_data': true,
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['status'] == 'success' && data['user'] != null) {
          return data['user'];
        }
      }
      throw Exception('Failed to get user data');
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Failed to get user data: $e');
    } finally {
      client?.close();
    }
  }

  // Store user data in secure storage
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      print('\n=== STORING USER DATA ===');
      final prefs = await SharedPreferences.getInstance();
      final storage = const FlutterSecureStorage();
      
      // Store user data
      await prefs.setString('user_data', json.encode(userData));
      await storage.write(key: 'user_data', value: json.encode(userData));
      
      // 💡 Store device ID separately if it exists
      if (userData['device_id'] != null) {
        await storage.write(key: 'device_id', value: userData['device_id']);
        await prefs.setString('device_id', userData['device_id']);
      }
      
      print('✅ User data stored successfully');
      print('User data: $userData');
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

  // Get government services
  Future<Map<String, dynamic>> getGovernmentServices(String nationalId) async {
    HttpClient? client;
    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.getUrl(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointGetGovernmentData}?national_id=$nationalId')
      );
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      Constants.userHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to get government services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting government services: $e');
      return {
        'status': 'error',
        'message': 'Failed to get government services',
      };
    } finally {
      client?.close();
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
      print('T_ResetPass_B1: Starting to retrieve stored mobile number');
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      
      print('T_ResetPass_B2: Retrieved user data string: ${userDataStr ?? 'null'}');
      
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        print('T_ResetPass_B3: Parsed user data: ${json.encode(userData)}');
        print('T_ResetPass_B4: Available keys in user data: ${userData.keys.toList()}');
        
        // Try different possible keys for mobile number
        String? mobileNo = userData['mobile_no'] ?? 
                         userData['mobileNo'] ?? 
                         userData['phone'] ?? 
                         userData['phoneNumber'] ??
                         userData['mobile'];
                         
        print('T_ResetPass_B5: Found mobile number: ${mobileNo ?? 'null'}');
        
        if (mobileNo != null) {
          // Clean the number: remove any non-digit characters and ensure it starts with 966
          String cleanNumber = mobileNo.toString().replaceAll(RegExp(r'[^\d]'), '');
          print('T_ResetPass_B6: Cleaned number (removed non-digits): $cleanNumber');
          
          // Remove leading zeros
          cleanNumber = cleanNumber.replaceAll(RegExp(r'^0+'), '');
          print('T_ResetPass_B7: Removed leading zeros: $cleanNumber');
          
          // Remove 966 if it exists at the start
          if (cleanNumber.startsWith('966')) {
            cleanNumber = cleanNumber.substring(3);
            print('T_ResetPass_B8: Removed 966 prefix: $cleanNumber');
          }
          
          // Add 966 prefix
          final formattedNumber = '966$cleanNumber';
          print('T_ResetPass_B9: Final formatted number: $formattedNumber');
          return formattedNumber;
        } else {
          print('T_ResetPass_B10: No mobile number found in user data');
        }
      } else {
        print('T_ResetPass_B11: No user data found in SharedPreferences');
      }

      // Try getting from secure storage as fallback
      print('T_ResetPass_B12: Trying to get phone from secure storage');
      final securePhone = await _secureStorage.read(key: 'user_phone');
      if (securePhone != null) {
        print('T_ResetPass_B13: Found phone in secure storage: $securePhone');
        return securePhone;
      }
      print('T_ResetPass_B14: No phone found in secure storage');

      return null;
    } catch (e) {
      print('T_ResetPass_B15: Error getting stored mobile number: $e');
      return null;
    }
  }

  // Generate OTP
  Future<Map<String, dynamic>> generateOTP(String nationalId) async {
    HttpClient? client;
    try {
      print('T_ResetPass_A1: Starting OTP generation in AuthService');

      // 💡 Check if OTP bypass is enabled
      if (Constants.bypassOtpForTesting) {
        print('⚠️ OTP BYPASS ENABLED - Returning mock success response');
        return {
          'success': true,
          'status': 'success',
          'result': {
            'verified': true,
            'nationalId': nationalId,
            'status': 'VERIFIED'
          },
          'message': 'OTP verified successfully (TESTING MODE)',
          'message_ar': 'تم التحقق من رمز التحقق بنجاح'
        };
      }
      
      print('T_ResetPass_A2: Getting user data from backend');
      
      // Get device info first
      final deviceInfo = await getDeviceInfo();
      print('T_ResetPass_A2.1: Got device info: ${json.encode(deviceInfo)}');
      
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final userDataRequest = await client.postUrl(Uri.parse('${Constants.apiBaseUrl}/auth/signin'));
      userDataRequest.headers.contentType = ContentType.json;
      userDataRequest.headers.add('Accept', 'application/json');
      userDataRequest.headers.add('x-api-key', Constants.apiKey);
      
      userDataRequest.write(jsonEncode({
        'nationalId': nationalId,
        'deviceId': deviceInfo['deviceId'],
        'password': null // This will trigger OTP flow
      }));

      final userDataResponse = await userDataRequest.close();
      final userDataResponseBody = await userDataResponse.transform(utf8.decoder).join();

      print('T_ResetPass_A3: User data response: $userDataResponseBody');
      final userData = json.decode(userDataResponseBody);

      if (userData['success'] != true) {
        print('T_ResetPass_A4: User data fetch failed');
        return {
          'success': false,
          'code': userData['code'] ?? 'USER_NOT_FOUND',
          'message': userData['message'] ?? 'User not found'
        };
      }

      final mobileNo = userData['data']?['user']?['phone'];
      print('T_ResetPass_A5: Got phone number from backend: $mobileNo');

      if (mobileNo == null) {
        print('T_ResetPass_A6: No phone number in backend response');
        return {
          'success': false,
          'code': 'INVALID_PHONE',
          'message': 'No phone number found for this ID'
        };
      }

      final requestBody = {
        'nationalId': nationalId,
        'mobileNo': mobileNo,
        'type': 'reset_password',
        'purpose': 'RESET_PASSWORD',
        'userId': nationalId
      };
      
      print('T_ResetPass_A7: Preparing OTP request');
      print('T_ResetPass_A8: Request Body: ${json.encode(requestBody)}');

      final otpRequest = await client.postUrl(Uri.parse(Constants.proxyOtpGenerateUrl));
      otpRequest.headers.contentType = ContentType.json;
      otpRequest.headers.add('Accept', 'application/json');
      otpRequest.headers.add('x-api-key', Constants.apiKey);
      
      otpRequest.write(jsonEncode(requestBody));
      
      print('T_ResetPass_A11: Sending OTP request');
      final response = await otpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('T_ResetPass_A12: OTP Response Status: ${response.statusCode}');
      print('T_ResetPass_A13: OTP Response Body: $responseBody');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        print('T_ResetPass_A14: OTP Generation Response: $responseData');
        
        // 💡 Store phone number
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', mobileNo);
        print('T_ResetPass_A15: Stored phone number in SharedPreferences');
        
        return {
          ...responseData,
          'success': true,
          'phone': mobileNo
        };
      } else {
        print('T_ResetPass_A16: Failed to generate OTP: ${response.statusCode}');
        throw Exception('Failed to generate OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('T_ResetPass_A17: Error generating OTP: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    } finally {
      client?.close();
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String nationalId, String otp) async {
    HttpClient? client;
    print('\n=== VERIFY OTP ===');
    print('📤 National ID: $nationalId');
    print('📤 OTP: $otp');

    // 💡 Check if OTP bypass is enabled
    if (Constants.bypassOtpForTesting) {
      print('⚠️ OTP BYPASS ENABLED - Returning mock success response');
      return {
        'success': true,
        'status': 'success',
        'result': {
          'verified': true,
          'nationalId': nationalId,
          'status': 'VERIFIED'
        },
        'message': 'OTP verified successfully (TESTING MODE)',
        'message_ar': 'تم التحقق من رمز التحقق بنجاح'
      };
    }

    try {
      // 💡 Create a custom HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse(Constants.proxyOtpVerifyUrl));
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      request.headers.add('x-api-key', Constants.apiKey);
      
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
      client?.close();
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
      String? deviceId = await _secureStorage.read(key: 'device_id');
      print('Secure Storage Device ID: $deviceId');
      
      if (deviceId != null) {
        print('Device ID found in secure storage');
        return deviceId;
      }
      
      // Fall back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('device_id');
      print('SharedPreferences Device ID: $deviceId');
      
      if (deviceId != null) {
        print('Device ID found in SharedPreferences');
        // Sync to secure storage for next time
        await _secureStorage.write(key: 'device_id', value: deviceId);
      } else {
        // 💡 Try to get from user data as last resort
        final userDataStr = await _secureStorage.read(key: 'user_data');
        if (userDataStr != null) {
          final userData = json.decode(userDataStr);
          deviceId = userData['device_id'];
          if (deviceId != null) {
            print('Device ID found in user data');
            await _secureStorage.write(key: 'device_id', value: deviceId);
            await prefs.setString('device_id', deviceId);
          }
        }
      }
      
      print('Final Device ID: $deviceId');
      print('=== GET DEVICE ID END ===\n');
      return deviceId;
    } catch (e) {
      print('Error getting device ID: $e');
      return null;
    }
  }
}