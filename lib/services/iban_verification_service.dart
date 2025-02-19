import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IbanVerificationService {
  final String baseUrl = 'https://tmappuat.nayifat.com/api/proxy/forward';
  final _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> verifyIban(String iban) async {
    try {
      print('\n=== IBAN VERIFICATION SERVICE START ===');
      print('Verifying IBAN: $iban');

      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': '7ca7427b418bdbd0b3b23d7debf69bf7',
      };

      final body = {
        'TargetUrl': 'http://172.22.226.189:3000/ibanverification',
        'Method': 'POST',
        'InternalHeaders': {
          'Content-Type': 'application/json',
          'Authorization': 'Basic TmF5aWZhdDpOYXlpZmF0QDIwMjM=',
          'X-API-ID': '3162C93C-3C9E-4613-A4D9-53BF99BB9CB1',
          'X-API-KEY': 'A624BA39-BFDA-4F09-829C-9F6294D6DF23',
          'X-Organization-No': 'Nayifat',
        },
        'Body': {
          'identification_number': '1064448614',
          'iban': iban,
        },
      };

      print('Request headers: $headers');
      print('Request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');
        
        if (responseData['status'] == 'INVALID_PARAMETERS') {
          print('Invalid IBAN format detected');
          return {
            'success': false,
            'error': 'Invalid IBAN number',
            'error_ar': 'رقم الآيبان غير صحيح',
            'errorType': 'invalid_iban'
          };
        }
        
        if (responseData['status'] == 'FAILED') {
          print('Bank error: ${responseData['message']}');
          return {
            'success': false,
            'error': responseData['message'] ?? 'Bank verification failed',
            'error_ar': 'فشل التحقق من البنك',
            'errorType': 'bank_error'
          };
        }
        
        if (responseData['status'] == 'OK') {
          final verifications = responseData['verifications'];
          print('Verifications data: $verifications');
          
          if (verifications['account_status'] != 'ACTIVE') {
            print('Account not active: ${verifications['account_status']}');
            return {
              'success': false,
              'error': 'Bank account is not active',
              'error_ar': 'الحساب البنكي غير نشط',
              'errorType': 'inactive_account'
            };
          }
          
          print('Verification successful');
          return {
            'success': true,
            'data': verifications
          };
        }
        
        print('Unexpected response format');
        return {
          'success': false,
          'error': 'Unexpected response from bank',
          'error_ar': 'استجابة غير متوقعة من البنك',
          'errorType': 'unknown'
        };
      }
      
      print('Server error: ${response.statusCode}');
      return {
        'success': false,
        'error': 'Server error (${response.statusCode})',
        'error_ar': 'خطأ في النظام',
        'errorType': 'server_error'
      };
    } catch (e, stackTrace) {
      print('Error in IBAN verification: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Connection error, please try again',
        'error_ar': 'خطأ في الاتصال، يرجى المحاولة مرة أخرى',
        'errorType': 'network_error'
      };
    } finally {
      print('=== IBAN VERIFICATION SERVICE END ===\n');
    }
  }
} 