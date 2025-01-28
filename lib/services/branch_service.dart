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
          "nameEn": "Khurais Branch",
          "nameAr": "فرع خريص",
          "latitude": 24.7255,
          "longitude": 46.7736,
          "address": "Khurais Road after Al Nahda Street"
        },
        {
          "nameEn": "Al Badi'ah Branch",
          "nameAr": "فرع البديعة",
          "latitude": 24.6212,
          "longitude": 46.6167,
          "address": "Western Ring Road, Exit 27"
        },
        {
          "nameEn": "Exit 10 Branch",
          "nameAr": "فرع مخرج 10",
          "latitude": 24.7525,
          "longitude": 46.7281,
          "address": "Al-Quds District, King Abdullah Road, Exit 10"
        },
        {
          "nameEn": "Olaya Branch",
          "nameAr": "فرع العليا",
          "latitude": 24.7136,
          "longitude": 46.6753,
          "address": "Al-Wurud District, Olaya Main Street, intersection with King Abdullah Road"
        },
        {
          "nameEn": "Al Duwadimi Branch",
          "nameAr": "فرع الدوادمي",
          "latitude": 24.5114,
          "longitude": 44.4057,
          "address": "King Abdulaziz Road"
        },
        {
          "nameEn": "Hail Branch",
          "nameAr": "فرع حائل",
          "latitude": 27.5114,
          "longitude": 41.7208,
          "address": "King Fahd Road, Al-Wasita, Hail"
        },
        {
          "nameEn": "Al-Qassim Branch",
          "nameAr": "فرع القصيم",
          "latitude": 26.3285,
          "longitude": 43.9750,
          "address": "Bukhari Street"
        },
        {
          "nameEn": "Al-Kharj Branch",
          "nameAr": "فرع الخرج",
          "latitude": 24.1556,
          "longitude": 47.3343,
          "address": "King Abdulaziz Road, Al-Kharj"
        },
        {
          "nameEn": "Al Majma'ah Branch",
          "nameAr": "فرع المجمعة",
          "latitude": 25.8976,
          "longitude": 45.3607,
          "address": "Al-Ma'athar Street, Al-Marqab, Al-Majma'ah"
        },
        {
          "nameEn": "Najran Branch",
          "nameAr": "فرع نجران",
          "latitude": 17.4917,
          "longitude": 44.1322,
          "address": "King Abdulaziz Road – Najran"
        },
        {
          "nameEn": "Jizan Branch",
          "nameAr": "فرع جازان",
          "latitude": 16.8895,
          "longitude": 42.5510,
          "address": "Corniche Road"
        },
        {
          "nameEn": "Al Bahah Branch",
          "nameAr": "فرع الباحة",
          "latitude": 20.0129,
          "longitude": 41.4677,
          "address": "King Fahd Road"
        },
        {
          "nameEn": "Abha Branch",
          "nameAr": "فرع أبها",
          "latitude": 18.2164,
          "longitude": 42.5053,
          "address": "Abha"
        },
        {
          "nameEn": "Bisha Branch",
          "nameAr": "فرع بيشة",
          "latitude": 20.0000,
          "longitude": 42.6000,
          "address": "King Saud bin Abdulaziz Street, next to the Civil Status Office"
        },
        {
          "nameEn": "Jeddah Main Branch",
          "nameAr": "فرع جدة الرئيسي",
          "latitude": 21.5435,
          "longitude": 39.1728,
          "address": "Al Andalus Branch Road heading towards King Abdul Aziz Road"
        },
        {
          "nameEn": "Al Madinah Al Munawwarah Branch",
          "nameAr": "فرع المدينة المنورة",
          "latitude": 24.5247,
          "longitude": 39.5692,
          "address": "Al Andalus Branch Road heading towards King Abdul Aziz Road"
        },
        {
          "nameEn": "Mecca Branch",
          "nameAr": "فرع مكة المكرمة",
          "latitude": 21.3891,
          "longitude": 39.8579,
          "address": "Batha Quraysh Road"
        },
        {
          "nameEn": "Tabuk Branch",
          "nameAr": "فرع تبوك",
          "latitude": 28.3838,
          "longitude": 36.5549,
          "address": "King Fahd Road"
        },
        {
          "nameEn": "Taif Branch",
          "nameAr": "فرع الطائف",
          "latitude": 21.2703,
          "longitude": 40.4158,
          "address": "Abdullah Suleiman Street, Al-Fayhaa District"
        },
        {
          "nameEn": "Jubail Branch",
          "nameAr": "فرع الجبيل",
          "latitude": 27.0046,
          "longitude": 49.6583,
          "address": "King Abdul Aziz Street, near SABB Bank"
        },
        {
          "nameEn": "Hafr Al-Batin Branch",
          "nameAr": "فرع حفر الباطن",
          "latitude": 28.4328,
          "longitude": 45.9708,
          "address": "King Abdulaziz Road, opposite the Arab National Bank"
        },
        {
          "nameEn": "Hofuf Branch",
          "nameAr": "فرع الهفوف",
          "latitude": 25.3833,
          "longitude": 49.6000,
          "address": "Al-Mahasen District, Makkah Al-Mukarramah Road, Al-Hofuf"
        },
        {
          "nameEn": "Dammam Branch",
          "nameAr": "فرع الدمام",
          "latitude": 26.4207,
          "longitude": 50.0888,
          "address": "Western Beach neighborhood, Gulf Road, Dammam"
        },
        {
          "nameEn": "Sakaka Branch",
          "nameAr": "فرع سكاكا",
          "latitude": 29.953894,
          "longitude": 40.197044,
          "address": "King Fahd bin Abdulaziz Road, Al Sina'iyah Subdivision"
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