//
// BackgroundTaskHandler.swift
// Runner
//
// Created by [Your Name] on [Date].
//

import Foundation
import BackgroundTasks

class BackgroundTaskHandler {
    static let shared = BackgroundTaskHandler()
    
    private init() { }
    
    // Handles the background refresh task
    func handleTask(_ task: BGAppRefreshTask) {
        // Insert your background task handling logic here.
        // Ensure you call task.setTaskCompleted(success:) when done.
        task.setTaskCompleted(success: true)
    }
    
    // Schedules the background refresh task
    func scheduleTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.nayifat.app.notification_refresh")
        // For example, schedule earliest after 15 minutes.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }
} 