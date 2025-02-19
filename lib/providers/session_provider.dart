import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

      if (_manualSignOff) {
        print('2. Manual sign off is true, skipping initialization');
        return;
      }

      print('3. Checking session state in storage');
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = const FlutterSecureStorage();
      
      // Check session state in both storages
      final secureSessionActive = await secureStorage.read(key: 'session_active') == 'true';
      final prefsSessionActive = prefs.getBool('session_active') ?? false;
      
      // If either storage indicates an active session, consider it active
      final hasActiveSessionState = secureSessionActive || prefsSessionActive;
      
      print('4. Session status:');
      print('   - Secure Storage Session: $secureSessionActive');
      print('   - SharedPreferences Session: $prefsSessionActive');
      print('   - Final Session State: $hasActiveSessionState');

      // Update state if needed
      if (hasActiveSessionState != _hasActiveSession || hasActiveSessionState != _isSignedIn) {
        _hasActiveSession = hasActiveSessionState;
        _isSignedIn = hasActiveSessionState;
        print('5. State updated:');
        print('   - isSignedIn: $_isSignedIn');
        print('   - hasActiveSession: $_hasActiveSession');
        notifyListeners();
      }
      
      print('=== SESSION PROVIDER INITIALIZE END ===\n');
    } catch (e) {
      print('\n!!! ERROR IN SESSION PROVIDER INITIALIZE !!!');
      print('Error details: $e');
      _isSignedIn = false;
      _hasActiveSession = false;
      notifyListeners();
      print('Session state reset to false due to error');
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
        print('2. Manual sign off is true, keeping current state');
        return;
      }

      print('3. Checking session state in storage');
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = const FlutterSecureStorage();
      
      // Check session state in both storages
      final secureSessionActive = await secureStorage.read(key: 'session_active') == 'true';
      final prefsSessionActive = prefs.getBool('session_active') ?? false;
      
      // If either storage indicates an active session, consider it active
      final hasActiveSessionState = secureSessionActive || prefsSessionActive;
      
      print('4. Session status:');
      print('   - Secure Storage Session: $secureSessionActive');
      print('   - SharedPreferences Session: $prefsSessionActive');
      print('   - Final Session State: $hasActiveSessionState');

      // Update state if needed
      if (hasActiveSessionState != _hasActiveSession || hasActiveSessionState != _isSignedIn) {
        _hasActiveSession = hasActiveSessionState;
        _isSignedIn = hasActiveSessionState;
        print('5. State updated:');
        print('   - isSignedIn: $_isSignedIn');
        print('   - hasActiveSession: $_hasActiveSession');
        notifyListeners();
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
      
      print('2. Clearing session state from storage');
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = const FlutterSecureStorage();
      
      await secureStorage.delete(key: 'session_active');
      await secureStorage.delete(key: 'session_user_id');
      await prefs.remove('session_active');
      await prefs.remove('session_user_id');
      
      print('3. Calling AuthService.signOff()');
      await _authService.signOff();
      
      print('4. Updating provider state');
      _hasActiveSession = false;
      _isSignedIn = false;
      _manualSignOff = true;
      
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
  void resetManualSignOff() {
    print('\n=== RESET MANUAL SIGN OFF START ===');
    print('1. Current states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    
    _manualSignOff = false;
    print('2. New states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - hasActiveSession: $_hasActiveSession');
    print('=== RESET MANUAL SIGN OFF END ===\n');
  }

  // Set signed in state explicitly
  void setSignedIn(bool value) {
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