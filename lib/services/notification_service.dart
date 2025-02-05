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

        // Add any additional data from the notification
        if (notification['additionalData'] != null) {
          additionalData.addAll(Map<String, dynamic>.from(notification['additionalData']));
        }

        await showNotification(
          title: title,
          body: body,
          payload: jsonEncode({
            'route': notification['route'],
            'data': additionalData,
          }),
          bigPictureUrl: notification['bigPictureUrl'],
          largeIconUrl: notification['largeIconUrl'],
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
      final List<Map<String, dynamic>> allNotifications = [];
      final prefs = await SharedPreferences.getInstance();
      final seenAllNotifications = prefs.getStringList('seen_all_notifications') ?? [];

      // Fetch user-specific notifications
      final userNotifications = await _fetchFromApi(nationalId, true);
      allNotifications.addAll(userNotifications);

      // Fetch "all" notifications
      final allTargetedNotifications = await _fetchFromApi("all", false);
      
      // Filter out already seen "all" notifications and add new ones to seen list
      final newAllNotifications = allTargetedNotifications.where((notification) {
        final id = notification['id'].toString();
        if (seenAllNotifications.contains(id)) return false;
        seenAllNotifications.add(id);
        return true;
      }).toList();

      // Save updated seen notifications
      if (newAllNotifications.isNotEmpty) {
        await prefs.setStringList('seen_all_notifications', seenAllNotifications);
      }

      allNotifications.addAll(newAllNotifications);
      return allNotifications;
    } catch (e, stackTrace) {
      debugPrint('Error fetching notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromApi(String nationalId, bool markAsRead) async {
    try {
      final url = '${Constants.apiBaseUrl}${Constants.endpointGetNotifications}';
      final body = {
        'nationalId': nationalId,
        'markAsRead': markAsRead,
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
        
        if (data['success'] == true && data['data'] != null) {
          final notifications = List<Map<String, dynamic>>.from(data['data']['notifications']);
          debugPrint('Found ${notifications.length} notifications');
          
          // Transform notifications to include image URLs
          final transformedNotifications = notifications.map((notification) {
            // 💡 Get image URLs with proper validation
            String? bigPictureUrl = notification['bigPictureUrl'] ?? 
                                  notification['BigPictureUrl'] ?? 
                                  notification['image_url'] ?? 
                                  notification['ImageUrl'];
            
            String? largeIconUrl = notification['largeIconUrl'] ?? 
                                 notification['LargeIconUrl'] ?? 
                                 notification['icon_url'] ?? 
                                 notification['IconUrl'];

            // Validate URLs
            if (bigPictureUrl != null && !bigPictureUrl.startsWith('http')) {
              bigPictureUrl = null;
            }
            if (largeIconUrl != null && !largeIconUrl.startsWith('http')) {
              largeIconUrl = null;
            }

            debugPrint('Processing notification images:');
            debugPrint('Big Picture URL: $bigPictureUrl');
            debugPrint('Large Icon URL: $largeIconUrl');

            return {
              ...notification,
              'bigPictureUrl': bigPictureUrl,
              'largeIconUrl': largeIconUrl,
            };
          }).toList();
          
          if (transformedNotifications.isNotEmpty) {
            debugPrint('Notifications with images: $transformedNotifications');
          }
          return transformedNotifications;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in API call: $e');
      return [];
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
    String? bigPictureUrl,
    String? largeIconUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSendNotification}'),
        headers: Constants.defaultHeaders,
        body: jsonEncode({
          if (nationalId != null) 'nationalId': nationalId,
          if (nationalIds != null) 'nationalIds': nationalIds,
          if (filters != null) 'filters': filters,
          if (isArabic == true) ...<String, String>{
            'titleAr': title,
            'bodyAr': body,
          } else ...<String, String>{
            'titleEn': title,
            'bodyEn': body,
          },
          if (route != null) 'route': route,
          if (additionalData != null) 'additionalData': additionalData,
          if (bigPictureUrl != null) 'bigPictureUrl': bigPictureUrl,
          if (largeIconUrl != null) 'largeIconUrl': largeIconUrl,
        }),
      );

      debugPrint('Sending notification:');
      debugPrint('URL: ${Constants.apiBaseUrl}${Constants.endpointSendNotification}');
      debugPrint('Headers: ${Constants.defaultHeaders}');
      debugPrint('Body: ${jsonEncode({
        if (nationalId != null) 'nationalId': nationalId,
        if (nationalIds != null) 'nationalIds': nationalIds,
        if (filters != null) 'filters': filters,
        if (isArabic == true) ...<String, String>{
          'titleAr': title,
          'bodyAr': body,
        } else ...<String, String>{
          'titleEn': title,
          'bodyEn': body,
        },
        if (route != null) 'route': route,
        if (additionalData != null) 'additionalData': additionalData,
        if (bigPictureUrl != null) 'bigPictureUrl': bigPictureUrl,
        if (largeIconUrl != null) 'largeIconUrl': largeIconUrl,
      })}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Response: ${response.body}');
        return data['success'] == true;
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
  /// // Send to a single user with image
  /// await sendNotification(
  ///   nationalId: "1000000013",
  ///   title: "New Offer",
  ///   body: "Check out our latest offer",
  ///   bigPictureUrl: "https://example.com/offer-image.jpg",
  ///   largeIconUrl: "https://example.com/icon.png"
  /// );
  /// 
  /// // Send to multiple users
  /// await sendNotification(
  ///   nationalIds: ["1000000013", "1000000014"],
  ///   title: "System Maintenance",
  ///   body: "System will be down for maintenance"
  /// );
  /// 
  /// // Send to users based on filters with image
  /// await sendNotification(
  ///   filters: {
  ///     "salary_range": {"min": 5000, "max": 10000},
  ///     "employment_status": "employed",
  ///     "employer_name": "Company XYZ",
  ///     "language": "ar"
  ///   },
  ///   title: "Special Offer",
  ///   body: "Exclusive offer for qualified customers",
  ///   bigPictureUrl: "https://example.com/special-offer.jpg"
  /// );

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('=================== NOTIFICATION CLICKED ===================');
    debugPrint('Action: ${receivedAction.buttonKeyPressed}');
    debugPrint('Raw Payload: ${receivedAction.payload}');
    
    try {
      // First, dismiss the notification if we have an ID
      if (receivedAction.id != null) {
        await AwesomeNotifications().dismiss(receivedAction.id!);
        debugPrint('Step N1: Dismissed notification with ID: ${receivedAction.id}');
      }
      
      if (receivedAction.payload != null && receivedAction.payload!['data'] != null) {
        final String payloadStr = receivedAction.payload!['data']!;
        debugPrint('Step N2: Payload String: $payloadStr');
        
        if (payloadStr.isNotEmpty) {
          final Map<String, dynamic> payload = jsonDecode(payloadStr);
          debugPrint('Step N3: Decoded Payload: $payload');
          
          String? route = payload['route'] as String?;
          debugPrint('Step N4: Original Route: $route');
          
          // Normalize route
          if (route != null) {
            // Keep the leading slash if present, as it's required for the new API
            // Only convert to lowercase for consistent matching
            route = route.toLowerCase();
            debugPrint('Step N5: Normalized Route: $route');
          }
          
          final Map<String, dynamic>? data = payload['data'] as Map<String, dynamic>?;
          debugPrint('Step N6: Extracted Data: $data');
          
          final bool isArabic = data?['isArabic'] as bool? ?? false;
          debugPrint('Step N7: Is Arabic: $isArabic');

          if (route != null && route.isNotEmpty) {
            debugPrint('Step N8: Attempting navigation to route: $route');
            // Wait a bit to ensure the app is properly initialized
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (navigatorKey?.currentState != null) {
              debugPrint('Step N9: Navigator is available, proceeding with navigation');
              
              // Use NavigationService for consistent navigation
              final navigationService = NavigationService();
              debugPrint('Step N10: Navigation Service initialized');
              
              // Pass any additional data from the notification
              final Map<String, dynamic> arguments = {
                'fromNotification': true,
                if (data != null) ...data,
              };
              
              navigationService.navigateToPage(
                route, // Route already has the leading slash
                isArabic: isArabic,
                arguments: arguments,
              );
              debugPrint('Step N11: Navigation command sent with arguments: $arguments');
            } else {
              debugPrint('Step N12: Navigator not available, storing route for later');
              // Store the route and language preference for when the app starts
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('pending_notification_route', route);
              await prefs.setBool('pending_notification_is_arabic', isArabic);
              debugPrint('Step N13: Route stored in SharedPreferences');
            }
          } else {
            debugPrint('Step N14: ERROR - No route specified in notification payload');
          }
        } else {
          debugPrint('Step N15: ERROR - Empty payload string');
        }
      } else {
        debugPrint('Step N16: ERROR - No payload data available');
      }
    } catch (e, stackTrace) {
      debugPrint('Step N17: ERROR in notification handling: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    debugPrint('=============== END NOTIFICATION HANDLING ===============');
  }

  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
    String? bigPictureUrl,
    String? largeIconUrl,
  }) async {
    try {
      debugPrint('Step S1: Creating local notification...');
      debugPrint('Step S2: Title: $title');
      debugPrint('Step S3: Body: $body');
      debugPrint('Step S4: Raw Payload: $payload');
      if (bigPictureUrl != null) debugPrint('Step S4.1: Big Picture URL: $bigPictureUrl');
      if (largeIconUrl != null) debugPrint('Step S4.2: Large Icon URL: $largeIconUrl');

      Map<String, dynamic> payloadData;
      String? route;
      
      // Parse the payload if it exists
      if (payload != null && payload.isNotEmpty) {
        try {
          payloadData = jsonDecode(payload);
          route = payloadData['route'] as String?;
          debugPrint('Step S5: Successfully parsed payload, route: $route');
        } catch (e) {
          debugPrint('Step S6: Error parsing payload: $e');
          payloadData = {};
        }
      } else {
        debugPrint('Step S7: No payload provided');
        payloadData = {};
      }

      // Create the payload structure that matches what we expect in onActionReceivedMethod
      final notificationPayload = {
        'route': route,
        'data': {
          'isArabic': _isArabic,
          // Add any other needed data here
        }
      };
      
      final encodedPayload = jsonEncode(notificationPayload);
      debugPrint('Step S8: Final Encoded Payload: $encodedPayload');

      // Create local notification with background handling
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: {'data': encodedPayload},
          notificationLayout: bigPictureUrl != null ? NotificationLayout.BigPicture : NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Message,
          autoDismissible: false,
          largeIcon: largeIconUrl ?? 'resource://drawable/notification_icon',
          bigPicture: bigPictureUrl ?? 'asset://assets/images/nayifatlogocircle-nobg.png',
        ),
      );

      debugPrint('Step S9: Local notification created successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Step S10: Error showing notification: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> registerDevice(String userId) async {
    try {
        final response = await http.post(
            Uri.parse('${Constants.apiBaseUrl}${Constants.endpointRegisterDevice}'),
            headers: Constants.deviceHeaders,
            body: jsonEncode({
                'userId': userId,
                'deviceToken': await _getDeviceToken(),
                'platform': Platform.isAndroid ? 'android' : 'ios',
                'deviceInfo': await _getDeviceInfo(),
            }),
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            debugPrint('Device registered successfully');
            return data['success'] == true;
        } else {
            debugPrint('Failed to register device: ${response.body}');
            return false;
        }
    } catch (e) {
        debugPrint('Error registering device: $e');
        return false;
    }
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
            'model': androidInfo.model,
            'manufacturer': androidInfo.manufacturer,
            'androidVersion': androidInfo.version.release,
            'sdkVersion': androidInfo.version.sdkInt.toString(),
        };
    } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
            'model': iosInfo.model,
            'systemName': iosInfo.systemName,
            'systemVersion': iosInfo.systemVersion,
            'name': iosInfo.name,
        };
    }
    return {};
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