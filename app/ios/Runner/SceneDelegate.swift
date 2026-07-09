import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  // Link + didascalia condivisi (catturati dallo schema URL), letti da Flutter
  // via il canale "beetit/share".
  static var pendingSharedUrl: String?
  static var pendingSharedCaption: String?

  // App aperta a freddo da una condivisione.
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions) {
    if let url = connectionOptions.urlContexts.first?.url { SceneDelegate.capture(url) }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  // App già in esecuzione riportata in primo piano dalla condivisione.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url { SceneDelegate.capture(url) }
    super.scene(scene, openURLContexts: URLContexts)
  }

  static func capture(_ url: URL) {
    guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
    let items = comps.queryItems
    if let u = items?.first(where: { $0.name == "u" })?.value, !u.isEmpty {
      pendingSharedUrl = u
    }
    if let c = items?.first(where: { $0.name == "cap" })?.value, !c.isEmpty {
      pendingSharedCaption = c
    }
  }
}
