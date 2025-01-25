import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NafathService {
  static const String baseUrl = 'https://api.nayifat.com/nafath/api/Nafath';

  Future<Map<String, dynamic>> createRequest(String nationalId) async {
    try {
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create Nafath request');
      }
    } catch (e) {
      throw Exception('Error creating Nafath request: $e');
    }
  }

  Future<Map<String, dynamic>> checkRequestStatus(
    String nationalId,
    String transId,
    String random,
  ) async {
    try {
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check Nafath status');
      }
    } catch (e) {
      throw Exception('Error checking Nafath status: $e');
    }
  }
} 