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

    // Canale per leggere il link condiviso dall'App Group (scritto dalla Share
    // Extension). Bypassa la consegna dell'URL al plugin: robusto col ciclo di
    // vita a "scene" di Flutter, dove l'apertura via URL non sempre arriva.
    if let messenger = engineBridge.pluginRegistry
        .registrar(forPlugin: "BeetItShare")?.messenger() {
      let channel = FlutterMethodChannel(name: "beetit/share", binaryMessenger: messenger)
      channel.setMethodCallHandler { call, result in
        guard call.method == "getSharedUrl" else {
          result(FlutterMethodNotImplemented); return
        }
        let ud = UserDefaults(suiteName: "group.io.beetit.recipes")
        var found: String? = nil
        if let data = ud?.data(forKey: "ShareKey"),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let path = arr.first?["path"] as? String, !path.isEmpty {
          found = path
        }
        ud?.removeObject(forKey: "ShareKey")   // consuma una sola volta
        result(found)
      }
    }
  }
}
