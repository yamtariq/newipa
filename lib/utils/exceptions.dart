class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

class MPINLockedException implements Exception {
  final String message;
  final DateTime? lockedUntil;

  MPINLockedException(this.message, {this.lockedUntil});

  @override
  String toString() => 'MPINLockedException: $message';
}

class DeviceInfoException implements Exception {
  final String message;

  DeviceInfoException(this.message);

  @override
  String toString() => 'DeviceInfoException: $message';
}

class BiometricException implements Exception {
  final String message;
  final BiometricErrorType type;

  BiometricException(this.message, this.type);

  @override
  String toString() => 'BiometricException: $message (Type: $type)';
}

enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  lockedOut,
  other
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class StorageException implements Exception {
  final String message;
  final String? key;

  StorageException(this.message, {this.key});

  @override
  String toString() => 'StorageException: $message${key != null ? ' (Key: $key)' : ''}';
}

class SessionException implements Exception {
  final String message;
  final bool requiresReauthentication;

  SessionException(this.message, {this.requiresReauthentication = false});

  @override
  String toString() => 'SessionException: $message';
}

class DeviceRegistrationException implements Exception {
  final String message;
  final Map<String, dynamic>? existingDevice;

  DeviceRegistrationException(this.message, {this.existingDevice});

  @override
  String toString() => 'DeviceRegistrationException: $message';
} 