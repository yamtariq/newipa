import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/branch.dart';

class BranchService {
  static const String _baseUrl = 'YOUR_API_BASE_URL';

  Future<List<Branch>> getBranches() async {
    try {
      // This is temporary mock data until you have the actual API endpoint
      final mockData = [
        {
          "nameEn": "Riyadh Main Branch",
          "nameAr": "فرع الرياض الرئيسي",
          "latitude": 24.7136,
          "longitude": 46.6753
        },
        {
          "nameEn": "Makkah Branch",
          "nameAr": "فرع مكة المكرمة",
          "latitude": 21.3891,
          "longitude": 39.8579
        },
        {
          "nameEn": "Dammam Branch",
          "nameAr": "فرع الدمام",
          "latitude": 26.4207,
          "longitude": 50.0888
        },
        {
          "nameEn": "Jeddah Branch",
          "nameAr": "فرع جدة",
          "latitude": 21.5433,
          "longitude": 39.1728
        },
        {
          "nameEn": "Medina Branch",
          "nameAr": "فرع المدينة المنورة",
          "latitude": 24.4672,
          "longitude": 39.6142
        }
      ];

      // When you have the actual API endpoint, replace the mock with this:
      // final response = await http.get(Uri.parse('$_baseUrl/branches'));
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.map((json) => Branch.fromJson(json)).toList();
      // }

      // For now, return mock data
      return mockData.map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load branches: $e');
    }
  }
} 