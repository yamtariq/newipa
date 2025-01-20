import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../models/registration_data.dart';

enum RegistrationStep {
  idAndPhone,
  otpVerification,
  passwordCreation,
  mpinCreation,
  biometricSetup,
  completed
}

class RegistrationProvider extends ChangeNotifier {
  RegistrationStep _currentStep = RegistrationStep.idAndPhone;
  String? _id;
  String? _phone;
  String? _password;
  String? _mpin;
  bool _isBiometricEnabled = false;
  bool _isLoading = false;
  String? _error;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Getters
  RegistrationStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBiometricEnabled => _isBiometricEnabled;
  double get progress {
    switch (_currentStep) {
      case RegistrationStep.idAndPhone:
        return 0.2;
      case RegistrationStep.otpVerification:
        return 0.4;
      case RegistrationStep.passwordCreation:
        return 0.6;
      case RegistrationStep.mpinCreation:
        return 0.8;
      case RegistrationStep.biometricSetup:
        return 0.9;
      case RegistrationStep.completed:
        return 1.0;
    }
  }

  // Methods to update state
  void setIdAndPhone(String id, String phone) {
    _id = id;
    _phone = phone;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  void setMpin(String mpin) {
    _mpin = mpin;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep != RegistrationStep.completed) {
      _currentStep = RegistrationStep.values[_currentStep.index + 1];
      notifyListeners();
    }
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Biometric authentication
  Future<bool> checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (e) {
      setError('Failed to check biometric availability: ${e.message}');
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        _isBiometricEnabled = true;
        notifyListeners();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      setError('Failed to enable biometric: ${e.message}');
      return false;
    }
  }

  // Get registration data
  RegistrationData? getRegistrationData() {
    if (_id != null && _phone != null && _password != null && _mpin != null) {
      return RegistrationData(
        id: _id!,
        phone: _phone!,
        password: _password!,
        quickAccessPin: _mpin!,
      );
    }
    return null;
  }

  // Reset registration
  void reset() {
    _currentStep = RegistrationStep.idAndPhone;
    _id = null;
    _phone = null;
    _password = null;
    _mpin = null;
    _isBiometricEnabled = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
} 