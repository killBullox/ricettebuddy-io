import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Canale per leggere il link condiviso catturato dallo schema URL nel
    // SceneDelegate. Nessun App Group: solo lo schema URL registrato.
    if let messenger = engineBridge.pluginRegistry
        .registrar(forPlugin: "BeetItShare")?.messenger() {
      let channel = FlutterMethodChannel(name: "beetit/share", binaryMessenger: messenger)
      channel.setMethodCallHandler { call, result in
        guard call.method == "getSharedUrl" else {
          result(FlutterMethodNotImplemented); return
        }
        let u = SceneDelegate.pendingSharedUrl
        SceneDelegate.pendingSharedUrl = nil   // consuma una sola volta
        result(u)
      }
    }
  }
}
