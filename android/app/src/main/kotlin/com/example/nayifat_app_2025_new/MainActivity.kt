package com.example.nayifat_app_2025_new

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.work.*
import android.util.Log
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import android.os.Build
import java.util.concurrent.TimeUnit
import androidx.lifecycle.Observer

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.nayifat_app_2025_new/background_service"
    private val TAG = "Tariq_NotificationWorker"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "Step M1: MainActivity onCreate called")
        
        try {
            // Start the background work
            startBackgroundWork()
        } catch (e: Exception) {
            Log.e(TAG, "Step Error M1: Error in onCreate: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun startBackgroundWork() {
        try {
            Log.d(TAG, "Step M2: Starting background work setup")

            // Create work constraints
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            Log.d(TAG, "Step M3: Work constraints created - Network required")

            // Create periodic work request that runs every 15 minutes
            val periodicWorkRequest = PeriodicWorkRequestBuilder<NotificationWorker>(
                15, TimeUnit.MINUTES,  // Repeat interval
                5, TimeUnit.MINUTES    // Flex interval
            )
            .setConstraints(constraints)
            .build()
            Log.d(TAG, "Step M4: 15-minute periodic work request created")

            // Create 2-minute check work request
            val frequentCheckRequest = PeriodicWorkRequestBuilder<NotificationWorker>(
                2, TimeUnit.MINUTES,  // Run every 2 minutes
                1, TimeUnit.MINUTES   // Flex interval
            )
            .setConstraints(constraints)
            .build()
            Log.d(TAG, "Step M5: 2-minute check work request created")

            // Get WorkManager instance
            val workManager = WorkManager.getInstance(applicationContext)

            // Get current work status
            workManager.getWorkInfosForUniqueWorkLiveData("notification_work")
                .observe(this, Observer { workInfoList ->
                    workInfoList?.let { list ->
                        if (list.isNotEmpty()) {
                            Log.d(TAG, "Step M6: Existing work status: ${list.first().state}")
                        }
                    }
                })

            // Enqueue the 15-minute periodic work
            workManager.enqueueUniquePeriodicWork(
                "notification_work",
                ExistingPeriodicWorkPolicy.REPLACE,
                periodicWorkRequest
            )
            Log.d(TAG, "Step M7: 15-minute periodic work enqueued")

            // Enqueue the 2-minute check work
            workManager.enqueueUniquePeriodicWork(
                "notification_frequent_check",
                ExistingPeriodicWorkPolicy.REPLACE,
                frequentCheckRequest
            )
            Log.d(TAG, "Step M8: 2-minute check work enqueued")
            
            // Schedule immediate one-time work to check notifications now
            val immediateWork = OneTimeWorkRequestBuilder<NotificationWorker>()
                .setConstraints(constraints)
                .build()
            workManager.enqueue(immediateWork)
            Log.d(TAG, "Step M9: Immediate work request enqueued")

            // Log all active work
            workManager.getWorkInfosLiveData(WorkQuery.fromStates(WorkInfo.State.RUNNING))
                .observe(this, Observer { workInfoList ->
                    Log.d(TAG, "Step M10: Current active work count: ${workInfoList.size}")
                    workInfoList.forEach { workInfo ->
                        Log.d(TAG, "Step M10.1: Work ID: ${workInfo.id}, State: ${workInfo.state}")
                    }
                })

        } catch (e: Exception) {
            Log.e(TAG, "Step Error M2: Error starting work: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    Log.d(TAG, "Step M11: Received startBackgroundService call from Flutter")
                    startBackgroundWork()
                    result.success(null)
                    Log.d(TAG, "Step M12: Responded to startBackgroundService call")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
} 