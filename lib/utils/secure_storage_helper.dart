import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecureStorageHelper {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyPrefix = 'secure_';
  late final encrypt.Key _encryptionKey;
  late final encrypt.IV _iv;

  SecureStorageHelper() {
    _initializeEncryption();
  }

  Future<void> _initializeEncryption() async {
    // Get or generate encryption key
    String? storedKey = await _storage.read(key: '${_keyPrefix}encryption_key');
    if (storedKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(key: '${_keyPrefix}encryption_key', value: base64.encode(key.bytes));
      _encryptionKey = key;
    } else {
      _encryptionKey = encrypt.Key(base64.decode(storedKey));
    }

    // Get or generate IV
    String? storedIV = await _storage.read(key: '${_keyPrefix}iv');
    if (storedIV == null) {
      final iv = encrypt.IV.fromSecureRandom(16);
      await _storage.write(key: '${_keyPrefix}iv', value: base64.encode(iv.bytes));
      _iv = iv;
    } else {
      _iv = encrypt.IV(base64.decode(storedIV));
    }
  }

  Future<void> secureWrite(String key, String value) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(value, iv: _iv);
    await _storage.write(key: '$_keyPrefix$key', value: encrypted.base64);
  }

  Future<String?> secureRead(String key) async {
    final encrypted = await _storage.read(key: '$_keyPrefix$key');
    if (encrypted == null) return null;

    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    try {
      final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      return null;
    }
  }

  Future<void> secureDelete(String key) async {
    await _storage.delete(key: '$_keyPrefix$key');
  }

  Future<void> secureDeleteAll() async {
    await _storage.deleteAll();
  }

  Future<bool> secureContainsKey(String key) async {
    return await _storage.containsKey(key: '$_keyPrefix$key');
  }

  Future<Map<String, String>> secureReadAll() async {
    final allValues = await _storage.readAll();
    final Map<String, String> decryptedValues = {};

    for (var entry in allValues.entries) {
      if (entry.key.startsWith(_keyPrefix)) {
        final key = entry.key.substring(_keyPrefix.length);
        final decrypted = await secureRead(key);
        if (decrypted != null) {
          decryptedValues[key] = decrypted;
        }
      }
    }

    return decryptedValues;
  }
} 