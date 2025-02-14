import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ConstantsService {
  static Future<Map<String, dynamic>> getAllConstants() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/constants'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiEndpoints.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return Map.fromEntries(
            (data['data'] as List).map((constant) => MapEntry(
              constant['name'] as String,
              {
                'value': constant['value'],
                'valueAr': constant['valueAr'],
                'description': constant['description'],
                'lastUpdated': DateTime.parse(constant['lastUpdated']),
              },
            )),
          );
        }
        throw Exception(data['error'] ?? 'Failed to load constants');
      }
      throw Exception('Failed to load constants');
    } catch (e) {
      throw Exception('Failed to load constants: $e');
    }
  }

  static Future<Map<String, dynamic>> getConstant(String name) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/constants/$name'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiEndpoints.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final constant = data['data'];
          return {
            'value': constant['value'],
            'valueAr': constant['valueAr'],
            'description': constant['description'],
            'lastUpdated': DateTime.parse(constant['lastUpdated']),
          };
        }
        throw Exception(data['error'] ?? 'Constant not found');
      }
      throw Exception('Failed to load constant');
    } catch (e) {
      throw Exception('Failed to load constant: $e');
    }
  }
} 