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
import 'dart:io';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;
  bool _isArabic = false;
  Timer? _iosBackgroundTimer;
  final _lock = Lock();
  bool _isChecking = false;
  
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static const platform = MethodChannel('com.nayifat.app/background_service');

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
    
    // 💡 Add random offset (between 0-60 seconds) to prevent synchronized calls
    final randomOffset = Duration(seconds: DateTime.now().millisecond % 60);
    
    // Create a new timer that runs every 15 minutes
    _iosBackgroundTimer = Timer.periodic(
      const Duration(minutes: 15) + randomOffset, 
      (timer) async {
        debugPrint('Background fetch timer triggered');
        final bool canFetch = await _canPerformBackgroundFetch();
        if (canFetch) {
          await checkForNewNotifications();
        } else {
          debugPrint('Background fetch skipped - too soon since last fetch');
        }
    });
    
    debugPrint('iOS background fetch scheduled with offset: ${randomOffset.inSeconds} seconds');
  }

  Future<bool> _canPerformBackgroundFetch() async {
    if (!Platform.isIOS) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt('last_fetch_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // 💡 Add buffer time to prevent edge cases (14 minutes instead of 15)
    if (currentTime - lastFetchTime >= const Duration(minutes: 14).inMilliseconds) {
      debugPrint('Background fetch allowed - sufficient time has passed');
      await prefs.setInt('last_fetch_time', currentTime);
      return true;
    }
    
    debugPrint('Background fetch denied - too soon (${(currentTime - lastFetchTime) / 1000} seconds since last fetch)');
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
          await checkForNewNotifications();
        }
      });

      await AwesomeNotifications().initialize(
        // 💡 Use colored logo for all icons
        Platform.isAndroid ? 'resource://drawable/nayifatlogocircle_nobg' : null,
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
            defaultRingtoneType: DefaultRingtoneType.Notification,
            // 💡 Add iOS-specific settings
            soundSource: Platform.isIOS ? 'notification_sound' : null
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

  Future<bool> checkForNewNotifications() async {
    if (_isChecking) {
      debugPrint('Already checking for notifications, skipping...');
      return false;
    }
    
    return await _lock.synchronized(() async {
      _isChecking = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastCheck = prefs.getInt('last_notification_check') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 💡 Add more detailed logging
        debugPrint('Time since last check: ${(now - lastCheck) / 1000} seconds');
        
        // Prevent checking more frequently than every 13 minutes
        if (now - lastCheck < const Duration(minutes: 13).inMilliseconds) {
          debugPrint('Skipping check - too soon since last check');
          return true;
        }

        // Update last check time BEFORE fetching to prevent race conditions
        await prefs.setInt('last_notification_check', now);

        final nationalId = prefs.getString('national_id');
        if (nationalId == null) {
          debugPrint('No national ID found, skipping notification check');
          return false;
        }

        final notifications = await _fetchNotificationsWithRetry(nationalId);
        if (notifications.isEmpty) {
          debugPrint('No new notifications found');
          return true;
        }

        await _processNotifications(notifications);
        return true;
      } catch (e) {
        debugPrint('Error checking notifications: $e');
        return false;
      } finally {
        _isChecking = false;
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchNotificationsWithRetry(String nationalId) async {
    int attempts = 0;
    while (attempts < Constants.notificationConfig.maxRetries) {
      try {
        return await fetchNotifications(nationalId);
      } catch (e) {
        attempts++;
        if (attempts == Constants.notificationConfig.maxRetries) rethrow;
        await Future.delayed(Constants.notificationConfig.retryDelay * attempts);
      }
    }
    return [];
  }

  Future<void> _processNotifications(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList('seen_notification_ids') ?? [];
    
    for (final notification in notifications) {
      final id = notification['id']?.toString();
      if (id == null || seenIds.contains(id)) continue;
      
      await _showNotification(notification);
      seenIds.add(id);
    }
    
    // Keep last 100 notifications
    if (seenIds.length > Constants.notificationConfig.maxStored) {
      seenIds.removeRange(0, seenIds.length - Constants.notificationConfig.maxStored);
    }
    
    await prefs.setStringList('seen_notification_ids', seenIds);
  }

  Future<void> _showNotification(Map<String, dynamic> notification) async {
    try {
      // Get the appropriate title and body
      final String title = _isArabic ? 
        (notification['title_ar'] ?? notification['title'] ?? 'Nayifat Notification') :
        (notification['title_en'] ?? notification['title'] ?? 'Nayifat Notification');
      
      final String body = _isArabic ?
        (notification['body_ar'] ?? notification['body'] ?? '') :
        (notification['body_en'] ?? notification['body'] ?? '');

      // Prepare notification content
      final Map<String, dynamic> notificationContent = {
        'title': title,
        'body': body,
        'payload': jsonEncode({
          'route': notification['route'],
          'data': {
            'isArabic': _isArabic,
            ...?notification['additionalData'],
          },
        }),
      };

      // Handle big picture
      String? bigPictureUrl = notification['bigPictureUrl'];
      if (bigPictureUrl != null) {
        try {
          bigPictureUrl = await _downloadAndSaveImage(
            bigPictureUrl,
            'notification_big_${notification['id']}'
          );
        } catch (e) {
          debugPrint('Failed to download big picture: $e');
        }
      }

      // Handle large icon
      String? largeIconUrl = notification['largeIconUrl'];
      if (largeIconUrl != null) {
        try {
          largeIconUrl = await _downloadAndSaveImage(
            largeIconUrl,
            'notification_icon_${notification['id']}'
          );
        } catch (e) {
          debugPrint('Failed to download large icon: $e');
        }
      }

      // Show notification with downloaded images
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notification['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: notificationContent['payload'],
          // 💡 Use colored logo for all icons
          icon: Platform.isAndroid ? 'resource://drawable/nayifatlogocircle_nobg' : null,
          largeIcon: largeIconUrl ?? 
              (Platform.isAndroid ? '@drawable/nayifatlogocircle_nobg' : null),
          bigPicture: bigPictureUrl,
          notificationLayout: bigPictureUrl != null ? 
            NotificationLayout.BigPicture : 
            NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Message,
          // 💡 Enable auto dismiss when clicked
          autoDismissible: true,
          // 💡 iOS-specific settings
          groupKey: Platform.isIOS ? 'basic_channel' : null,
          summary: Platform.isIOS ? title : null,
          // 💡 Hide large icon when expanded on Android only
          hideLargeIconOnExpand: Platform.isAndroid && bigPictureUrl != null,
        ),
      );

      // 💡 Add debug logging for image paths
      debugPrint('Image Paths in Notification:');
      debugPrint('Icon: ${Platform.isAndroid ? 'resource://drawable/nayifatlogocircle_nobg' : 'null'}');
      debugPrint('Large Icon URL: ${largeIconUrl ?? (Platform.isAndroid ? '@drawable/nayifatlogocircle_nobg' : 'null')}');
      debugPrint('Big Picture URL: $bigPictureUrl');

      // Cleanup old images
      await _cleanupOldImages();
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<String> _downloadAndSaveImage(String url, String filename) async {
    final http.Client client = http.Client();
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Get app's local storage directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename.jpg';

      // Save the image
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } finally {
      client.close();
    }
  }

  Future<void> _cleanupOldImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      // Keep only last 20 notification images
      final notificationImages = files.where((f) => 
        f.path.contains('notification_big_') || 
        f.path.contains('notification_icon_')
      ).toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      if (notificationImages.length > 20) {
        for (var file in notificationImages.sublist(20)) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String nationalId) async {
    HttpClient? client;
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
        // 💡 Limit seen notifications to 100
        if (seenAllNotifications.length > 100) {
          seenAllNotifications.removeRange(0, seenAllNotifications.length - 100);
          debugPrint('Trimmed seen notifications to latest 100');
        }
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
    HttpClient? client;
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 5);

    while (retryCount < maxRetries) {
      try {
        final url = '${Constants.apiBaseUrl}/notifications/list';
        final body = {
          'nationalId': nationalId,
          'markAsRead': markAsRead,
        };

        debugPrint('API Request Details:');
        debugPrint('URL: $url');
        debugPrint('Headers: ${Constants.defaultHeaders}');
        debugPrint('Body: ${jsonEncode(body)}');
        
        // 💡 Create HttpClient with custom timeout
        client = HttpClient()
          ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true)
          ..connectionTimeout = const Duration(seconds: 120);

        final uri = Uri.parse(url);
        final request = await client.postUrl(uri);
        
        // Add headers
        Constants.defaultHeaders.forEach((key, value) {
          request.headers.set(key, value);
        });
        request.headers.contentType = ContentType.json;

        // Add body
        request.write(jsonEncode(body));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        debugPrint('\nAPI Response Details:');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Headers: ${response.headers}');
        debugPrint('Response Body: $responseBody');

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          debugPrint('\nParsed Response Data: $data');
          
          if (data['success'] == true && data['data'] != null) {
            final notifications = List<Map<String, dynamic>>.from(data['data']['notifications'] ?? []);
            debugPrint('Found ${notifications.length} notifications');
            return notifications;
          }
        }
        // If we get here with a non-200 status code, throw to trigger retry
        if (response.statusCode != 200) {
          throw Exception('API returned status code: ${response.statusCode}');
        }
        return [];
      } catch (e) {
        debugPrint('Error in API call: $e');
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Retrying in ${retryDelay.inSeconds} seconds... (Attempt ${retryCount + 1}/$maxRetries)');
          await Future.delayed(retryDelay * retryCount);
          continue;
        }
        return [];
      } finally {
        client?.close();
      }
    }
    return [];
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
    HttpClient? client;
    try {
      // 💡 Create HttpClient that accepts self-signed certificates
      client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      final uri = Uri.parse('${Constants.apiBaseUrl}${Constants.endpointSendNotification}');
      final request = await client.postUrl(uri);
      
      // Add headers
      Constants.defaultHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.headers.contentType = ContentType.json;

      // Prepare request body
      final requestBody = {
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
      };

      // Add body
      request.write(jsonEncode(requestBody));

      debugPrint('Sending notification:');
      debugPrint('URL: ${Constants.apiBaseUrl}${Constants.endpointSendNotification}');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Body: ${jsonEncode(requestBody)}');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        debugPrint('Response: $responseBody');
        return data['success'] == true;
      }
      debugPrint('Error response: $responseBody');
      return false;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    } finally {
      client?.close();
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
      // 💡 Enhanced notification dismissal
      if (receivedAction.id != null) {
        // Dismiss this specific notification
        await AwesomeNotifications().dismiss(receivedAction.id!);
        debugPrint('Step N1: Dismissed notification with ID: ${receivedAction.id}');
        
        // Also cancel the notification to prevent it from showing again
        await AwesomeNotifications().cancel(receivedAction.id!);
        debugPrint('Step N1.1: Cancelled notification with ID: ${receivedAction.id}');
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

      // 💡 Validate and clean URLs
      String? validatedBigPictureUrl = bigPictureUrl;
      String? validatedLargeIconUrl = largeIconUrl;

      if (validatedBigPictureUrl != null) {
        if (!validatedBigPictureUrl.startsWith('http://') && !validatedBigPictureUrl.startsWith('https://')) {
          debugPrint('Step S4.3: Invalid big picture URL format: $validatedBigPictureUrl');
          validatedBigPictureUrl = null;
        }
      }

      if (validatedLargeIconUrl != null) {
        if (!validatedLargeIconUrl.startsWith('http://') && !validatedLargeIconUrl.startsWith('https://')) {
          debugPrint('Step S4.4: Invalid large icon URL format: $validatedLargeIconUrl');
          validatedLargeIconUrl = null;
        }
      }

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

      // 💡 Create local notification with proper image handling
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: {'data': encodedPayload},
          notificationLayout: validatedBigPictureUrl != null 
              ? NotificationLayout.BigPicture 
              : NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Message,
          autoDismissible: false,
          // 💡 Platform-specific icon handling with debug logging
          icon: Platform.isAndroid 
              ? 'resource://drawable/nayifatlogocircle_nobg' 
              : null,
          largeIcon: validatedLargeIconUrl ?? 
              (Platform.isAndroid 
                ? '@drawable/nayifatlogocircle_nobg'  
                : null),
          bigPicture: validatedBigPictureUrl, // 💡 Use URL directly
          // 💡 iOS-specific settings
          groupKey: Platform.isIOS ? 'basic_channel' : null,
          summary: Platform.isIOS ? title : null,
          // 💡 Hide large icon when expanded on Android only
          hideLargeIconOnExpand: Platform.isAndroid && validatedBigPictureUrl != null,
        ),
      );

      // 💡 Add debug logging for image paths
      debugPrint('Step S8.1: Icon path: ${Platform.isAndroid ? 'resource://drawable/nayifatlogocircle_nobg' : 'null'}');
      debugPrint('Step S8.2: Large icon path: ${validatedLargeIconUrl ?? (Platform.isAndroid ? '@drawable/nayifatlogocircle_nobg' : 'null')}');
      debugPrint('Step S8.3: Big picture URL: $validatedBigPictureUrl');

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
      await checkForNewNotifications();
      debugPrint('Background fetch test completed');
    } else {
      debugPrint('Test only available on iOS');
    }
  }
} 