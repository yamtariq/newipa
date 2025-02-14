import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import 'package:http/http.dart' as http;

class DakhliService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 💡 Fetch salary information from Dakhli API using proxy
  Future<Map<String, dynamic>> fetchSalaryInfo(String nationalId) async {
    try {
      print('\n=== DAKHLI SALARY INFO START ===');
      print('Fetching salary info for National ID: $nationalId');
      
      // 💡 Prepare proxy request body according to documentation
      final proxyRequest = {
        "targetUrl": 'https://172.22.226.190:4043/api/Dakhli/GetDakhliPubPriv?customerId=${nationalId}&dob=${await _getDOBFromStorage()}&reason=CARD',
        "method": "GET",
        "internalHeaders": {
          "Internal-Auth": Constants.bankApiKey,
          "Internal-API-Version": "2.0",
          "Content-Type": "application/json"
        },
        "Body": {
          "customerId": nationalId,
          "dob": await _getDOBFromStorage(),
          "reason": "CARD"
        }
      };
      
      print('Making proxy API call...');
      print('Endpoint: ${Constants.dakhliSalaryEndpoint}');
      print('Request Body: ${jsonEncode(proxyRequest)}');
      
      final response = await http.post(
        Uri.parse(Constants.dakhliSalaryEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Constants.apiKey,
          'Accept-Charset': 'utf-8'
        },
        body: jsonEncode(proxyRequest)
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Raw Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        
        // 💡 Use dart:convert with UTF8 decoder explicitly
        final responseData = jsonDecode(const Utf8Decoder().convert(response.bodyBytes));
        
        if (responseData['success'] == true) {
          print('Successfully fetched salary data');
          print('Raw employment info before transformation: ${responseData['result']['employmentStatusInfo']}');
          
          // Transform the response to our expected format
          final employmentInfo = responseData['result']['employmentStatusInfo'] as List;
          
          // 💡 Log each employer name as we process it
          for (var emp in employmentInfo) {
            print('Processing employer name: ${emp['employerName']}');
          }
          
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

  // 💡 Helper method to get DOB from storage
  Future<String> _getDOBFromStorage() async {
    try {
      final userDataStr = await _secureStorage.read(key: 'user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr) as Map<String, dynamic>;
        // Try all possible DOB keys in order of preference
        final dob = userData['date_of_birth']?.toString() ?? 
                   userData['dateOfBirth']?.toString() ?? 
                   userData['dob']?.toString();
        if (dob != null && dob.isNotEmpty) {
          return dob;
        }
      }
      throw Exception('Date of birth not found in storage');
    } catch (e) {
      print('Error getting DOB from storage: $e');
      throw Exception('Failed to get date of birth: $e');
    }
  }
}