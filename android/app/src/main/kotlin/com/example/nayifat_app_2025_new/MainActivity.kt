package com.example.nayifat_app_2025_new

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.work.WorkManager
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nayifat.app/background_service"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize WorkManager
        WorkManager.getInstance(applicationContext)
        
        // Schedule the notification worker
        NotificationWorker.schedulePeriodicWork(applicationContext)
        Log.d("MainActivity", "Initialized WorkManager and scheduled NotificationWorker")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    NotificationWorker.schedulePeriodicWork(applicationContext)
                    result.success(null)
                }
                "stopBackgroundService" -> {
                    WorkManager.getInstance(applicationContext)
                        .cancelUniqueWork("notification_worker")
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
} 