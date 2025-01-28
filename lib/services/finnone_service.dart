import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/http_utils.dart';

class FinnoneService {
  static final FinnoneService _instance = FinnoneService._internal();
  factory FinnoneService() => _instance;
  FinnoneService._internal();

  /// Creates a customer in Finnone system
  Future<ApiResponse> createCustomer(String applicationNo) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Finnone/create_customer'),
        headers: await HttpUtils.getHeaders(),
        queryParameters: {'applicationNo': applicationNo},
      );

      final jsonResponse = json.decode(response.body);
      return ApiResponse.fromJson(jsonResponse);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create customer in Finnone: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Checks the status of a Finnone customer creation request
  Future<ApiResponse> checkStatus(String applicationNo) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Finnone/check_status'),
        headers: await HttpUtils.getHeaders(),
        queryParameters: {'applicationNo': applicationNo},
      );

      final jsonResponse = json.decode(response.body);
      return ApiResponse.fromJson(jsonResponse);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to check Finnone status: ${e.toString()}',
        data: null,
      );
    }
  }
} 