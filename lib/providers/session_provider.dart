import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class SessionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isSignedIn = false;
  bool _manualSignOff = false;  // Track if user manually signed off
  bool get isSignedIn => _isSignedIn;

  // Initialize the session state
  Future<void> initializeSession() async {
    try {
      print('\n=== SESSION PROVIDER INITIALIZE START ===');
      print('1. Current states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - manualSignOff: $_manualSignOff');

      if (_manualSignOff) {
        print('2. Manual sign off is true, skipping initialization');
        return;
      }

      print('3. Fetching user data and session status');
      final userData = await _authService.getUserData();
      final sessionFromAuth = await _authService.isSessionActive();
      final sessionFromProps = userData?['isSessionActive'] ?? false;
      
      print('4. Session status:');
      print('   - User Data: $userData');
      print('   - Session from Auth: $sessionFromAuth');
      print('   - Session from Props: $sessionFromProps');

      _isSignedIn = sessionFromAuth || sessionFromProps;
      print('5. New isSignedIn state: $_isSignedIn');
      
      print('6. Notifying listeners');
      notifyListeners();
      print('=== SESSION PROVIDER INITIALIZE END ===\n');
    } catch (e) {
      print('\n!!! ERROR IN SESSION PROVIDER INITIALIZE !!!');
      print('Error details: $e');
      _isSignedIn = false;
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

      if (_manualSignOff) {
        print('2. Manual sign off is true, skipping check');
        return;
      }

      print('3. Fetching user data and session status');
      final userData = await _authService.getUserData();
      final sessionFromAuth = await _authService.isSessionActive();
      final sessionFromProps = userData?['isSessionActive'] ?? false;
      final newSignedInState = sessionFromAuth || sessionFromProps;
      
      print('4. Session status:');
      print('   - User Data: $userData');
      print('   - Session from Auth: $sessionFromAuth');
      print('   - Session from Props: $sessionFromProps');
      print('   - New State: $newSignedInState');
      
      if (newSignedInState != _isSignedIn) {
        print('5. State change detected');
        print('   - Old state: $_isSignedIn');
        print('   - New state: $newSignedInState');
        _isSignedIn = newSignedInState;
        notifyListeners();
        print('6. Listeners notified of state change');
      } else {
        print('5. No state change needed');
      }
      print('=== SESSION PROVIDER CHECK END ===\n');
    } catch (e) {
      print('\n!!! ERROR IN SESSION PROVIDER CHECK !!!');
      print('Error details: $e');
      if (_isSignedIn) {
        _isSignedIn = false;
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
      
      print('2. Calling AuthService.signOff()');
      await _authService.signOff();
      print('3. AuthService.signOff() completed');
      
      print('4. Updating provider state');
      _isSignedIn = false;
      _manualSignOff = true;
      print('5. New states:');
      print('   - isSignedIn: $_isSignedIn');
      print('   - manualSignOff: $_manualSignOff');
      
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
    
    _manualSignOff = false;
    print('2. New states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('=== RESET MANUAL SIGN OFF END ===\n');
  }

  // Set signed in state explicitly
  void setSignedIn(bool value) {
    print('\n=== SET SIGNED IN STATE START ===');
    print('1. Current states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    print('   - Requested state: $value');
    
    _isSignedIn = value;
    if (value) {
      _manualSignOff = false;
    }
    
    print('2. New states:');
    print('   - isSignedIn: $_isSignedIn');
    print('   - manualSignOff: $_manualSignOff');
    
    print('3. Notifying listeners');
    notifyListeners();
    print('=== SET SIGNED IN STATE END ===\n');
  }
} 