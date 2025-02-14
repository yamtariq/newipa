import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NafathService {
  static const String baseUrl = 'https://api.nayifat.com/nafath/api/Nafath';

  Future<Map<String, dynamic>> createRequest(String nationalId) async {
    try {
      // 💡 Check for bypass flag
      if (Constants.bypassNafathForTesting) {
        print('\n=== NAFATH BYPASS ENABLED ===');
        print('Returning mock successful response');
        return {
          'success': true,
          'result': {
            'random': '123456',
            'transId': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          }
        };
      }

      print('\n=== NAFATH CREATE REQUEST ===');
      print('National ID: $nationalId');
      print('URL: $baseUrl/CreateRequest');
      
      final response = await http.post(
        Uri.parse('$baseUrl/CreateRequest'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode({
          'nationalId': nationalId,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create Nafath request: ${response.body}');
      }
    } catch (e) {
      print('Error creating Nafath request: $e');
      throw Exception('Error creating Nafath request: $e');
    }
  }

  Future<Map<String, dynamic>> checkRequestStatus(
    String nationalId,
    String transId,
    String random,
  ) async {
    try {
      // 💡 Check for bypass flag
      if (Constants.bypassNafathForTesting) {
        print('\n=== NAFATH BYPASS ENABLED ===');
        print('Returning mock successful status');
        return {
          'success': true,
          'result': {
            'status': 'COMPLETED',
            'transId': transId,
            'random': random,
            'nationalId': nationalId,
          }
        };
      }

      print('\n=== NAFATH STATUS CHECK ===');
      print('National ID: $nationalId');
      print('Transaction ID: $transId');
      print('Random: $random');
      print('URL: $baseUrl/RequestStatus');

      final response = await http.post(
        Uri.parse('$baseUrl/RequestStatus'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode({
          'nationalId': nationalId,
          'transId': transId,
          'random': random,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check Nafath status: ${response.body}');
      }
    } catch (e) {
      print('Error checking Nafath status: $e');
      throw Exception('Error checking Nafath status: $e');
    }
  }
} 