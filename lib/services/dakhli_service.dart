import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class DakhliService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Fetch salary information from Dakhli API
  Future<Map<String, dynamic>> fetchSalaryInfo(String nationalId) async {
    HttpClient? client;
    try {
      print('\n=== DAKHLI SALARY INFO START ===');
      print('Fetching salary info for National ID: $nationalId');
      
      final dob = '1975-09-04';  // Using the example date format
      final reason = 'CARD';
      
      final uri = Uri.parse(Constants.dakhliSalaryEndpoint);
      print('Target URL: $uri');
      
      // Create HttpClient with SSL bypass like in AuthService
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      print('Making API call...');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.add('Accept', 'application/json');
      request.headers.add('x-api-key', Constants.apiKey);
      Constants.authHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      // Send request body
      final requestBody = jsonEncode({
        'customerId': nationalId,
        'dob': dob,
        'reason': reason,
      });
      print('Request Body: $requestBody');
      request.write(requestBody);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: $responseBody');
      
      if (response.statusCode == 200) {
        if (responseBody.isEmpty) {
          throw Exception('Empty response body');
        }
        final responseData = jsonDecode(responseBody);
        if (responseData['success'] == true) {
          print('Successfully fetched salary data');
          
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
          print('Saved salary data to secure storage');
          print('=== DAKHLI SALARY INFO END ===\n');
          return transformedData;
        } else {
          final errors = responseData['errors'] ?? ['Unknown error occurred'];
          throw Exception('API Error: ${errors.join(', ')}');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchSalaryInfo: ${e.toString()}');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network connection error');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timed out');
      }
      throw Exception('Error fetching salary data: ${e.toString()}');
    } finally {
      client?.close();
    }
  }

  // Get saved salary data
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