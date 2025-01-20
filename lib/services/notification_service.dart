import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import './navigation_service.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;
  bool _isArabic = false;
  Timer? _iosBackgroundTimer;
  
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static const platform = MethodChannel('com.nayifat.nayifat_app_2025_new/background_service');

  Future<void> startBackgroundService() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('startBackgroundService');
        debugPrint('Android background service started');
      } else if (Platform.isIOS) {
        // Start iOS background fetch
        _startIOSBackgroundFetch();
        debugPrint('iOS background fetch started');
      }
    } catch (e) {
      debugPrint('Error starting background service: $e');
    }
  }

  Future<void> stopBackgroundService() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('stopBackgroundService');
        debugPrint('Android background service stopped');
      } else if (Platform.isIOS) {
        _iosBackgroundTimer?.cancel();
        debugPrint('iOS background fetch stopped');
      }
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }

  void _startIOSBackgroundFetch() {
    // Cancel any existing timer
    _iosBackgroundTimer?.cancel();
    
    // Create a new timer that runs every 15 minutes
    _iosBackgroundTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final bool canFetch = await _canPerformBackgroundFetch();
      if (canFetch) {
        await _checkForNewNotifications();
      }
    });
  }

  Future<bool> _canPerformBackgroundFetch() async {
    if (!Platform.isIOS) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt('last_fetch_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Check if at least 15 minutes have passed since the last fetch
    if (currentTime - lastFetchTime >= const Duration(minutes: 15).inMilliseconds) {
      await prefs.setInt('last_fetch_time', currentTime);
      return true;
    }
    
    return false;
  }

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  Future<void> initialize() async {
    debugPrint('Initializing NotificationService...');
    
    try {
      // Set up method channel handler for iOS background fetch
      platform.setMethodCallHandler((call) async {
        if (call.method == 'checkNotifications') {
          await _checkForNewNotifications();
        }
      });

      await AwesomeNotifications().initialize(
        'resource://mipmap/launcher_icon', // Use the app icon for notifications
        [
          NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic notifications',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            channelShowBadge: true,
            importance: NotificationImportance.High,
            criticalAlerts: true,
            defaultRingtoneType: DefaultRingtoneType.Notification
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group'
          )
        ],
        debug: true
      );

      // Request all necessary permissions
      debugPrint('Requesting notification permissions...');
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.CriticalAlert,
        ]
      );
      
      debugPrint('Setting up notification listeners...');
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod
      );
      
      // Start the background service
      await startBackgroundService();
      
      debugPrint('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing NotificationService: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _checkForNewNotifications() async {
    try {
      debugPrint('Checking for new notifications...');
      
      final prefs = await SharedPreferences.getInstance();
      final nationalId = prefs.getString('national_id');
      
      if (nationalId == null) {
        debugPrint('No national ID found, cannot fetch notifications');
        return;
      }

      debugPrint('Fetching notifications for ID: $nationalId');
      final notifications = await fetchNotifications(nationalId);
      debugPrint('Found ${notifications.length} notifications');

      if (notifications.isEmpty) {
        debugPrint('No new notifications found');
        return;
      }

      for (final notification in notifications) {
        debugPrint('Processing notification: ${notification['title']}');
        
        // Get the appropriate title and body based on language
        String title;
        String body;
        
        if (_isArabic) {
          title = notification['title_ar'] ?? notification['title'] ?? 'Nayifat Notification';
          body = notification['body_ar'] ?? notification['body'] ?? '';
        } else {
          title = notification['title_en'] ?? notification['title'] ?? 'Nayifat Notification';
          body = notification['body_en'] ?? notification['body'] ?? '';
        }

        // Prepare additional data
        final Map<String, dynamic> additionalData = {
          'isArabic': _isArabic,
        };

        // Add route if available
        if (notification['route'] != null) {
          additionalData['route'] = notification['route'];
        }

        await showNotification(
          title: title,
          body: body,
          payload: jsonEncode({
            'route': notification['route'],
            'data': additionalData,
          }),
        );
      }
      debugPrint('Finished processing notifications');
    } catch (e) {
      debugPrint('Error checking for new notifications: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String nationalId) async {
    try {
      debugPrint('\n=== Fetching Notifications from API ===');
      final url = '${Constants.apiBaseUrl}${Constants.endpointGetNotifications}';
      final body = {
        'national_id': nationalId,
        'mark_as_read': true,
      };

      debugPrint('API Request Details:');
      debugPrint('URL: $url');
      debugPrint('Headers: ${Constants.defaultHeaders}');
      debugPrint('Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: Constants.defaultHeaders,
        body: jsonEncode(body),
      );

      debugPrint('\nAPI Response Details:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('\nParsed Response Data: $data');
        
        if (data['status'] == 'success') {
          final notifications = List<Map<String, dynamic>>.from(data['notifications']);
          debugPrint('Found ${notifications.length} notifications');
          if (notifications.isNotEmpty) {
            debugPrint('Notifications: $notifications');
          }
          return notifications;
        } else {
          debugPrint('API returned non-success status: ${data["status"]}');
          if (data['message'] != null) {
            debugPrint('Error message: ${data["message"]}');
          }
        }
      } else {
        debugPrint('API call failed with status code: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('Error fetching notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    } finally {
      debugPrint('=== API Call Complete ===\n');
    }
  }

  Future<bool> sendNotification({
    String? nationalId,
    List<String>? nationalIds,
    Map<String, dynamic>? filters,
    required String title,
    required String body,
    String? route,
    bool? isArabic,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSendNotification}'),
        headers: Constants.defaultHeaders,
        body: jsonEncode({
          if (nationalId != null) 'national_id': nationalId,
          if (nationalIds != null) 'national_ids': nationalIds,
          if (filters != null) 'filters': filters,
          'title': title,
          'body': body,
          if (route != null) 'route': route,
          if (isArabic != null) 'isArabic': isArabic,
          if (additionalData != null) 'additionalData': additionalData,
        }),
      );

      debugPrint('Sending notification:');
      debugPrint('URL: ${Constants.apiBaseUrl}${Constants.endpointSendNotification}');
      debugPrint('Headers: ${Constants.defaultHeaders}');
      debugPrint('Body: ${jsonEncode({
        if (nationalId != null) 'national_id': nationalId,
        if (nationalIds != null) 'national_ids': nationalIds,
        if (filters != null) 'filters': filters,
        'title': title,
        'body': body,
        if (route != null) 'route': route,
        if (isArabic != null) 'isArabic': isArabic,
        if (additionalData != null) 'additionalData': additionalData,
      })}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Response: ${response.body}');
        return data['status'] == 'success';
      }
      debugPrint('Error response: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  /// Example usage:
  /// 
  /// // Send to a single user
  /// await sendNotification(
  ///   nationalId: "1000000013",
  ///   title: "New Offer",
  ///   body: "Check out our latest offer"
  /// );
  /// 
  /// // Send to multiple users
  /// await sendNotification(
  ///   nationalIds: ["1000000013", "1000000014"],
  ///   title: "System Maintenance",
  ///   body: "System will be down for maintenance"
  /// );
  /// 
  /// // Send to users based on filters
  /// await sendNotification(
  ///   filters: {
  ///     "salary_range": {"min": 5000, "max": 10000},
  ///     "employment_status": "employed",
  ///     "employer_name": "Company XYZ",
  ///     "language": "ar"
  ///   },
  ///   title: "Special Offer",
  ///   body: "Exclusive offer for qualified customers"
  /// );

  @pragma('vm:entry-point')
  static Future<void> _handleNotificationAction(ReceivedAction receivedAction) async {
    try {
      if (receivedAction.payload != null) {
        final payloadJson = jsonDecode(receivedAction.payload!['data'] ?? '{}');
        final route = payloadJson['route'];
        final data = payloadJson['data'] as Map<String, dynamic>;
        final isArabic = data['isArabic'] as bool;
        
        if (route != null) {
          NavigationService().navigateToPage(route, isArabic: isArabic);
        }
      }
    } catch (e) {
      print('Error handling notification action: $e');
    }
  }

  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      debugPrint('Creating local notification...');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Payload: $payload');

      // Create local notification with background handling
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: {'data': payload ?? ''},
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Message,
          autoDismissible: false,
          largeIcon: 'resource://drawable/notification_icon',
          bigPicture: 'asset://assets/images/nayifatlogocircle-nobg.png',
        ),
      );

      debugPrint('Local notification creation result: true');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error showing notification: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> registerDevice(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegisterDevice}'),
        headers: Constants.defaultHeaders,
        body: jsonEncode({
          'user_id': userId,
          'device_token': await _getDeviceToken(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      if (response.statusCode == 200) {
        print('Device registered successfully');
        return true;
      } else {
        print('Failed to register device: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error registering device: $e');
      return false;
    }
  }

  static Future<String> _getDeviceToken() async {
    // For testing, return a dummy token
    return 'dummy_device_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Called when a notification is created
    debugPrint('Notification created: ${receivedNotification.title}');
  }

  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Called when a notification is displayed
    debugPrint('Notification displayed: ${receivedNotification.title}');
  }

  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Called when a notification is dismissed
    debugPrint('Notification dismissed');
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.buttonKeyPressed}');
    debugPrint('Payload: ${receivedAction.payload}');
    
    try {
      if (receivedAction.payload != null) {
        final payloadStr = receivedAction.payload!['data'];
        if (payloadStr != null) {
          final Map<String, dynamic> payload = jsonDecode(payloadStr);
          final String? route = payload['route'] as String?;
          final Map<String, dynamic> data = payload['data'] as Map<String, dynamic>;
          final bool isArabic = data['isArabic'] as bool? ?? false;

          debugPrint('Processing notification action - Route: $route, IsArabic: $isArabic');

          if (route != null && navigatorKey?.currentState != null) {
            debugPrint('Navigating to route: $route');
            navigatorKey!.currentState!.pushNamed(route);
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling notification action: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Add setter for language
  void setLanguage(bool isArabic) {
    _isArabic = isArabic;
  }

  Future<void> testBackgroundFetch() async {
    debugPrint('Testing background fetch...');
    if (Platform.isIOS) {
      // Simulate background fetch
      await _checkForNewNotifications();
      debugPrint('Background fetch test completed');
    } else {
      debugPrint('Test only available on iOS');
    }
  }
} 