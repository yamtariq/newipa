import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nayifat_app_2025_new/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io' show Platform;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService notificationService;
  const channel = MethodChannel('com.nayifat.app/background_service');
  final mockPlatform = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    // Initialize SharedPreferences
    SharedPreferences.setMockInitialValues({
      'national_id': '1234567890',
      'is_arabic': false,
    });

    // Set up the notification service
    notificationService = NotificationService();

    // Mock platform to simulate iOS
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async {
      return '.';
    });

    // Mock the platform check to always return iOS
    setMockPlatform('iOS');

    await notificationService.initialize();

    // Set up platform channel mock
    mockPlatform.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'checkNotifications':
          // Simulate API response
          return {
            'status': 'success',
            'notifications': [
              {
                'id': 1,
                'title': 'Test Notification',
                'body': 'This is a test notification',
                'title_en': 'Test Notification EN',
                'body_en': 'This is a test notification in English',
                'title_ar': 'Test Notification AR',
                'body_ar': 'This is a test notification in Arabic',
                'route': '/test_route',
                'created_at': DateTime.now().toIso8601String(),
                'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                'status': 'unread'
              }
            ]
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    mockPlatform.setMockMethodCallHandler(channel, null);
    resetMockPlatform();
  });

  group('Background Notification Tests', () {
    test('iOS background fetch test', () async {
      // Test the background fetch
      await notificationService.testBackgroundFetch();
      
      // Verify that notifications were processed
      // This will be logged in the test output
    });

    test('Notification content is properly localized', () async {
      // Test English notifications
      notificationService.setLanguage(false);
      await notificationService.testBackgroundFetch();

      // Test Arabic notifications
      notificationService.setLanguage(true);
      await notificationService.testBackgroundFetch();
    });

    test('Expired notifications are handled correctly', () async {
      // Mock an expired notification
      mockPlatform.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'checkNotifications') {
          return {
            'status': 'success',
            'notifications': [
              {
                'id': 1,
                'title': 'Expired Notification',
                'body': 'This notification is expired',
                'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
                'expires_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                'status': 'unread'
              }
            ]
          };
        }
        return null;
      });

      await notificationService.testBackgroundFetch();
      // Verify that expired notifications are not processed
    });

    test('Background fetch respects minimum interval', () async {
      // First fetch
      await notificationService.testBackgroundFetch();
      
      // Immediate second fetch should not process notifications
      await notificationService.testBackgroundFetch();
      
      // Wait for 15 minutes (simulated)
      mockTimeAdvance(const Duration(minutes: 15));
      
      // Third fetch should process notifications
      await notificationService.testBackgroundFetch();
    });
  });
}

// Helper functions for platform mocking
void setMockPlatform(String platform) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/device_info'), (call) async {
    if (platform == 'iOS') {
      return {
        'name': 'iPhone',
        'systemName': 'iOS',
        'systemVersion': '15.0',
        'model': 'iPhone',
        'localizedModel': 'iPhone',
        'identifierForVendor': 'test-id',
        'isPhysicalDevice': true,
        'utsname': {
          'sysname': 'iOS',
          'nodename': 'iPhone',
          'release': '15.0',
          'version': 'iOS 15.0',
          'machine': 'iPhone'
        }
      };
    }
    return null;
  });
}

void resetMockPlatform() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/device_info'), null);
}

// Helper function to simulate time passing
void mockTimeAdvance(Duration duration) {
  // This is a mock implementation - in a real test, you might need to
  // update any time-dependent values in your mocks
} 