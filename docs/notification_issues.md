# Debugging Notifications Issue in Nayifat App

## Overview

This document outlines the potential reasons why notifications are not functioning correctly when the Nayifat app is **completely closed** and the **phone screen is off**. It provides a comprehensive analysis of the current implementation across both **Android** and **iOS** platforms, identifies key issues, and offers detailed recommendations to resolve them.

---

## Table of Contents

1. [Android Implementation Issues](#android-implementation-issues)
    - [NotificationWorker.kt](#notificationworkerkotlin)
    - [AndroidManifest.xml Permissions](#androidmanifestxml-permissions)
2. [iOS Implementation Issues](#ios-implementation-issues)
    - [Background Fetch Mechanism](#background-fetch-mechanism)
    - [Info.plist Configuration](#infoplist-configuration)
3. [Backend (PHP) Considerations](#backend-php-considerations)
    - [send_notification.php](#send_notificationphp)
4. [Permissions and User Consent](#permissions-and-user-consent)
5. [Ensuring Background Workers are Properly Registered](#ensuring-background-workers-are-properly-registered)
6. [Testing and Debugging](#testing-and-debugging)
7. [Conclusion](#conclusion)
8. [Additional Recommendations](#additional-recommendations)

---

## Android Implementation Issues

### NotificationWorker.kt

**Current Issue:**

The `NotificationWorker.kt` attempts to launch the app's main activity when processing notifications:
kotlin
// Trigger the notification using AwesomeNotifications
val intent = applicationContext.packageManager.getLaunchIntentForPackage(applicationContext.packageName)
intent?.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
applicationContext.startActivity(intent)


This approach requires the app to be active, which is not feasible when the app is completely closed.

**Recommended Solution:**

1. **Use Native Android APIs to Display Notifications:**

   Modify the `doWork()` method to directly display notifications using Android's `NotificationManager` and `NotificationCompat`. This ensures notifications are shown even when the app is closed.

   ```kotlin
   override fun doWork(): Result {
       return try {
           val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
           val nationalId = prefs.getString("flutter.national_id", null)

           if (nationalId == null) {
               Log.d("NotificationWorker", "No national ID found")
               return Result.success()
           }

           val notifications = fetchNotificationsFromApi(nationalId)

           if (notifications.isNotEmpty()) {
               notifications.forEach { notification ->
                   displayNativeNotification(notification)
               }
           }

           Result.success()
       } catch (e: Exception) {
           Log.e("NotificationWorker", "Error checking notifications", e)
           Result.retry()
       }
   }

   private fun fetchNotificationsFromApi(nationalId: String): List<Notification> {
       // Implement API call to fetch notifications
   }

   private fun displayNativeNotification(notification: Notification) {
       val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

       val channelId = "default_channel_id"
       val channelName = "Default Channel"

       if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
           val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
           notificationManager.createNotificationChannel(channel)
       }

       val builder = NotificationCompat.Builder(applicationContext, channelId)
           .setSmallIcon(R.drawable.ic_notification)
           .setContentTitle(notification.title)
           .setContentText(notification.body)
           .setPriority(NotificationCompat.PRIORITY_HIGH)
           .setAutoCancel(true)

       notificationManager.notify(notification.id, builder.build())
   }
   ```

2. **Ensure Notification Channels are Properly Configured:**

   For Android Oreo (API 26) and above, notification channels are mandatory. Ensure that channels are created and managed correctly.

### AndroidManifest.xml Permissions

**Current Issue:**

Although the necessary permissions are declared, it's crucial to verify that all required permissions for displaying notifications and running background services are correctly set.

**Recommended Steps:**

1. **Verify Required Permissions:**

   Ensure the following permissions are present and correctly configured:

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```

2. **Request Runtime Permissions:**

   For Android 13 and above, notification permissions must be requested at runtime.

   ```dart
   // Example in Dart using Awesome Notifications
   bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
   if (!isAllowed) {
       // Request permission
       await AwesomeNotifications().requestPermissionToSendNotifications();
   }
   ```

3. **Handle Permission Denials Gracefully:**

   Inform users about the necessity of granting permissions for optimal app functionality.

---

## iOS Implementation Issues

### Background Fetch Mechanism

**Current Issue:**

The app uses `Timer.periodic` for background fetch, which is unreliable when the app is terminated or in the background:
dart
void startIOSBackgroundFetch() {
// Cancel any existing timer
iosBackgroundTimer?.cancel();
// Create a new timer that runs every 15 minutes
iosBackgroundTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
final bool canFetch = await canPerformBackgroundFetch();
if (canFetch) {
await checkForNewNotifications();
}
});
}


**Recommended Solution:**

1. **Utilize BGTaskScheduler for Background Fetch:**

   Implement `BGTaskScheduler` in `AppDelegate.swift` to handle background tasks efficiently.

   ```swift
   import BackgroundTasks

   @UIApplicationMain
   class AppDelegate: FlutterAppDelegate {
       override func application(
           _ application: UIApplication,
           didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
       ) -> Bool {
           BGTaskScheduler.shared.register(forTaskWithIdentifier: "\(Bundle.main.bundleIdentifier!).notification_refresh", using: nil) { task in
               self.handleBackgroundTask(task: task as! BGAppRefreshTask)
           }
           return super.application(application, didFinishLaunchingWithOptions: launchOptions)
       }
       
       func handleBackgroundTask(task: BGAppRefreshTask) {
           scheduleBackgroundTask()
           
           task.expirationHandler = {
               task.setTaskCompleted(success: false)
           }
           
           fetchAndDisplayNotifications { success in
               task.setTaskCompleted(success: success)
           }
       }
       
       func fetchAndDisplayNotifications(completion: @escaping (Bool) -> Void) {
           // Implement network call to fetch notifications
           // Use UserNotifications framework to display notifications
           let content = UNMutableNotificationContent()
           content.title = "Notification Title"
           content.body = "Notification Body"
           content.sound = .default

           let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
           UNUserNotificationCenter.current().add(request) { error in
               if let error = error {
                   print("Error displaying notification: \(error)")
                   completion(false)
               } else {
                   completion(true)
               }
           }
       }
       
       func scheduleBackgroundTask() {
           let request = BGAppRefreshTaskRequest(identifier: "\(Bundle.main.bundleIdentifier!).notification_refresh")
           request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
           do {
               try BGTaskScheduler.shared.submit(request)
           } catch {
               print("Could not schedule app refresh: \(error)")
           }
       }
   }
   ```

2. **Remove Timer-Based Background Fetch:**

   Replace the `Timer.periodic` approach with the `BGTaskScheduler` implementation.

### Info.plist Configuration

**Current Issue:**

Incomplete or incorrect `Info.plist` configurations can prevent background tasks and notifications from functioning correctly.

**Recommended Steps:**

1. **Add Required Keys:**

   Ensure the following keys are present in `Info.plist`:

   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>remote-notification</string>
       <string>fetch</string>
   </array>
   <key>APS Environment</key>
   <string>development</string> <!-- or "production" -->
   ```

2. **Configure Entitlements:**

   Update `Runner.entitlements` to include necessary entitlements for push notifications and background modes.

3. **Enable Critical Alerts (If Applicable):**

   If using critical alerts, ensure permissions and configurations are correctly set.

---

## Backend (PHP) Considerations

### send_notification.php

**Current Issue:**

The backend script `send_notification.php` adds notifications to the `user_notifications` table but does not send push notifications directly via APNS (iOS) or FCM (Android). Relying solely on the app's background workers to fetch and display notifications is unreliable when the app is closed.

**Recommended Solution:**

1. **Integrate Push Notification Services:**

   Implement direct push notifications using APNS for iOS and FCM for Android.

2. **Maintain Device Tokens:**

   Store and manage device tokens for each user to target notifications effectively.

3. **Implement Notification Sending Logic:**

   Update `send_notification.php` to send notifications directly to user devices.

   **Example Integration with FCM:**

   ```php
   <?php
   function sendFCMNotification($deviceToken, $title, $body, $payload = []) {
       $url = 'https://fcm.googleapis.com/fcm/send';
       $fields = [
           'to' => $deviceToken,
           'notification' => [
               'title' => $title,
               'body' => $body,
               'sound' => 'default'
           ],
           'data' => $payload
       ];

       $headers = [
           'Authorization: key=YOUR_FCM_SERVER_KEY',
           'Content-Type: application/json'
       ];

       $ch = curl_init();
       curl_setopt($ch, CURLOPT_URL, $url);
       curl_setopt($ch, CURLOPT_POST, true);
       curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
       curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
       curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);  
       curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);  
       curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));

       $result = curl_exec($ch);
       if ($result === FALSE) {
           die('Curl failed: ' . curl_error($ch));
       }

       curl_close($ch);
       return $result;
   }

   // Usage Example
   $deviceToken = 'user_device_token_here';
   $title = 'New Notification';
   $body = 'You have a new message!';
   $payload = ['key1' => 'value1', 'key2' => 'value2'];

   sendFCMNotification($deviceToken, $title, $body, $payload);
   ?>
   ```

4. **Handle APNS for iOS:**

   Similarly, integrate APNS for sending notifications to iOS devices.

   **Resources:**
   - [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)

5. **Error Handling and Logging:**

   Implement robust error handling to manage failed notification deliveries and log related events for auditing.

---

## Permissions and User Consent

**Issue:**

Notifications require explicit user permissions. If permissions are not granted, notifications will not appear, especially when the app is closed.

**Recommended Actions:**

1. **Request Permissions Appropriately:**

   - **iOS:**
     - Request notification permissions during app initialization.
     - Example in Dart:

       ```dart
       import 'package:awesome_notifications/awesome_notifications.dart';

       Future<void> requestIOSPermissions() async {
           bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
           if (!isAllowed) {
               // Request permission
               await AwesomeNotifications().requestPermissionToSendNotifications();
           }
       }
       ```

   - **Android:**
     - For Android 13 and above, request notification permissions at runtime.
     - Example in Dart:

       ```dart
       import 'package:permission_handler/permission_handler.dart';

       Future<void> requestAndroidPermissions() async {
           if (await Permission.notification.isDenied) {
               await Permission.notification.request();
           }
       }
       ```

2. **Handle Permission Denials Gracefully:**

   - Inform users about the importance of granting notification permissions.
   - Provide options to open app settings for enabling permissions.

3. **Check Permissions Before Sending Notifications:**

   - Implement checks to verify if permissions are granted before attempting to display notifications.

---

## Ensuring Background Workers are Properly Registered

**Issue:**

Background workers must be correctly registered and scheduled to run at specified intervals to handle notifications reliably.

**Recommended Steps:**

1. **Android:**

   - **WorkManager Configuration:**
     - Ensure that `NotificationWorker` is properly registered with WorkManager.
     - Verify that there are no constraints preventing its execution.
     - Example setup in `MainActivity.kt`:

       ```kotlin
       import androidx.work.PeriodicWorkRequestBuilder
       import androidx.work.WorkManager
       import java.util.concurrent.TimeUnit

       class MainActivity: FlutterActivity() {
           override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
               super.configureFlutterEngine(flutterEngine)
               
               // Schedule NotificationWorker to run periodically
               val notificationWork = PeriodicWorkRequestBuilder<NotificationWorker>(15, TimeUnit.MINUTES)
                   .build()
               WorkManager.getInstance(this).enqueue(notificationWork)
           }
       }
       ```

2. **iOS:**

   - **BGTaskScheduler Registration:**
     - Ensure background tasks are registered with unique identifiers.
     - Verify that `scheduleBackgroundTask()` is called appropriately.
     - Example in `AppDelegate.swift`:

       ```swift
       func scheduleBackgroundTask() {
           let request = BGAppRefreshTaskRequest(identifier: "\(Bundle.main.bundleIdentifier!).notification_refresh")
           request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
           do {
               try BGTaskScheduler.shared.submit(request)
           } catch {
               print("Could not schedule app refresh: \(error)")
           }
       }
       ```

---

## Testing and Debugging

**Issue:**

Without comprehensive testing, issues related to background execution and notification delivery may go unnoticed.

**Recommended Testing Strategies:**

1. **Android:**

   - **Use ADB Logs:**
     - Monitor logs to verify background worker execution and notification display.
     - Command: `adb logcat`

   - **Trigger Background Worker Manually:**
     - Use WorkManager's testing tools to trigger `NotificationWorker` and observe behavior.

   - **Test Across Multiple Android Versions:**
     - Ensure compatibility and functionality across different Android versions.

2. **iOS:**

   - **Use Xcode Debugger:**
     - Monitor background task execution and notification delivery.
     - Check console logs for any errors.

   - **Test on Physical Devices:**
     - Simulators may not accurately represent background behaviors.
     - Ensure background fetch and notifications work as expected on real devices.

3. **Backend:**

   - **Monitor Server Logs:**
     - Ensure notifications are being sent correctly.
     - Identify any issues with push notification services.

   - **Use Tools Like Postman:**
     - Manually test API endpoints related to notifications.

4. **General Testing:**

   - **Validate Notification Payloads:**
     - Ensure payloads adhere to platform-specific requirements.

   - **Simulate App States:**
     - Test notifications when the app is in the foreground, background, and completely closed.

   - **Check Permission Scenarios:**
     - Test with permissions granted and denied to ensure proper handling.

---

## Conclusion

The malfunctioning notifications when the app is **completely closed** and the **phone screen is off** are primarily due to the following reasons:

1. **Android:**
    - **NotificationWorker.kt** launches the app's main activity instead of directly displaying notifications using native APIs.

2. **iOS:**
    - Reliance on `Timer.periodic` for background fetch is unreliable when the app is terminated.
    - Proper use of `BGTaskScheduler` and native notification handling is required.

3. **Backend:**
    - The current backend approach relies solely on background workers for fetching notifications, which is unreliable when the app is closed.
    - Implementing direct push notifications via APNS and FCM enhances reliability.

4. **Permissions:**
    - Ensuring all necessary permissions are correctly requested and granted by the user is crucial for notifications to function as expected.

By addressing these areas, the notification system's reliability and functionality can be significantly enhanced, ensuring that users receive notifications even when the app is not actively running.

---

## Additional Recommendations

1. **Update Dependencies:**
    - Ensure all packages and dependencies, especially `Awesome Notifications` and WorkManager, are up-to-date to leverage the latest features and bug fixes.

2. **Comprehensive Documentation:**
    - Maintain detailed documentation outlining the notification flow, permission handling, and background task implementations to aid future development and troubleshooting.

3. **User Feedback Mechanisms:**
    - Implement in-app feedback to inform users about notification settings and provide options to manage their preferences.

4. **Security Enhancements:**
    - Ensure secure handling of device tokens and sensitive user data to prevent unauthorized access.

5. **Performance Optimization:**
    - Optimize background tasks to minimize battery consumption and ensure efficient performance.

---

## Next Steps for Developers

1. **Modify Android `NotificationWorker.kt`:**
    - Implement native notification display using `NotificationManager`.
    - Remove the intent-launching mechanism.

2. **Configure `AndroidManifest.xml`:**
    - Verify and update necessary permissions.
    - Ensure runtime permission requests are implemented for Android 13+.

3. **Implement iOS `BGTaskScheduler`:**
    - Replace `Timer.periodic` with `BGTaskScheduler` in `AppDelegate.swift`.
    - Ensure `Info.plist` includes all necessary background modes.

4. **Enhance Backend Notification Logic:**
    - Integrate push notifications using APNS and FCM.
    - Manage and secure device tokens effectively.

5. **Ensure Proper Permission Handling:**
    - Implement comprehensive permission requests and handling in both Android and iOS.

6. **Conduct Thorough Testing:**
    - Test notifications across different app states and device conditions.
    - Utilize platform-specific debugging tools to monitor and resolve issues.

---

