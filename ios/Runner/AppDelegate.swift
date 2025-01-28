import UIKit
import Flutter.Flutter
import GoogleMaps
import AVFoundation
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Provide Google Maps API key
        GMSServices.provideAPIKey("AIzaSyDtpHNagyWnQXZXoJzuX0hJch7KDIZPLdE")
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "\(Bundle.main.bundleIdentifier!).notification_refresh",
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        
        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: self)
        
        // Set notification center delegate (iOS 13+)
        if #available(iOS 13.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        // Schedule the next background task
        scheduleBackgroundTask()
        
        // Expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Trigger notification check in Flutter
        guard let controller = window?.rootViewController as? FlutterViewController else {
            task.setTaskCompleted(success: false)
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.nayifat.nayifat_app_2025_new/background_service",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.invokeMethod("checkNotifications", arguments: nil) { _ in
            task.setTaskCompleted(success: true)
        }
    }
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "\(Bundle.main.bundleIdentifier!).notification_refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundTask()
    }
}
