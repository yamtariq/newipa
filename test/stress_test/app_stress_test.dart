import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nayifat_app/utils/constants.dart';
import 'stress_test_config.dart';

void main() {
  group('App Stress Tests', () {
    test('Concurrent User Load Test', () async {
      final futures = <Future>[];
      
      // Simulate concurrent users
      for (var i = 0; i < StressTestConfig.CONCURRENT_USERS; i++) {
        futures.add(_simulateUserSession());
      }
      
      await Future.wait(futures);
    });
    
    test('API Endpoint Performance Test', () async {
      final endpoints = {
        'masterFetch': masterFetchUrl,
        'loanDecision': '$apiBaseUrl/loan_decision.php',
        'cardsDecision': '$apiBaseUrl/cards_decision.php',
      };
      
      for (var entry in endpoints.entries) {
        await StressTestConfig.performLoadTest(
          entry.value,
          defaultHeaders,
        );
      }
    });
  });
}

Future<void> _simulateUserSession() async {
  try {
    // Simulate user journey
    await StressTestConfig.performLoadTest(
      '$apiBaseUrl/signin.php',
      authHeaders,
    );
    
    // Random delay between requests (100-500ms)
    await Future.delayed(Duration(milliseconds: 100 + (400 * DateTime.now().millisecondsSinceEpoch % 5).toInt()));
    
    await StressTestConfig.performLoadTest(
      masterFetchUrl,
      defaultHeaders,
    );
  } catch (e) {
    print('User session simulation error: $e');
  }
} 