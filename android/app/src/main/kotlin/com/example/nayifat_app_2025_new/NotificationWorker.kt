package com.example.nayifat_app_2025_new

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import androidx.core.app.NotificationCompat
import android.os.Build
import org.json.JSONObject
import java.net.URL
import javax.net.ssl.HttpsURLConnection
import android.app.Notification
import android.app.PendingIntent
import org.json.JSONArray
import android.content.SharedPreferences

class NotificationWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private fun getApiBaseUrl(prefs: SharedPreferences): String {
            val useNewApi = prefs.getBoolean("flutter.useNewApi", true)
            return if (useNewApi) {
                "https://45f9-51-252-155-185.ngrok-free.app/api"
            } else {
                "https://icreditdept.com/api"
            }
        }
        private const val NOTIFICATIONS_ENDPOINT = "/notifications/list"
        private const val API_KEY = "7ca7427b418bdbd0b3b23d7debf69bf7"
        private const val TAG = "Tariq_NotificationWorker"
    }

    override fun doWork(): Result {
        Log.d(TAG, "Step 1: Worker Started - Time: ${System.currentTimeMillis()}")
        try {
            // Get national ID from SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val baseUrl = getApiBaseUrl(prefs)
            Log.d(TAG, "Step 2: Checking SharedPreferences")
            Log.d(TAG, "Step 2.1: Available SharedPreferences keys:")
            prefs.all.forEach { (key, value) ->
                Log.d(TAG, "Step 2.2: Found Key: $key, Value: $value")
            }
            
            val nationalId = prefs.getString("flutter.national_id", null)
            Log.d(TAG, "Step 3: National ID check - ${if (nationalId != null) "Found ID: $nationalId" else "No ID found"}")
            
            if (nationalId == null) {
                Log.d(TAG, "Step 3.1: No user-specific ID, checking 'all' notifications only")
            }

            // Fetch notifications from API
            Log.d(TAG, "Step 4: Starting API calls")
            val notifications = fetchNotifications(nationalId)
            Log.d(TAG, "Step 7: API calls complete - Found ${notifications.size} notifications")

            if (notifications.isNotEmpty()) {
                Log.d(TAG, "Step 8: Processing ${notifications.size} notifications")
                notifications.forEachIndexed { index, notification ->
                    Log.d(TAG, "Step 8.${index + 1}: Processing notification: ${notification["title"]}")
                    showNotification(notification)
                }
            } else {
                Log.d(TAG, "Step 8: No notifications to display")
            }
            
            Log.d(TAG, "Step 9: Worker Completed Successfully")
            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Step Error: Worker failed with error: ${e.message}")
            e.printStackTrace()
            Log.d(TAG, "Step Error: Will retry worker")
            return Result.retry()
        }
    }

    private fun fetchNotifications(nationalId: String?): List<Map<String, String>> {
        Log.d(TAG, "Step 4.1: Setting up API calls")
        val allNotifications = mutableListOf<Map<String, String>>()
        val seenNotifications = getSeenNotifications()
        
        try {
            // First, fetch "all" notifications
            fetchFromApi("all", false)?.let { notifications ->
                // Filter out already seen notifications
                notifications.forEach { notification ->
                    val id = notification["id"]
                    if (id != null && !seenNotifications.contains(id)) {
                        allNotifications.add(notification)
                        // Add to seen notifications
                        addToSeenNotifications(id)
                    }
                }
            }

            // Then, if we have a national ID, fetch user-specific notifications
            if (!nationalId.isNullOrEmpty()) {
                fetchFromApi(nationalId, true)?.let { notifications ->
                    allNotifications.addAll(notifications)
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error fetching notifications: ${e.message}")
        }
        
        return allNotifications
    }

    private fun fetchFromApi(nationalId: String, markAsRead: Boolean): List<Map<String, String>>? {
        Log.d(TAG, "Step 4.2: Fetching notifications for ID: $nationalId")
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val baseUrl = getApiBaseUrl(prefs)
        val url = URL("$baseUrl$NOTIFICATIONS_ENDPOINT")
        val connection = url.openConnection() as HttpsURLConnection
        
        try {
            // Get language setting
            val isArabic = prefs.getBoolean("flutter.isArabic", false)
            Log.d(TAG, "Step 4.2.1: App language setting - isArabic: $isArabic")

            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("x-api-key", API_KEY)
            connection.doOutput = true
            connection.connectTimeout = 30000
            connection.readTimeout = 30000

            val requestBody = JSONObject().apply {
                put("nationalId", nationalId)
                put("markAsRead", markAsRead)
            }

            connection.outputStream.use { os ->
                os.write(requestBody.toString().toByteArray())
            }

            val responseCode = connection.responseCode
            Log.d(TAG, "Step 4.3: API Response code: $responseCode")

            if (responseCode in 200..299) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val jsonResponse = JSONObject(response)
                
                if (jsonResponse.optBoolean("success", false)) {
                    val data = jsonResponse.optJSONObject("data")
                    val notificationsArray = data?.optJSONArray("notifications")
                    
                    if (notificationsArray != null) {
                        return parseNotifications(notificationsArray, isArabic)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in API call: ${e.message}")
        } finally {
            connection.disconnect()
        }
        return null
    }

    private fun getSeenNotifications(): Set<String> {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        try {
            val storedValue = prefs.getString("flutter.seen_all_notifications", null)
            if (storedValue != null) {
                // Extract the JSON array part from the stored string
                val jsonArrayStr = storedValue.substringAfter("!")
                val jsonArray = JSONArray(jsonArrayStr)
                return (0 until jsonArray.length())
                    .map { jsonArray.getString(it) }
                    .toSet()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing seen notifications: ${e.message}")
        }
        return setOf()
    }

    private fun addToSeenNotifications(id: String) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        try {
            val currentSeen = getSeenNotifications().toMutableSet()
            currentSeen.add(id)
            
            // Create the JSON array string
            val jsonArray = JSONArray(currentSeen.toList())
            // Add the Flutter prefix and save
            val valueToStore = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!$jsonArray"
            
            prefs.edit().putString("flutter.seen_all_notifications", valueToStore).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving seen notification: ${e.message}")
        }
    }

    private fun parseNotifications(notificationsArray: JSONArray, isArabic: Boolean): List<Map<String, String>> {
        val notifications = mutableListOf<Map<String, String>>()
        
        for (i in 0 until notificationsArray.length()) {
            val notif = notificationsArray.getJSONObject(i)
            
            // Get title based on language
            val title = when {
                isArabic && !notif.optString("title_ar").isNullOrBlank() -> notif.optString("title_ar")
                !isArabic && !notif.optString("title_en").isNullOrBlank() -> notif.optString("title_en")
                !notif.optString("title").isNullOrBlank() -> notif.optString("title")
                else -> "Nayifat Notification"
            }

            // Get body based on language
            val body = when {
                isArabic && !notif.optString("body_ar").isNullOrBlank() -> notif.optString("body_ar")
                !isArabic && !notif.optString("body_en").isNullOrBlank() -> notif.optString("body_en")
                !notif.optString("body").isNullOrBlank() -> notif.optString("body")
                else -> ""
            }

            // 💡 Get image URLs with fallbacks
            val bigPictureUrl = notif.optString("big_picture_url") ?: 
                               notif.optString("bigPictureUrl") ?: 
                               notif.optString("image_url")

            val largeIconUrl = notif.optString("large_icon_url") ?: 
                              notif.optString("largeIconUrl") ?: 
                              notif.optString("icon_url")

            notifications.add(mapOf(
                "id" to (notif.optString("id") ?: System.currentTimeMillis().toString()),
                "title" to title,
                "body" to body,
                "route" to notif.optString("route", ""),
                "created_at" to notif.optString("created_at", ""),
                "expires_at" to notif.optString("expires_at", ""),
                "bigPictureUrl" to bigPictureUrl,  // 💡 Added
                "largeIconUrl" to largeIconUrl     // 💡 Added
            ))
        }
        
        return notifications
    }

    private fun showNotification(notification: Map<String, String>) {
        Log.d(TAG, "Step 8.1: Starting notification display process")
        val channelId = "nayifat_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "Step 8.2: Creating notification channel")
            val channel = NotificationChannel(
                channelId,
                "Nayifat Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications from Nayifat App"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Step 8.3: Notification channel created")
        }

        // Create intent to open the app
        Log.d(TAG, "Step 8.4: Creating intent to open app")
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            // Add the route if available
            notification["route"]?.let { route ->
                if (route.isNotEmpty()) {
                    Log.d(TAG, "Step 8.4.1: Adding route to intent: $route")
                    putExtra("initial_route", route)
                    // Get isArabic from SharedPreferences
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val isArabic = prefs.getBoolean("flutter.isArabic", false)
                    Log.d(TAG, "Step 8.4.2: Retrieved isArabic from SharedPreferences: $isArabic")
                    
                    // Store route and language preference
                    prefs.edit().apply {
                        putString("flutter.pending_notification_route", route)
                        putBoolean("flutter.pending_notification_is_arabic", isArabic)
                        apply()
                    }
                    Log.d(TAG, "Step 8.4.3: Stored route in SharedPreferences: $route")
                }
            }
        }

        // Create pending intent
        val pendingIntent = if (intent != null) {
            Log.d(TAG, "Step 8.4.4: Creating PendingIntent")
            PendingIntent.getActivity(
                context,
                notification["id"]?.toInt() ?: 1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            Log.e(TAG, "Step Error 8.4.5: Could not create launch intent")
            null
        }

        // Create notification builder
        Log.d(TAG, "Step 8.5: Building notification with title: ${notification["title"]}")
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(notification["title"])
            .setContentText(notification["body"])
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(1000, 1000, 1000))
            .setOnlyAlertOnce(false)

        // 💡 Handle images with proper error handling and fallbacks
        var hasLargeIcon = false
        var hasBigPicture = false

        // First try to set large icon
        val largeIconUrl = notification["largeIconUrl"]?.takeIf { it.isNotBlank() }
        if (!largeIconUrl.isNullOrBlank() && (largeIconUrl.startsWith("http://") || largeIconUrl.startsWith("https://"))) {
            try {
                Log.d(TAG, "Step 8.5.1: Setting large icon from URL: $largeIconUrl")
                val iconBitmap = getBitmapFromUrl(largeIconUrl)
                if (iconBitmap != null) {
                    builder.setLargeIcon(iconBitmap)
                    hasLargeIcon = true
                    Log.d(TAG, "Step 8.5.2: Large icon set successfully")
                } else {
                    Log.e(TAG, "Step 8.5.3: Failed to load large icon")
                    // Set default icon from resources
                    builder.setLargeIcon(android.graphics.BitmapFactory.decodeResource(context.resources, R.mipmap.launcher_icon))
                    hasLargeIcon = true
                }
            } catch (e: Exception) {
                Log.e(TAG, "Step 8.5.4: Error setting large icon: ${e.message}")
                // Set default icon from resources
                builder.setLargeIcon(android.graphics.BitmapFactory.decodeResource(context.resources, R.mipmap.launcher_icon))
                hasLargeIcon = true
            }
        } else {
            Log.d(TAG, "Step 8.5.1.1: Using default large icon")
            builder.setLargeIcon(android.graphics.BitmapFactory.decodeResource(context.resources, R.mipmap.launcher_icon))
            hasLargeIcon = true
        }

        // Then try to set big picture
        val bigPictureUrl = notification["bigPictureUrl"]?.takeIf { it.isNotBlank() }
        if (!bigPictureUrl.isNullOrBlank() && (bigPictureUrl.startsWith("http://") || bigPictureUrl.startsWith("https://"))) {
            try {
                Log.d(TAG, "Step 8.5.5: Setting big picture from URL: $bigPictureUrl")
                val imageBitmap = getBitmapFromUrl(bigPictureUrl)
                if (imageBitmap != null) {
                    val bigPictureStyle = NotificationCompat.BigPictureStyle()
                        .bigPicture(imageBitmap)
                        
                    // If we have a large icon, hide it when expanded
                    if (hasLargeIcon) {
                        bigPictureStyle.bigLargeIcon(null as android.graphics.Bitmap?)
                    }
                    
                    builder.setStyle(bigPictureStyle)
                    hasBigPicture = true
                    Log.d(TAG, "Step 8.5.6: Big picture set successfully")
                } else {
                    Log.e(TAG, "Step 8.5.7: Failed to load big picture")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Step 8.5.8: Error setting big picture: ${e.message}")
            }
        } else {
            Log.d(TAG, "Step 8.5.5.1: No valid big picture URL provided")
        }

        // If no big picture was set, use BigTextStyle as fallback
        if (!hasBigPicture) {
            builder.setStyle(NotificationCompat.BigTextStyle()
                .bigText(notification["body"]))
            Log.d(TAG, "Step 8.5.9: Using BigTextStyle as fallback")
        }

        // Set the pending intent if available
        pendingIntent?.let {
            builder.setContentIntent(it)
        }

        // Show the notification
        val notificationId = notification["id"]?.toInt() ?: 1
        Log.d(TAG, "Step 8.6: Displaying notification with ID: $notificationId")
        notificationManager.notify(notificationId, builder.build())
        Log.d(TAG, "Step 8.7: Notification displayed successfully")
    }

    // 💡 Helper function to load images from URLs with improved error handling and caching
    private fun getBitmapFromUrl(imageUrl: String): android.graphics.Bitmap? {
        return try {
            Log.d(TAG, "Step Image 1: Starting image download from: $imageUrl")
            val url = URL(imageUrl)
            val connection = url.openConnection() as HttpsURLConnection
            connection.apply {
                connectTimeout = 15000 // 15 seconds
                readTimeout = 15000
                doInput = true
                requestMethod = "GET"
                setRequestProperty("User-Agent", "Nayifat-Android-App")
            }

            Log.d(TAG, "Step Image 2: Connection configured, starting download")
            connection.connect()

            if (connection.responseCode == HttpsURLConnection.HTTP_OK) {
                val input = connection.inputStream
                val options = android.graphics.BitmapFactory.Options().apply {
                    // Decode bounds first
                    inJustDecodeBounds = true
                }
                
                // Read bounds
                android.graphics.BitmapFactory.decodeStream(input, null, options)
                input.close()

                // Calculate sample size
                options.apply {
                    inJustDecodeBounds = false
                    inSampleSize = calculateInSampleSize(options, 512, 512) // Target size for notification
                }

                // Reopen connection for actual download
                connection.disconnect()
                val newConnection = url.openConnection() as HttpsURLConnection
                newConnection.apply {
                    connectTimeout = 15000
                    readTimeout = 15000
                    doInput = true
                }

                Log.d(TAG, "Step Image 3: Downloading and decoding image")
                val bitmap = android.graphics.BitmapFactory.decodeStream(newConnection.inputStream, null, options)
                Log.d(TAG, "Step Image 4: Image downloaded successfully: ${bitmap != null}")
                bitmap
            } else {
                Log.e(TAG, "Step Image Error: Server returned code: ${connection.responseCode}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Step Image Error: Failed to load image: ${e.message}")
            e.printStackTrace()
            null
        }
    }

    // 💡 Helper function to calculate optimal sample size for image loading
    private fun calculateInSampleSize(options: android.graphics.BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val (height: Int, width: Int) = options.run { outHeight to outWidth }
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }
} 