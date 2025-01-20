class RegistrationData {
  final String id;
  final String phone;
  final String password;
  final String quickAccessPin;

  RegistrationData({
    required this.id,
    required this.phone,
    required this.password,
    required this.quickAccessPin,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'password': password,
      'quick_access_pin': quickAccessPin,
    };
  }

  factory RegistrationData.fromJson(Map<String, dynamic> json) {
    return RegistrationData(
      id: json['id'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String,
      quickAccessPin: json['quick_access_pin'] as String,
    );
  }
} 