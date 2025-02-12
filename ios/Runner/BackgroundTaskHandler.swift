class BackgroundTaskHandler {
    static let shared = BackgroundTaskHandler()
    private let taskIdentifier = "com.nayifat.app.notification_refresh"
    
    func scheduleTask() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule task: \(error)")
        }
    }
    
    func handleTask(_ task: BGAppRefreshTask) {
        scheduleTask() // Schedule next task first
        
        let taskTimeout = 25.0 // iOS allows max 30 seconds
        
        task.expirationHandler = {
            // Cleanup and mark task complete
            task.setTaskCompleted(success: false)
        }
        
        // Create method channel
        guard let controller = UIApplication.shared.windows.first?.rootViewController as? FlutterViewController else {
            task.setTaskCompleted(success: false)
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.nayifat.app/background_service",
            binaryMessenger: controller.binaryMessenger)
        
        // Execute with timeout
        let taskTimer = Timer.scheduledTimer(withTimeInterval: taskTimeout, repeats: false) { _ in
            task.setTaskCompleted(success: false)
        }
        
        channel.invokeMethod("checkNotifications", arguments: nil) { result in
            taskTimer.invalidate()
            task.setTaskCompleted(success: result as? Bool ?? false)
        }
    }
} 