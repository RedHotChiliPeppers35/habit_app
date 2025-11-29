import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  var lastAPNsToken: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Ask for notification permission
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      print("🔔 Notification permission granted: \(granted), error: \(String(describing: error))")
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    }

    // Also attempt registration (will only succeed if permission granted)
    application.registerForRemoteNotifications()

    // Setup MethodChannel so Flutter can ask for current token
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "apns_channel",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "getCurrentToken" {
          result(self?.lastAPNsToken)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called when APNs gives us the device token
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let apnsToken = tokenParts.joined()
    print("APNs Device Token: \(apnsToken)")

    self.lastAPNsToken = apnsToken

    // Send token immediately to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "apns_channel",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("apnsToken", arguments: apnsToken)
    }

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // 🔥 Show notifications even when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("📩 Will present notification: \(notification.request.identifier)")
    completionHandler([.alert, .sound, .badge])  // .alert works on older iOS too
  }

}
