import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DakhliService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 💡 Helper method to format date from Hijri (dd-MM-yyyy) to Gregorian (yyyy-MM-dd)
  String _formatDateForApi(String hijriDate) {
    try {
      // Split the Hijri date
      final parts = hijriDate.split('-');
      if (parts.length != 3) throw Exception('Invalid date format');
      
      // Ensure each part is padded with leading zeros if needed
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2].padLeft(4, '0');
      
      // Return in yyyy-MM-dd format
      return '$year-$month-$day';
    } catch (e) {
      print('❌ Error formatting date: $e');
      throw Exception('Failed to format date: $e');
    }
  }

  // 💡 Fetch salary information from Dakhli API using proxy
  Future<Map<String, dynamic>> fetchSalaryInfo(String nationalId) async {
    try {
      print('\n=== DAKHLI SALARY INFO START ===');
      print('Fetching salary info for National ID: $nationalId');
      
      // Get and format DOB
      final rawDob = await _getDOBFromStorage();
      final formattedDob = _formatDateForApi(rawDob);
      print('💡 Formatted DOB for API: $formattedDob');
      
      // 💡 Prepare proxy request body according to documentation
      final proxyRequest = {
        "targetUrl": 'https://172.22.226.190:4043/api/Dakhli/GetDakhliPubPriv?customerId=${nationalId}&dob=${formattedDob}&reason=CARD',
        "method": "GET",
        "internalHeaders": {
          "Internal-Auth": Constants.bankApiKey,
          "Internal-API-Version": "2.0",
          "Content-Type": "application/json"
        },
        "Body": {
          "customerId": nationalId,
          "dob": formattedDob,
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
          print('Raw data before transformation: ${responseData['result']['data']}');
          
          // Transform the response to our expected format
          final employmentData = responseData['result']['data'] as List;
          
          // 💡 Log each employment record as we process it
          final transformedData = {
            'salaries': employmentData.map((emp) => {
              'amount': emp['payslipInfo']['netSalary'],
              'employer': emp['employerInfo']['agencyName'],
              'status': 'ACTIVE', // Status is implied by presence in response
              'fullName': emp['personalInfo']['employeeNameEn'],
              'workingMonths': _calculateWorkingMonths(emp['employmentInfo']['agencyEmploymentDate']),
              'basicWage': emp['payslipInfo']['basicSalary'],
              'housingAllowance': '0', // Not provided in new response
              'otherAllowance': emp['payslipInfo']['totalAllownces'],
            }).toList(),
          };

          print('Transformed salary data: $transformedData');

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
      print('\n=== GETTING DOB FROM STORAGE START ===');
      String? dob;
      
      // 💡 Initialize both storage types
      final _secureStorage = const FlutterSecureStorage();
      final _sharedPrefs = await SharedPreferences.getInstance();
      
      // First try user_data from both storages
      print('1. Checking user_data in both storages...');
      final userDataStrSS = await _secureStorage.read(key: 'user_data');
      final userDataStrSP = _sharedPrefs.getString('user_data');
      
      // Try SecureStorage user_data
      if (userDataStrSS != null) {
        print('Found user_data in SecureStorage: $userDataStrSS');
        final userData = json.decode(userDataStrSS) as Map<String, dynamic>;
        dob = userData['date_of_birth']?.toString() ?? 
              userData['dateOfBirth']?.toString() ?? 
              userData['dob']?.toString();
        if (dob != null && dob.isNotEmpty) {
          print('✅ Found DOB in SecureStorage user_data: $dob');
          return dob;
        }
      }
      
      // Try SharedPreferences user_data
      if (userDataStrSP != null) {
        print('Found user_data in SharedPreferences: $userDataStrSP');
        final userData = json.decode(userDataStrSP) as Map<String, dynamic>;
        dob = userData['date_of_birth']?.toString() ?? 
              userData['dateOfBirth']?.toString() ?? 
              userData['dob']?.toString();
        if (dob != null && dob.isNotEmpty) {
          print('✅ Found DOB in SharedPreferences user_data: $dob');
          return dob;
        }
      }
      
      print('❌ No DOB found in user_data, checking registration_data...');

      // Try registration_data from both storages
      print('2. Checking registration_data in both storages...');
      final registrationDataStrSS = await _secureStorage.read(key: 'registration_data');
      final registrationDataStrSP = _sharedPrefs.getString('registration_data');
      
      // Try SecureStorage registration_data
      if (registrationDataStrSS != null) {
        print('Found registration_data in SecureStorage: $registrationDataStrSS');
        final registrationData = json.decode(registrationDataStrSS) as Map<String, dynamic>;
        dob = _extractDOBFromRegistrationData(registrationData);
        if (dob != null) return dob;
      }
      
      // Try SharedPreferences registration_data
      if (registrationDataStrSP != null) {
        print('Found registration_data in SharedPreferences: $registrationDataStrSP');
        final registrationData = json.decode(registrationDataStrSP) as Map<String, dynamic>;
        dob = _extractDOBFromRegistrationData(registrationData);
        if (dob != null) return dob;
      }

      print('❌ DOB not found in any storage location');
      throw Exception('Date of birth not found in storage');
    } catch (e) {
      print('❌ Error getting DOB from storage: $e');
      throw Exception('Failed to get date of birth: $e');
    }
  }

  // 💡 Helper method to extract DOB from registration data
  String? _extractDOBFromRegistrationData(Map<String, dynamic> registrationData) {
    // Check in userData object first
    final userDataMap = registrationData['userData'] as Map<String, dynamic>?;
    if (userDataMap != null) {
      print('Found userData object in registration_data');
      final dob = userDataMap['dateOfBirth']?.toString() ?? 
                 userDataMap['date_of_birth']?.toString() ?? 
                 userDataMap['dob']?.toString();
      if (dob != null && dob.isNotEmpty) {
        print('✅ Found DOB in registration_data.userData: $dob');
        return dob;
      }
    }
    
    // Check at root level as fallback
    final rootDob = registrationData['dateOfBirth']?.toString() ?? 
                   registrationData['date_of_birth']?.toString() ?? 
                   registrationData['dob']?.toString();
    if (rootDob != null && rootDob.isNotEmpty) {
      print('✅ Found DOB at registration_data root: $rootDob');
      return rootDob;
    }
    
    return null;
  }

  // 💡 Helper method to calculate working months
  int _calculateWorkingMonths(String startDate) {
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      return ((now.year - start.year) * 12) + (now.month - start.month);
    } catch (e) {
      print('❌ Error calculating working months: $e');
      return 0;
    }
  }
}