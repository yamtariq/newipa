class RegistrationConstants {
  // Password Rules (2025 NIST Guidelines)
  static const int minPasswordLength = 12;
  static const int maxPasswordLength = 64;
  static const String passwordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,64}$';
  static const String passwordRequirements = '''
    • At least 12 characters long
    • Maximum 64 characters
    • At least one uppercase letter
    • At least one lowercase letter
    • At least one number
    • At least one special character (@\$!%*?&)
  ''';

  // MPIN Rules
  static const int mpinLength = 6; // 6-digit MPIN for enhanced security
  static const String mpinPattern = r'^\d{6}$';

  // OTP Rules
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;

  // Validation Messages
  static const String invalidIdMessage = 'Please enter a valid ID number';
  static const String invalidPhoneMessage = 'Please enter a valid mobile number';
  static const String invalidPasswordMessage = 'Password does not meet the requirements';
  static const String invalidMpinMessage = 'MPIN must be 6 digits';
  static const String invalidOtpMessage = 'Please enter a valid 6-digit OTP';
} 