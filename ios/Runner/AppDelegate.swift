import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appSettingsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    appSettingsChannel = FlutterMethodChannel(
      name: "leximon/app_settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    appSettingsChannel?.setMethodCallHandler { call, result in
      guard call.method == "openAppSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }

      UIApplication.shared.open(settingsUrl) { opened in
        result(opened)
      }
    }
  }
}
