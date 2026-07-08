import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

// Share Extension di Beet-It — AUTONOMA (Swift puro, nessuna dipendenza).
//
// Riceve un link/testo condiviso da altre app (Instagram, TikTok, Facebook,
// YouTube, Safari…) e riapre l'app principale passando il link DIRETTAMENTE
// nell'URL di riapertura (query `?u=<link>`). Nessun App Group: niente
// entitlement/provisioning speciale, solo lo schema URL registrato nell'app.
@objc(ShareViewController)
class ShareViewController: UIViewController {

    private let hostBundleId = "io.beetit.recipes"
    private let schemePrefix = "ShareMedia"   // schema registrato: ShareMedia-io.beetit.recipes

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
        guard !providers.isEmpty else { return complete(nil) }

        var link: String? = nil
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(urlUTI) {
                group.enter()
                provider.loadItem(forTypeIdentifier: urlUTI, options: nil) { data, _ in
                    if link == nil {
                        if let u = data as? URL { link = u.absoluteString }
                        else if let s = data as? String { link = s }
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(textUTI) {
                group.enter()
                provider.loadItem(forTypeIdentifier: textUTI, options: nil) { data, _ in
                    if link == nil {
                        if let s = data as? String { link = s }
                        else if let u = data as? URL { link = u.absoluteString }
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.complete(link)
        }
    }

    private func complete(_ link: String?) {
        if let link = link,
           let enc = link.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
           let url = URL(string: "\(schemePrefix)-\(hostBundleId)://import?u=\(enc)") {
            redirect(to: url)
        } else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // Riapre l'app principale risalendo la responder chain.
    private func redirect(to url: URL) {
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
