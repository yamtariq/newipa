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
import javax.net.ssl.*
import android.app.Notification
import android.app.PendingIntent
import org.json.JSONArray
import android.content.SharedPreferences
import java.security.SecureRandom
import java.security.cert.X509Certificate
import android.media.RingtoneManager
import android.media.AudioAttributes
import android.graphics.Color
import com.example.nayifat_app_2025_new.R
import androidx.work.Constraints
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkRequest
import androidx.work.WorkManager
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.core.app.NotificationManagerCompat
import androidx.work.BackoffPolicy
import java.util.concurrent.TimeUnit

class NotificationWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private fun getApiBaseUrl(prefs: SharedPreferences): String {
            val useNewApi = prefs.getBoolean("flutter.useNewApi", true)
            // 💡 Read development URL from SharedPreferences, with fallback
            return if (useNewApi) {
                prefs.getString("flutter.apiBaseUrl", "https://tmappuat.nayifat.com/api") ?: "https://tmappuat.nayifat.com/api"
            } else {
                "https://icreditdept.com/api"
            }
        }
        private const val NOTIFICATIONS_ENDPOINT = "/notifications/list"
        private const val API_KEY = "7ca7427b418bdbd0b3b23d7debf69bf7"
        private const val TAG = "Tariq_NotificationWorker"
        
        // 💡 Add function to schedule periodic work
        fun schedulePeriodicWork(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<NotificationWorker>(
                15, TimeUnit.MINUTES,  // Minimum interval is 15 minutes
                5, TimeUnit.MINUTES    // Flex interval
            )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.LINEAR,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                    "notification_worker",
                    ExistingPeriodicWorkPolicy.KEEP,
                    workRequest
                )
            
            Log.d(TAG, "Scheduled periodic work for notifications")
        }
    }

    // 💡 Create a trust manager that trusts all certificates
    private fun createTrustAllCerts(): Array<TrustManager> {
        return arrayOf(object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {}
            override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {}
            override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
        })
    }

    // 💡 Configure SSL context to accept all certificates
    private fun configureSSL(): SSLContext {
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, createTrustAllCerts(), SecureRandom())
        HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.socketFactory)
        HttpsURLConnection.setDefaultHostnameVerifier { _, _ -> true }
        return sslContext
    }

    override fun doWork(): Result {
        Log.d(TAG, "Starting notification worker...")
        
        return try {
            // Get SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Check if notifications are enabled
            if (!areNotificationsEnabled()) {
                Log.d(TAG, "Notifications are disabled")
                return Result.success()
            }
            
            // Get national ID
            val nationalId = prefs.getString("flutter.national_id", null)
            if (nationalId == null) {
                Log.d(TAG, "No national ID found")
                return Result.retry()
            }

            Log.d(TAG, "Fetching notifications for ID: $nationalId")
            
            // Fetch notifications
            val notifications = fetchNotifications(nationalId)
            if (notifications.isEmpty()) {
                Log.d(TAG, "No new notifications found")
                return Result.success()
            }

            Log.d(TAG, "Found ${notifications.size} notifications")
            
            // Process notifications
            var successCount = 0
            notifications.forEach { notification ->
                try {
                    showNotification(notification)
                    successCount++
                } catch (e: Exception) {
                    Log.e(TAG, "Error showing notification: ${e.message}")
                }
            }

            Log.d(TAG, "Successfully showed $successCount notifications")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error in worker: ${e.message}", e)
            if (e is java.net.UnknownHostException || 
                e is java.net.SocketTimeoutException || 
                e is java.io.IOException) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    private fun areNotificationsEnabled(): Boolean {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // For Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = notificationManager.getNotificationChannel("nayifat_notifications")
            if (channel?.importance == NotificationManager.IMPORTANCE_NONE) {
                return false
            }
        }

        // Check if notifications are enabled for the app
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    private fun fetchNotificationsWithRetry(nationalId: String, maxRetries: Int = 3): Pair<Int, List<Map<String, String>>> {
        var retryCount = 0
        var lastException: Exception? = null

        while (retryCount < maxRetries) {
            try {
                val notifications = fetchNotifications(nationalId)
                return Pair(200, notifications)  // Return success status code with notifications
            } catch (e: Exception) {
                lastException = e
                Log.e(TAG, "Error fetching notifications (attempt ${retryCount + 1}/$maxRetries): ${e.message}")
                retryCount++
                if (retryCount < maxRetries) {
                    Thread.sleep(5000L * retryCount) // Exponential backoff
                }
            }
        }

        Log.e(TAG, "Failed to fetch notifications after $maxRetries attempts", lastException)
        return Pair(500, emptyList()) // Return error status code and empty list
    }

    private fun processNotifications(
        allNotifications: List<Map<String, String>>?,
        userNotifications: List<Map<String, String>>?
    ): List<Map<String, String>> {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val seenNotifications = prefs.getStringSet("flutter.seen_notifications", mutableSetOf()) ?: mutableSetOf()
        val newSeenNotifications = seenNotifications.toMutableSet()
        
        val result = mutableListOf<Map<String, String>>()

        // Process all notifications
        allNotifications?.forEach { notification ->
            val id = notification["id"]
            if (id != null && !seenNotifications.contains(id)) {
                result.add(notification)
                newSeenNotifications.add(id)
            }
        }

        // Process user notifications
        userNotifications?.forEach { notification ->
            val id = notification["id"]
            if (id != null && !seenNotifications.contains(id)) {
                result.add(notification)
                newSeenNotifications.add(id)
            }
        }

        // Update seen notifications
        if (newSeenNotifications.size > seenNotifications.size) {
            prefs.edit().putStringSet("flutter.seen_notifications", newSeenNotifications).apply()
        }

        return result
    }

    private fun fetchNotifications(nationalId: String?): List<Map<String, String>> {
        Log.d(TAG, "Step 4: Starting API calls")
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

            // 💡 Limit to 100 notifications for "all" target
            if (allNotifications.size > 100) {
                allNotifications.subList(0, 100)
                Log.d(TAG, "Trimmed notifications to latest 100")
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

            connection.apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("x-api-key", API_KEY)
                doOutput = true
                connectTimeout = 30000
                readTimeout = 30000
                // 💡 Trust all certificates for this connection
                sslSocketFactory = configureSSL().socketFactory
                hostnameVerifier = HostnameVerifier { _, _ -> true }
            }

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

    private fun showNotification(notificationData: Map<String, String>) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "nayifat_notifications"
        
        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Nayifat Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications from Nayifat App"
                enableLights(true)
                lightColor = Color.GREEN
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Create an Intent for when notification is tapped
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("route", "/notifications")  // Add route for navigation
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Get notification content based on language
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isArabic = prefs.getBoolean("flutter.isArabic", false)
        
        val title = if (isArabic) {
            notificationData["title_ar"] ?: notificationData["title"] ?: "إشعار جديد"
        } else {
            notificationData["title"] ?: notificationData["title_ar"] ?: "New Notification"
        }
        
        val body = if (isArabic) {
            notificationData["body_ar"] ?: notificationData["body"] ?: "لديك إشعار جديد"
        } else {
            notificationData["body"] ?: notificationData["body_ar"] ?: "You have a new notification"
        }

        // Build the notification
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.nayifatlogocircle_nobg)  // 💡 Use the Nayifat logo as notification icon
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setDefaults(Notification.DEFAULT_ALL)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setContentIntent(pendingIntent)
            .setTimeoutAfter(24 * 60 * 60 * 1000) // 24 hours
            .build()

        // Show the notification with a unique ID based on current time
        val notificationId = System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notification)
        
        Log.d(TAG, "Step 8.4: Notification displayed - ID: $notificationId, Title: $title")
    }

    // 💡 Helper function to load images from URLs with improved error handling and caching
    private fun getBitmapFromUrl(imageUrl: String): android.graphics.Bitmap? {
        var connection: HttpsURLConnection? = null
        try {
            Log.d(TAG, "Step Image 1: Starting image download from: $imageUrl")
            val url = URL(imageUrl)
            connection = url.openConnection() as HttpsURLConnection
            connection.apply {
                connectTimeout = 15000 // 15 seconds
                readTimeout = 15000
                doInput = true
                requestMethod = "GET"
                setRequestProperty("User-Agent", "Nayifat-Android-App")
                // 💡 Accept image content types
                setRequestProperty("Accept", "image/*")
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

                // Calculate sample size based on notification size requirements
                options.apply {
                    inJustDecodeBounds = false
                    // 💡 Use different target sizes for large icon and big picture
                    val maxSize = if (imageUrl.contains("largeIcon")) {
                        128 // Large icon size
                    } else {
                        512 // Big picture size
                    }
                    inSampleSize = calculateInSampleSize(options, maxSize, maxSize)
                }

                // Reopen connection for actual download
                connection.disconnect()
                connection = url.openConnection() as HttpsURLConnection
                connection.apply {
                    connectTimeout = 15000
                    readTimeout = 15000
                    doInput = true
                    // 💡 Accept image content types
                    setRequestProperty("Accept", "image/*")
                }

                Log.d(TAG, "Step Image 3: Downloading and decoding image")
                val bitmap = android.graphics.BitmapFactory.decodeStream(connection.inputStream, null, options)
                
                if (bitmap != null) {
                    // 💡 Process bitmap based on usage
                    return if (imageUrl.contains("largeIcon")) {
                        // Round the large icon
                        getRoundedBitmap(bitmap)
                    } else {
                        // Scale and process big picture
                        getProcessedBigPicture(bitmap)
                    }
                }
                Log.d(TAG, "Step Image 4: Image downloaded and processed successfully")
                return bitmap
            } else {
                Log.e(TAG, "Step Image Error: Server returned code: ${connection.responseCode}")
                return null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Step Image Error: Failed to load image: ${e.message}")
            e.printStackTrace()
            return null
        } finally {
            connection?.disconnect()
        }
    }

    // 💡 Helper function to create rounded bitmap for large icons
    private fun getRoundedBitmap(bitmap: android.graphics.Bitmap): android.graphics.Bitmap {
        val output = android.graphics.Bitmap.createBitmap(
            bitmap.width,
            bitmap.height,
            android.graphics.Bitmap.Config.ARGB_8888
        )
        val canvas = android.graphics.Canvas(output)
        val paint = android.graphics.Paint().apply {
            isAntiAlias = true
            shader = android.graphics.BitmapShader(
                bitmap,
                android.graphics.Shader.TileMode.CLAMP,
                android.graphics.Shader.TileMode.CLAMP
            )
        }
        val rect = android.graphics.RectF(0f, 0f, bitmap.width.toFloat(), bitmap.height.toFloat())
        canvas.drawRoundRect(rect, bitmap.width / 2f, bitmap.height / 2f, paint)
        return output
    }

    // 💡 Helper function to process big picture
    private fun getProcessedBigPicture(bitmap: android.graphics.Bitmap): android.graphics.Bitmap {
        // Scale bitmap if needed
        val maxSize = 1024
        if (bitmap.width > maxSize || bitmap.height > maxSize) {
            val scale = maxSize.toFloat() / Math.max(bitmap.width, bitmap.height)
            val matrix = android.graphics.Matrix()
            matrix.postScale(scale, scale)
            return android.graphics.Bitmap.createBitmap(
                bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
            )
        }
        return bitmap
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