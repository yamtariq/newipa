import UIKit
import Flutter
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
        
        // Register background task (handler now exists)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.nayifat.app.notification_refresh",
            using: nil
        ) { task in
            BackgroundTaskHandler.shared.handleTask(task as! BGAppRefreshTask)
        }
        
        // Register Flutter plugins (this uses GeneratedPluginRegistrant)
        GeneratedPluginRegistrant.register(with: self)
        
        // Set notification center delegate (iOS 13+)
        if #available(iOS 13.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        BackgroundTaskHandler.shared.scheduleTask()
    }
}
