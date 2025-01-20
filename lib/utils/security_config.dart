import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityConfig {
  static const storage = FlutterSecureStorage();
  
  // Encryption key management
  static Future<void> storeSecureKey(String key, String value) async {
    await storage.write(key: key, value: value);
  }
  
  static Future<String?> getSecureKey(String key) async {
    return await storage.read(key: key);
  }
  
  // Data encryption
  static String encryptData(String data, String key) {
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key)));
    final iv = encrypt.IV.fromLength(16);
    return encrypter.encrypt(data, iv: iv).base64;
  }
  
  // Hash sensitive data
  static String hashSensitiveData(String data) {
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Security headers
  static Map<String, String> getSecureHeaders() {
    return {
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Content-Security-Policy': "default-src 'self'",
    };
  }
  
  // Certificate pinning configuration
  static const List<String> validCertificateFingerprints = [
    // Add your API server's certificate fingerprints here
    // Example: "sha256/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="
  ];
  
  // Rate limiting configuration
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  
  // Session management
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const bool requireReauthForSensitiveOperations = true;
  
  // Input validation patterns
  static final RegExp safeInputPattern = RegExp(r'^[a-zA-Z0-9\s\-_\.@]+$');
  static final RegExp phonePattern = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
} 