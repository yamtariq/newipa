import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nayifat_app/utils/constants.dart';

class StressTestConfig {
  static const int CONCURRENT_USERS = 100;
  static const int REQUESTS_PER_USER = 50;
  static const Duration TIMEOUT = Duration(seconds: 30);
  
  static const Map<String, int> ENDPOINT_WEIGHTS = {
    'login': 30,
    'loan_decision': 20,
    'cards_decision': 20,
    'master_fetch': 15,
    'user_profile': 15
  };

  static Future<void> performLoadTest(String endpoint, Map<String, String> headers) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(TIMEOUT);
      stopwatch.stop();

      // Log performance metrics
      print('Response time for $endpoint: ${stopwatch.elapsedMilliseconds}ms');
      print('Status code: ${response.statusCode}');
      print('Response size: ${response.bodyBytes.length} bytes');
    } catch (e) {
      print('Error testing $endpoint: $e');
    }
  }
} 