import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import 'package:http/io_client.dart';

class DakhliService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // 💡 Create HTTP client that bypasses certificate verification
  http.Client _createUnsafeClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    return IOClient(httpClient);
  }
  
  // 💡 Fetch salary information from Dakhli API
  Future<Map<String, dynamic>> fetchSalaryInfo(String nationalId) async {
    print('🔍 Fetching salary info for National ID: $nationalId');
    final client = _createUnsafeClient();
    
    try {
      // Construct the endpoint URL
      final endpoint = 'https://172.22.226.190:4043/api/Dakhli/GetDakhliPubPriv';
      print('📡 Calling endpoint: $endpoint');

      // Prepare query parameters with the exact format from the example
      final queryParams = {
        'customerId': nationalId,
        'dob': '1975-09-04',  // Using the example date format
        'reason': 'CARD'
      };

      print('📤 Request params: $queryParams');

      // Add timeout to the request
      final response = await client.get(
        Uri.parse(endpoint).replace(queryParameters: queryParams),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⚠️ Request timed out after 30 seconds');
          client.close();
          throw Exception('Request timed out');
        },
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      // Check for empty response body
      if (response.body.isEmpty) {
        print('⚠️ Empty response body received');
        throw Exception('Empty response from server');
      }

      // Try to parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('❌ Failed to parse response body: $e');
        throw Exception('Invalid response format from server');
      } finally {
        client.close();
      }

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Successfully fetched salary data');
          
          // Transform the response to our expected format
          final employmentInfo = responseData['result']['employmentStatusInfo'] as List;
          final transformedData = {
            'salaries': employmentInfo.map((emp) => {
              'amount': (double.parse(emp['basicWage'].toString()) + 
                        double.parse(emp['housingAllowance'].toString()) + 
                        double.parse(emp['otherAllowance'].toString())).toString(),
              'employer': emp['employerName'],
              'status': emp['employmentStatus'],
              'fullName': emp['fullName'],
              'workingMonths': emp['workingMonths'],
              'basicWage': emp['basicWage'],
              'housingAllowance': emp['housingAllowance'],
              'otherAllowance': emp['otherAllowance'],
            }).toList(),
          };

          // Save the transformed response for later use
          await _secureStorage.write(
            key: 'dakhli_salary_data',
            value: json.encode(transformedData),
          );
          print('💾 Saved salary data to secure storage');
          return transformedData;
        } else {
          final errors = responseData['errors'] ?? ['Unknown error occurred'];
          throw Exception('API Error: ${errors.join(', ')}');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in fetchSalaryInfo: ${e.toString()}');
      client.close();
      if (e.toString().contains('SocketException')) {
        throw Exception('Network connection error');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timed out');
      }
      throw Exception('Error fetching salary data: ${e.toString()}');
    }
  }

  // 💡 Get saved salary data
  Future<Map<String, dynamic>?> getSavedSalaryData() async {
    try {
      print('🔍 Retrieving saved salary data');
      final data = await _secureStorage.read(key: 'dakhli_salary_data');
      if (data != null) {
        print('✅ Found saved salary data');
        return json.decode(data);
      }
      print('⚠️ No saved salary data found');
      return null;
    } catch (e) {
      print('❌ Error reading saved salary data: $e');
      return null;
    }
  }
} 