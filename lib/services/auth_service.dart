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

  // Register device - simplified flow
  Future<Map<String, dynamic>> registerDevice({
    required String nationalId,
  }) async {
    try {
      final deviceInfo = await getDeviceInfo();
      
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegisterDevice}'),
        headers: await getAuthHeaders(),  // Use auth headers for proper API key
        body: jsonEncode({
          'national_id': nationalId,
          'deviceId': deviceInfo['deviceId'],
          'platform': deviceInfo['platform'],
          'model': deviceInfo['model'],
          'manufacturer': deviceInfo['manufacturer'],
        }),
      );

      final data = jsonDecode(response.body);
      print('Device registration response: $data');

      if (data['status'] == 'success') {
        // Store device registration data locally
        await storeDeviceRegistration(nationalId);
      }

      return data;
    } catch (e) {
      print('Error registering device: $e');
      return {
        'status': 'error',
        'message': 'Error registering device: $e',
        'message_ar': 'حدث خطأ أثناء تسجيل الجهاز'
      };
    }
  }

  // Core sign-in method
  Future<Map<String, dynamic>> signIn({
    required String nationalId,
    String? password,
    String? deviceId,
  }) async {
    try {
      // Always register device first
      final deviceRegistration = await registerDevice(nationalId: nationalId);
      if (deviceRegistration['status'] != 'success') {
        return deviceRegistration;
      }

      final deviceInfo = await getDeviceInfo();
      
      final Map<String, dynamic> requestBody = {
        'national_id': nationalId,
        'deviceId': deviceId ?? deviceInfo['deviceId'],
        'device_info': deviceInfo,
      };

      if (password != null) {
        requestBody['password'] = password;
      }

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSignIn}'),
        headers: await getAuthHeaders(),
        body: jsonEncode(requestBody),
      );

      print('Login API Response:');
      print(response.body);

      final data = jsonDecode(response.body);
      
      if (data['status'] == 'success') {
        // Store tokens and start session
        if (data['token'] != null) {
          await storeToken(data['token']);
        }
        if (data['user'] != null) {
          await storeUserData(data['user']);
          await startSession(data['user']['national_id']);
        }
      }

      return data;
    } catch (e) {
      print('Error during sign in: $e');
      return {
        'status': 'error',
        'message': 'Error during sign in: $e',
        'message_ar': 'حدث خطأ أثناء تسجيل الدخول'
      };
    }
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

      // Get device info
      final deviceInfo = await getDeviceInfo();
      final deviceId = deviceInfo['deviceId'];
      
      if (deviceId == null) {
        print('Could not get device ID');
        throw Exception('Could not get device ID');
      }
      
      // Use the core signIn method
      return await signIn(
        nationalId: nationalId,
        deviceId: deviceId,
      );
    } catch (e) {
      print('Error during MPIN login: $e');
      return {
        'status': 'error',
        'message': 'Error during MPIN login: $e',
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

      final deviceInfo = await getDeviceInfo();
      final deviceId = deviceInfo['deviceId'];
      
      if (deviceId == null) {
        throw Exception('Could not get device ID');
      }
      
      return await signIn(
        nationalId: nationalId,
        deviceId: deviceId,
      );
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
      print('Error: $e');
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
      final token = await _secureStorage.read(key: 'auth_token');
      return token != null;
    } catch (e) {
      print('Error checking session status: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await signOff(); // Use existing signOff method
  }

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

          // Even if server call fails, continue with local cleanup
          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              if (data['status'] != 'success') {
                print('Server returned error: ${data['message']}');
              }
            } catch (e) {
              print('Error parsing server response: $e');
            }
          } else {
            print('Server returned status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Error calling unregister endpoint: $e');
          // Continue with local cleanup even if server call fails
        }
      }

      // Clear all device-related data
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'device_registered');
      await _secureStorage.delete(key: 'device_user_id');
      await _secureStorage.delete(key: 'biometrics_enabled');
      await _secureStorage.delete(key: 'biometric_user_id');
      await _secureStorage.delete(key: 'mpin');
      await _secureStorage.delete(key: 'mpin_set');
      await _secureStorage.delete(key: 'session_active');
      await _secureStorage.delete(key: 'user_data');
      await _secureStorage.delete(key: 'user_password');

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_user_id');
      await prefs.remove('device_registered');
      await prefs.setBool('session_active', false);
      
      print('Device signed out successfully');
    } catch (e) {
      print('Error during device sign out: $e');
      // Still throw the error so UI can handle it
      throw Exception('Failed to sign out device: $e');
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
      'api-key': apiKey,
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
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool('session_active') ?? false;
      
      if (isActive) {
        await prefs.setBool('session_active', true);
        print('Session refreshed successfully');
      }
    } catch (e) {
      print('Error refreshing session: $e');
    }
  }

  // Generate OTP
  Future<Map<String, dynamic>> generateOTP(String nationalId) async {
    try {
      print('\n=== GENERATING OTP ===');
      print('National ID: $nationalId');
      print('Endpoint: ${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}');
      
      // Use auth form headers since this endpoint expects form data
      final headers = Constants.authFormHeaders;
      print('Using headers: $headers');

      final body = {
        'national_id': nationalId,
      };
      print('Request Body: $body');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPGenerate}'),
        headers: headers,
        body: body,  // Send as form data
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed Response: $data');
        
        // If the response doesn't have a status field, wrap it in a standard format
        if (!data.containsKey('status')) {
          return {
            'status': response.statusCode == 200 ? 'success' : 'error',
            'message': data['message'] ?? 'OTP sent successfully',
            'message_ar': data['message_ar'] ?? 'تم إرسال رمز التحقق بنجاح',
            'data': data
          };
        }
        
        print('=== OTP GENERATION END ===\n');
        return data;
      } else {
        print('HTTP Error: ${response.statusCode}');
        throw Exception('Failed to generate OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating OTP: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'status': 'error',
        'message': 'Failed to generate OTP',
        'message_ar': 'فشل في إرسال رمز التحقق',
        'error': e.toString()
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String nationalId, String otp) async {
    try {
      print('\n=== VERIFYING OTP ===');
      print('National ID: $nationalId');
      print('OTP: $otp');
      print('Endpoint: ${Constants.apiBaseUrl}${Constants.endpointOTPVerification}');
      
      // Use auth form headers since this endpoint expects form data
      final headers = Constants.authFormHeaders;
      print('Using headers: $headers');

      final body = {
        'national_id': nationalId,
        'otp_code': otp,
      };
      print('Request Body: $body');

      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointOTPVerification}'),
        headers: headers,
        body: body,  // Send as form data
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed Response: $data');
        
        // If the response doesn't have a status field, wrap it in a standard format
        if (!data.containsKey('status')) {
          return {
            'status': response.statusCode == 200 ? 'success' : 'error',
            'message': data['message'] ?? 'OTP verified successfully',
            'message_ar': data['message_ar'] ?? 'تم التحقق من الرمز بنجاح',
            'data': data
          };
        }
        
        print('=== OTP VERIFICATION END ===\n');
        return data;
      } else {
        print('HTTP Error: ${response.statusCode}');
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'status': 'error',
        'message': 'Failed to verify OTP',
        'message_ar': 'فشل في التحقق من الرمز',
        'error': e.toString()
      };
    }
  }
}