import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/slide.dart';
import '../models/contact_details.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final bool useMockData = false;

  // Check if API is reachable
  Future<bool> isApiReachable() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.masterFetchUrl),
        headers: Constants.defaultHeaders,
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get default slides based on language
  List<Slide> getDefaultSlides({bool isArabic = false}) {
    if (isArabic) {
      return [
        Slide(
          id: 1,
          imageUrl: 'assets/images/slide1.jpg',
          link: '/Loans',
          leftTitle: 'تقدم بطلبك الان',
          rightTitle: 'التمويل الشخصي',
        ),
        Slide(
          id: 2,
          imageUrl: 'assets/images/slide2.jpg',
          link: '/Cards',
          leftTitle: 'اطلبها الآن',
          rightTitle: 'البطاقات الائتمانية',
        ),
        Slide(
          id: 3,
          imageUrl: 'assets/images/slide3.jpg',
          link: 'https://nayifat.com/',
          leftTitle: 'Special Offers',
          rightTitle: 'More info',
        ),
      ];
    } else {
      return [
        Slide(
          id: 1,
          imageUrl: 'assets/images/slide1.jpg',
          link: '/Loans',
          leftTitle: 'Personal Loans',
          rightTitle: 'Apply now',
        ),
        Slide(
          id: 2,
          imageUrl: 'assets/images/slide2.jpg',
          link: '/Cards',
          leftTitle: 'Credit Card',
          rightTitle: 'Apply now',
        ),
        Slide(
          id: 3,
          imageUrl: 'assets/images/slide3.jpg',
          link: 'https://nayifat.com/',
          leftTitle: 'Special Offers',
          rightTitle: 'More info',
        ),
      ];
    }
  }

  // Get default contact details
  ContactDetails getDefaultContactDetails({bool isArabic = false}) {
    return ContactDetails(
      email: 'CustomerCare@nayifat.com',
      phone: '8001000088',
      workHours: '',
      socialLinks: {
        'linkedin': 'https://www.linkedin.com/company/nayifat-instalment-company',
        'instagram': 'https://www.instagram.com/nayifatcompany',
        'twitter': 'https://twitter.com/nayifatco',
        'facebook': 'https://www.facebook.com/nayifatcompany',
      },
    );
  }

  // Registration Step 1: Validate ID and Phone
  Future<Map<String, dynamic>> validateUserIdentity(String id, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointValidateIdentity}'),
        body: json.encode({
          'id': id,
          'phone': phone,
        }),
        headers: Constants.authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to validate identity: ${response.statusCode}');
      }
    } catch (e) {
      print('Error validating identity: $e');
      throw Exception('Network error: $e');
    }
  }

  // Registration Step 2: Set Password
  Future<Map<String, dynamic>> setPassword(String id, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointSetPassword}'),
        body: json.encode({
          'id': id,
          'password': password,
        }),
        headers: Constants.authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to set password: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting password: $e');
      throw Exception('Network error: $e');
    }
  }

  // Registration Step 3: Set Quick Access PIN
  Future<Map<String, dynamic>> setQuickAccessPin(String id, String pin) async {
    try {
      // MPIN is now stored only locally, no API call needed
      return {
        'success': true,
        'message': 'MPIN stored locally'
      };
    } catch (e) {
      print('Error with MPIN: $e');
      throw Exception('Error: $e');
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String id, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointVerifyOtp}'),
        body: json.encode({
          'id': id,
          'otp': otp,
        }),
        headers: Constants.authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      throw Exception('Network error: $e');
    }
  }

  // Resend OTP
  Future<void> resendOtp(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointResendOtp}'),
        body: json.encode({
          'id': id,
        }),
        headers: Constants.authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to resend OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error resending OTP: $e');
      throw Exception('Network error: $e');
    }
  }

  // Fetch slides based on language
  Future<List<Slide>> getSlides({bool isArabic = false}) async {
    if (useMockData || !await isApiReachable()) {
      return getDefaultSlides(isArabic: isArabic);
    }

    try {
      final uri = Uri.parse(Constants.masterFetchUrl).replace(
        queryParameters: {
          'page': 'home',
          'key_name': isArabic ? 'slideshow_content_ar' : 'slideshow_content',
        },
      );

      final response = await http.get(
        uri,
        headers: Constants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> slidesData = responseData['data'];
          return slidesData.map((item) => Slide.fromJson(Map<String, dynamic>.from(item))).toList();
        }
        return getDefaultSlides(isArabic: isArabic);
      } else {
        return getDefaultSlides(isArabic: isArabic);
      }
    } catch (e) {
      print('Error loading slides: $e');
      return getDefaultSlides(isArabic: isArabic);
    }
  }

  // Fetch contact details
  Future<ContactDetails> getContactDetails({bool isArabic = false}) async {
    if (useMockData || !await isApiReachable()) {
      return getDefaultContactDetails(isArabic: isArabic);
    }

    try {
      final uri = Uri.parse(Constants.masterFetchUrl).replace(
        queryParameters: {
          'page': 'home',
          'key_name': isArabic ? 'contact_details_ar' : 'contact_details',
        },
      );

      final response = await http.get(
        uri,
        headers: Constants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        if (response.body.trim().toLowerCase().startsWith('<!doctype')) {
          return getDefaultContactDetails(isArabic: isArabic);
        }

        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return ContactDetails.fromJson(responseData['data']);
        } else {
          return getDefaultContactDetails(isArabic: isArabic);
        }
      } else {
        return getDefaultContactDetails(isArabic: isArabic);
      }
    } catch (e) {
      print('Error loading contact details: $e');
      return getDefaultContactDetails(isArabic: isArabic);
    }
  }

  // Fetch master configuration
  Future<Map<String, dynamic>> fetchMasterConfig(String page, String key_name) async {
    try {
      final uri = Uri.parse(Constants.masterFetchUrl).replace(
        queryParameters: {
          'page': page,
          'key_name': key_name,
        },
      );

      final response = await http.get(
        uri,
        headers: Constants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'data': data['data'] ?? {},
        };
      }
      return {'success': false, 'data': {}};
    } catch (e) {
      print('Error fetching master config: $e');
      return {'success': false, 'data': {}};
    }
  }

  Future<CustomerCareResponse> submitCustomerCare(CustomerCareRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.authBaseUrl}${Constants.endpointSubmitCustomerCare}'),
        body: json.encode(request.toJson()),
        headers: Constants.authHeaders,
      );

      if (response.statusCode == 200) {
        return CustomerCareResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to submit request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting customer care: $e');
      return CustomerCareResponse(
        success: false,
        message: 'Failed to submit request. Please try again.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String nationalId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/notifications/list'),
        headers: {
          ...Constants.defaultHeaders,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nationalId': nationalId,
          'markAsRead': false,
        }),
      );

      if (response.statusCode != 200) {
        throw ApiException('Failed to fetch notifications: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }
}

class CustomerCareRequest {
  final String nationalId;
  final String phone;
  final String customerName;
  final String subject;
  final String? subSubject;
  final String complaint;

  CustomerCareRequest({
    required this.nationalId,
    required this.phone,
    required this.customerName,
    required this.subject,
    this.subSubject,
    required this.complaint,
  });

  Map<String, dynamic> toJson() => {
    'nationalId': nationalId,
    'phone': phone,
    'customerName': customerName,
    'subject': subject,
    'subSubject': subSubject,
    'complaint': complaint,
  };
}

class CustomerCareResponse {
  final bool success;
  final String? complaintNumber;
  final String message;

  CustomerCareResponse({
    required this.success,
    this.complaintNumber,
    required this.message,
  });

  factory CustomerCareResponse.fromJson(Map<String, dynamic> json) {
    return CustomerCareResponse(
      success: json['success'] ?? false,
      complaintNumber: json['complaintNumber']?.toString(),
      message: json['message'] ?? '',
    );
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}