import Flutter
import UIKit
import GoogleMaps
import AVFoundation
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TODO: Replace with your actual Google Maps API key
    GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY")
    
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
    ) { task in
      self.handleBackgroundTask(task: task as! BGAppRefreshTask)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure background fetch
    if #available(iOS 13.0, *) {
        UNUserNotificationCenter.current().delegate = self
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func handleBackgroundTask(task: BGAppRefreshTask) {
    // Schedule the next background task
    scheduleBackgroundTask()
    
    // Create a task to track remaining background time
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    
    // Trigger notification check through Flutter method channel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.nayifat.nayifat_app_2025_new/background_service",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.invokeMethod("checkNotifications", arguments: nil) { result in
      task.setTaskCompleted(success: true)
    }
  }
  
  func scheduleBackgroundTask() {
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
