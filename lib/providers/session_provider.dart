import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isSignedIn = false;
  bool _manualSignOff = false;  // Track if user manually signed off
  bool _hasActiveSession = false;  // Track active session state
  
  bool get isSignedIn => _isSignedIn;
  bool get hasActiveSession => _hasActiveSession;

  // Initialize the session state
  Future<void> initializeSession() async {
    try {
      print('\n=== SESSION PROVIDER INITIALIZE START ===');
      print('1. Current states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - manualSignOff: $_manualSignOff');
      print('   - hasActiveSession: $_hasActiveSession');

      // 💡 First check persisted isSignedIn state
      final prefs = await SharedPreferences.getInstance();
      final persistedSignedIn = prefs.getBool('is_signed_in') ?? false;
      _isSignedIn = persistedSignedIn;

      // 💡 Check device registration status
      final isDeviceRegistered = await _authService.isDeviceRegistered();
      print('2. Device registration status: $isDeviceRegistered');

      if (_manualSignOff) {
        print('3. Manual sign off is true, keeping isSignedIn as $persistedSignedIn');
        notifyListeners();
        return;
      }

      print('4. Fetching user data and session status');
      final userData = await _authService.getUserData();
      final deviceId = userData?['device_id'] ?? await _authService.getDeviceId();
      final sessionFromAuth = await _authService.isSessionActive();
      final hasValidUserData = userData != null && (deviceId != null || userData['device_id'] != null);
      
      print('5. Session status:');
      print('   - User Data: $userData');
      print('   - Device ID: $deviceId');
      print('   - Session from Auth: $sessionFromAuth');
      print('   - Has Valid User Data: $hasValidUserData');
      print('   - Device Registered: $isDeviceRegistered');

      _hasActiveSession = sessionFromAuth;
      
      // 💡 Update isSignedIn based on all conditions
      if (!persistedSignedIn || !isDeviceRegistered) {
        _isSignedIn = false;
        await prefs.setBool('is_signed_in', false);
      }
      
      print('6. New states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - hasActiveSession: $_hasActiveSession');
      print('   - Device Registered: $isDeviceRegistered');
      
      print('7. Notifying listeners');
      notifyListeners();
      print('=== SESSION PROVIDER INITIALIZE END ===\n');
    } catch (e) {
      print('\n!!! ERROR IN SESSION PROVIDER INITIALIZE !!!');
      print('Error details: $e');
      // Reset all states on error
      _isSignedIn = false;
      _hasActiveSession = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_signed_in', false);
      notifyListeners();
      print('Session state reset due to error');
      print('!!! ERROR HANDLING COMPLETE !!!\n');
    }
  }

  // Update session state
  Future<void> checkSession() async {
    try {
      print('\n=== SESSION PROVIDER CHECK START ===');
      print('1. Current states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - manualSignOff: $_manualSignOff');
      print('   - hasActiveSession: $_hasActiveSession');

      if (_manualSignOff) {
        print('2. Manual sign off is true, skipping check');
        return;
      }

      print('3. Fetching user data and session status');
      final userData = await _authService.getUserData();
      final deviceId = await _authService.getDeviceId();
      final sessionFromAuth = await _authService.isSessionActive();
      final hasValidUserData = userData != null && deviceId != null;
      
      print('4. Session status:');
      print('   - User Data: $userData');
      print('   - Device ID: $deviceId');
      print('   - Session from Auth: $sessionFromAuth');
      print('   - Has Valid User Data: $hasValidUserData');

      final newHasActiveSession = sessionFromAuth;
      final newSignedInState = sessionFromAuth && hasValidUserData;
      
      if (newHasActiveSession != _hasActiveSession || newSignedInState != _isSignedIn) {
        print('5. State change detected');
        print('   - Old isSignedIn: $_isSignedIn');
        print('   - New isSignedIn: $newSignedInState');
        print('   - Old hasActiveSession: $_hasActiveSession');
        print('   - New hasActiveSession: $newHasActiveSession');
        _isSignedIn = newSignedInState;
        _hasActiveSession = newHasActiveSession;
        notifyListeners();
        print('6. Listeners notified of state change');
      } else {
        print('5. No state change needed');
      }
      print('=== SESSION PROVIDER CHECK END ===\n');
    } catch (e) {
      print('\n!!! ERROR IN SESSION PROVIDER CHECK !!!');
      print('Error details: $e');
      if (_isSignedIn || _hasActiveSession) {
        _isSignedIn = false;
        _hasActiveSession = false;
        notifyListeners();
        print('Session state reset to false due to error');
      }
      print('!!! ERROR HANDLING COMPLETE !!!\n');
    }
  }

  // Handle sign off
  Future<void> signOff() async {
    try {
      print('\n=== SESSION PROVIDER SIGN OFF START ===');
      print('1. Current states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - manualSignOff: $_manualSignOff');
      print('   - hasActiveSession: $_hasActiveSession');
      
      print('2. Calling AuthService.signOff()');
      await _authService.signOff();
      print('3. AuthService.signOff() completed');
      
      print('4. Updating provider state');
      _hasActiveSession = false;
      _manualSignOff = true;
      // 💡 Keep isSignedIn true and persist it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_signed_in', true);
      
      print('5. New states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - manualSignOff: $_manualSignOff');
      print('   - hasActiveSession: $_hasActiveSession');
      
      print('6. Notifying listeners');
      notifyListeners();
      print('=== SESSION PROVIDER SIGN OFF END ===\n');
    } catch (e) {
      print('\n!!! ERROR IN SESSION PROVIDER SIGN OFF !!!');
      print('Error details: $e');
      print('!!! ERROR HANDLING COMPLETE !!!\n');
      throw e;
    }
  }

  // Reset manual sign off flag (call this when user signs in)
  void resetManualSignOff() async {
    print('\n=== RESET MANUAL SIGN OFF START ===');
    print('1. Current states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    
    _manualSignOff = false;
    // 💡 Update persisted isSignedIn state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_signed_in', _isSignedIn);
    
    print('2. New states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    print('=== RESET MANUAL SIGN OFF END ===\n');
  }

  // Set signed in state explicitly
  void setSignedIn(bool value) async {
    print('\n=== SET SIGNED IN STATE START ===');
    print('1. Current states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    print('   - Requested state: $value');
    
    _isSignedIn = value;
    if (value) {
      _manualSignOff = false;
      _hasActiveSession = true;
    }
    
    // 💡 Persist the isSignedIn state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_signed_in', value);
    
    print('2. New states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    
    print('3. Notifying listeners');
    notifyListeners();
    print('=== SET SIGNED IN STATE END ===\n');
  }

  void setManualSignOff(bool value) {
    print('\n=== SET MANUAL SIGN OFF START ===');
    print('1. Current states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    
    _manualSignOff = value;
    print('2. New states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    print('=== SET MANUAL SIGN OFF END ===\n');
    notifyListeners();
  }
} 