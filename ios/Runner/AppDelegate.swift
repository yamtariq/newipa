import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 💡 Configure notification icon and permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
            
            // 💡 Set default notification icon
            if let iconImage = UIImage(named: "NotificationIcon") {
              let icon = UNNotificationAttachment.makeAttachment(
                from: iconImage,
                identifier: "notificationIcon"
              )
              if let attachment = icon {
                let content = UNMutableNotificationContent()
                content.attachments = [attachment]
              }
            }
          }
        }
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 💡 Set notification presentation options for iOS 10 and above
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
}

// 💡 Helper extension for creating notification attachments
extension UNNotificationAttachment {
  static func makeAttachment(from image: UIImage, identifier: String) -> UNNotificationAttachment? {
    let fileManager = FileManager.default
    let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
    let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
    
    do {
      try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
      let imageFileIdentifier = identifier + ".png"
      let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
      
      guard let imageData = image.pngData() else { return nil }
      try imageData.write(to: fileURL)
      
      let imageAttachment = try UNNotificationAttachment(identifier: identifier, url: fileURL, options: nil)
      return imageAttachment
    } catch {
      print("Error creating notification attachment: \(error)")
      return nil
    }
  }
}
