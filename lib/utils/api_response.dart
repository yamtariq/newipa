class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? errorCode;
  final bool requiresDeviceReplacement;
  final bool requiresLogin;
  final Map<String, dynamic>? deviceInfo;

  ApiResponse._({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.requiresDeviceReplacement = false,
    this.requiresLogin = false,
    this.deviceInfo,
  });

  factory ApiResponse.success(Map<String, dynamic> data) {
    return ApiResponse._(
      success: true,
      message: data['message'] ?? 'Operation successful',
      data: data,
    );
  }

  factory ApiResponse.error(String message, {String? errorCode}) {
    return ApiResponse._(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  factory ApiResponse.deviceMismatch(Map<String, dynamic> data) {
    return ApiResponse._(
      success: false,
      message: data['message'] ?? 'Device mismatch detected',
      requiresDeviceReplacement: true,
      deviceInfo: data['device_info'],
    );
  }

  factory ApiResponse.unauthorized(String message) {
    return ApiResponse._(
      success: false,
      message: message,
      errorCode: 'UNAUTHORIZED',
      requiresLogin: true,
    );
  }

  factory ApiResponse.forbidden(String message) {
    return ApiResponse._(
      success: false,
      message: message,
      errorCode: 'FORBIDDEN',
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
  bool get needsDeviceReplacement => requiresDeviceReplacement;
  bool get needsLogin => requiresLogin;
} 