package com.example.nayifat_app_2025_new

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.work.*
import android.content.Context
import android.os.Build
import android.util.Log
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nayifat.app/background_service"
    private val TAG = "Tariq_MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    startBackgroundService()
                    result.success(null)
                }
                "stopBackgroundService" -> {
                    stopBackgroundService()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startBackgroundService() {
        Log.d(TAG, "Starting background service")
        
        // Create WorkManager configuration
        val config = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.DEBUG)
            .build()
        
        // Initialize WorkManager with configuration
        WorkManager.initialize(applicationContext, config)

        // Create constraints
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(false)
            .build()

        // Create periodic work request
        val workRequest = PeriodicWorkRequestBuilder<NotificationWorker>(
            15, TimeUnit.MINUTES,  // Minimum interval allowed by Android
            5, TimeUnit.MINUTES    // Flex interval
        )
        .setConstraints(constraints)
        .setBackoffCriteria(
            BackoffPolicy.LINEAR,
            WorkRequest.MIN_BACKOFF_MILLIS,
            TimeUnit.MILLISECONDS
        )
        .addTag("notification_worker")
        .build()

        // Enqueue the work with REPLACE policy
        WorkManager.getInstance(applicationContext)
            .enqueueUniquePeriodicWork(
                "notification_worker",
                ExistingPeriodicWorkPolicy.REPLACE,
                workRequest
            )

        Log.d(TAG, "Background service started")
    }

    private fun stopBackgroundService() {
        Log.d(TAG, "Stopping background service")
        WorkManager.getInstance(applicationContext)
            .cancelUniqueWork("notification_worker")
        Log.d(TAG, "Background service stopped")
    }
} 