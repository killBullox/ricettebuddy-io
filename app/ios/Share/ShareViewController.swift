import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

// Share Extension di Beet-It — AUTONOMA (Swift puro, nessuna dipendenza).
//
// Riceve un link/testo condiviso da altre app (Instagram, TikTok, Facebook,
// YouTube, Safari…), lo salva nell'App Group nello STESSO formato che il
// plugin receive_sharing_intent legge lato Flutter, e riapre l'app principale
// tramite lo schema URL. L'app poi importa la ricetta.
//
// @objc(ShareViewController) fissa il nome runtime a "ShareViewController"
// così NSExtensionPrincipalClass nell'Info.plist risolve senza prefisso modulo.
@objc(ShareViewController)
class ShareViewController: UIViewController {

    // Devono combaciare con la configurazione dell'app principale.
    private let appGroupId = "group.io.beetit.recipes"
    private let hostBundleId = "io.beetit.recipes"
    private let shareKey = "ShareKey"            // kUserDefaultsKey del plugin
    private let messageKey = "ShareMessageKey"   // kUserDefaultsMessageKey del plugin
    private let schemePrefix = "ShareMedia"      // kSchemePrefix del plugin

    // Rispecchia SharedMediaFile del plugin (obbligatori: path, type).
    private struct SharedFile: Codable {
        let path: String
        let mimeType: String?
        let thumbnail: String?
        let duration: Double?
        let message: String?
        let type: String   // "url" | "text"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        process()
    }

    private func process() {
        let urlUTI = "public.url"
        let textUTI = "public.plain-text"

        var providers: [NSItemProvider] = []
        for case let item as NSExtensionItem in extensionContext?.inputItems ?? [] {
            providers.append(contentsOf: item.attachments ?? [])
        }
        guard !providers.isEmpty else { return finish([]) }

        var results: [SharedFile] = []
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(urlUTI) {
                group.enter()
                provider.loadItem(forTypeIdentifier: urlUTI, options: nil) { data, _ in
                    if let url = data as? URL {
                        results.append(SharedFile(path: url.absoluteString, mimeType: nil,
                                                  thumbnail: nil, duration: nil, message: nil, type: "url"))
                    } else if let s = data as? String {
                        results.append(SharedFile(path: s, mimeType: nil,
                                                  thumbnail: nil, duration: nil, message: nil, type: "url"))
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(textUTI) {
                group.enter()
                provider.loadItem(forTypeIdentifier: textUTI, options: nil) { data, _ in
                    if let s = data as? String {
                        results.append(SharedFile(path: s, mimeType: "text/plain",
                                                  thumbnail: nil, duration: nil, message: nil, type: "text"))
                    } else if let url = data as? URL {
                        results.append(SharedFile(path: url.absoluteString, mimeType: "text/plain",
                                                  thumbnail: nil, duration: nil, message: nil, type: "text"))
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.finish(results)
        }
    }

    private func finish(_ results: [SharedFile]) {
        if !results.isEmpty, let ud = UserDefaults(suiteName: appGroupId) {
            if let data = try? JSONEncoder().encode(results) {
                ud.set(data, forKey: shareKey)
            }
            ud.removeObject(forKey: messageKey)
            ud.synchronize()
            redirectToHost()
        } else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // Riapre l'app principale risalendo la responder chain (come fa il plugin).
    private func redirectToHost() {
        guard let url = URL(string: "\(schemePrefix)-\(hostBundleId):share") else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        var responder: UIResponder? = self
        if #available(iOS 18.0, *) {
            while responder != nil {
                if let app = responder as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                }
                responder = responder?.next
            }
        } else {
            let sel = sel_registerName("openURL:")
            while responder != nil {
                if responder?.responds(to: sel) == true {
                    _ = responder?.perform(sel, with: url)
                }
                responder = responder?.next
            }
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
