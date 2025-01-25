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

class NotificationWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val BASE_URL = "https://icreditdept.com/api"
        private const val API_KEY = "7ca7427b418bdbd0b3b23d7debf69bf7"
        private const val TAG = "Tariq_NotificationWorker"
    }

    override fun doWork(): Result {
        Log.d(TAG, "Step 1: Worker Started - Time: ${System.currentTimeMillis()}")
        try {
            // Get national ID from SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            Log.d(TAG, "Step 2: Checking SharedPreferences")
            Log.d(TAG, "Step 2.1: Available SharedPreferences keys:")
            prefs.all.forEach { (key, value) ->
                Log.d(TAG, "Step 2.2: Found Key: $key, Value: $value")
            }
            
            val nationalId = prefs.getString("flutter.national_id", null)
            Log.d(TAG, "Step 3: National ID check - ${if (nationalId != null) "Found ID: $nationalId" else "No ID found"}")
            
            if (nationalId == null) {
                Log.e(TAG, "Step 3.1: Error - No national ID in SharedPreferences")
                return Result.success()
            }

            // Fetch notifications from API
            Log.d(TAG, "Step 4: Starting API call for ID: $nationalId")
            val notifications = fetchNotifications(nationalId)
            Log.d(TAG, "Step 7: API call complete - Found ${notifications.size} notifications")

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

    private fun fetchNotifications(nationalId: String): List<Map<String, String>> {
        Log.d(TAG, "Step 4.1: Setting up API call")
        val url = URL("$BASE_URL/get_notifications.php")
        val connection = url.openConnection() as HttpsURLConnection
        
        try {
            // Get language setting
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isArabic = prefs.getBoolean("flutter.isArabic", false)
            Log.d(TAG, "Step 4.1.1: App language setting - isArabic: $isArabic")

            Log.d(TAG, "Step 4.2: Configuring connection to: ${url}")
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("api-key", API_KEY)
            connection.doOutput = true
            connection.connectTimeout = 30000
            connection.readTimeout = 30000

            val requestBody = JSONObject().apply {
                put("national_id", nationalId)
                put("mark_as_read", true)
            }
            Log.d(TAG, "Step 4.3: Request body prepared: ${requestBody}")
            Log.d(TAG, "Step 4.4: Headers - api-key: ${connection.getRequestProperty("api-key")}")

            Log.d(TAG, "Step 5: Sending API request")
            connection.outputStream.use { os ->
                os.write(requestBody.toString().toByteArray())
            }

            val responseCode = connection.responseCode
            Log.d(TAG, "Step 6.1: API Response code: $responseCode")

            val response = if (responseCode in 200..299) {
                connection.inputStream.bufferedReader().use { it.readText() }
            } else {
                connection.errorStream.bufferedReader().use { it.readText() }
            }
            Log.d(TAG, "Step 6.2: API Response body: $response")

            val jsonResponse = JSONObject(response)
            Log.d(TAG, "Step 6.3: Response status: ${jsonResponse.optString("status")}")

            if (jsonResponse.getString("status") == "success") {
                val notificationsArray = jsonResponse.getJSONArray("notifications")
                val notifications = mutableListOf<Map<String, String>>()

                for (i in 0 until notificationsArray.length()) {
                    val notif = notificationsArray.getJSONObject(i)
                    
                    // Get title based on language with more robust null checking
                    val titleAr = notif.optString("title_ar")?.takeIf { it.isNotBlank() }
                    val titleEn = notif.optString("title_en")?.takeIf { it.isNotBlank() }
                    val titleGeneric = notif.optString("title")?.takeIf { it.isNotBlank() }
                    
                    val title = when {
                        isArabic && !titleAr.isNullOrBlank() -> titleAr
                        !isArabic && !titleEn.isNullOrBlank() -> titleEn
                        !titleGeneric.isNullOrBlank() -> titleGeneric
                        else -> "Nayifat Notification"
                    }

                    // Get body based on language with more robust null checking
                    val bodyAr = notif.optString("body_ar")?.takeIf { it.isNotBlank() }
                    val bodyEn = notif.optString("body_en")?.takeIf { it.isNotBlank() }
                    val bodyGeneric = notif.optString("body")?.takeIf { it.isNotBlank() }
                    
                    val body = when {
                        isArabic && !bodyAr.isNullOrBlank() -> bodyAr
                        !isArabic && !bodyEn.isNullOrBlank() -> bodyEn
                        !bodyGeneric.isNullOrBlank() -> bodyGeneric
                        else -> "You have a new notification"
                    }

                    // Enhanced debug logging
                    Log.d(TAG, """
                        Step 6.4.1: Notification content debug:
                        Language Mode: ${if (isArabic) "Arabic" else "English"}
                        Available Titles:
                          - title_ar: ${titleAr ?: "NULL/EMPTY"}
                          - title_en: ${titleEn ?: "NULL/EMPTY"}
                          - title: ${titleGeneric ?: "NULL/EMPTY"}
                        Selected Title: $title
                        Available Bodies:
                          - body_ar: ${bodyAr ?: "NULL/EMPTY"}
                          - body_en: ${bodyEn ?: "NULL/EMPTY"}
                          - body: ${bodyGeneric ?: "NULL/EMPTY"}
                        Selected Body: $body
                    """.trimIndent())

                    // Verify content before adding to notifications list
                    if (title.isBlank() || body.isBlank()) {
                        Log.e(TAG, "Step 6.4.2: Warning - Empty title or body after processing")
                        continue
                    }

                    notifications.add(mapOf(
                        "id" to (notif.optString("id") ?: System.currentTimeMillis().toString()),
                        "title" to title,
                        "body" to body,
                        "route" to notif.optString("route", ""),
                        "created_at" to notif.optString("created_at", ""),
                        "expires_at" to notif.optString("expires_at", "")
                    ))
                    Log.d(TAG, "Step 6.4.3: Successfully added notification: ID=${notif.optString("id")}, Title=$title")
                }
                Log.d(TAG, "Step 6.5: Successfully parsed ${notifications.size} notifications")
                return notifications
            } else {
                Log.e(TAG, "Step 6.6: API returned non-success status: ${jsonResponse.optString("message", "Unknown error")}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Step Error: API call failed: ${e.message}")
            e.printStackTrace()
        } finally {
            connection.disconnect()
            Log.d(TAG, "Step 6.7: API Connection closed")
        }
        
        return emptyList()
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

        // Create notification
        Log.d(TAG, "Step 8.5: Building notification with title: ${notification["title"]}")
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(notification["title"])
            .setContentText(notification["body"])
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(1000, 1000, 1000))
            .setOnlyAlertOnce(false)

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
} 