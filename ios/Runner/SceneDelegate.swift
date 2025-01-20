import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let flutterViewController = FlutterViewController(project: nil, initialRoute: nil, nibName: nil, bundle: nil)
        window?.rootViewController = flutterViewController
        window?.makeKeyAndVisible()
        
        // Handle any deep links that were used to launch the app
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        }
        
        if let urlContext = connectionOptions.urlContexts.first {
            self.scene(scene, openURLContexts: URLContexts([urlContext]))
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }
        
        handleDeepLink(url: url)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        handleDeepLink(url: url)
    }
    
    private func handleDeepLink(url: URL) {
        guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        let channel = FlutterMethodChannel(name: "plugins.flutter.io/uni_links",
                                         binaryMessenger: flutterViewController.binaryMessenger)
        
        channel.invokeMethod("onLink", arguments: url.absoluteString)
    }
} 