import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

// Share Extension di Beet-It — AUTONOMA (Swift puro, nessuna dipendenza).
//
// Quando condividi da un'app SOCIAL a cui sei loggato (Facebook, Instagram,
// TikTok…), la condivisione porta con sé anche la DIDASCALIA/descrizione del
// post (contenuto autenticato). Qui la leggiamo TUTTA — non solo l'URL — e la
// passiamo all'app nell'URL di riapertura (`?u=<link>&cap=<didascalia>`).
@objc(ShareViewController)
class ShareViewController: UIViewController {

    private let hostBundleId = "io.beetit.recipes"
    private let schemePrefix = "ShareMedia"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        process()
    }

    // Diagnostica del payload grezzo (debug con singolo utente).
    private var diagUTIs: [String] = []
    private var diagAttr: [String] = []

    private func process() {
        let urlUTI = "public.url"
        let textUTIs = ["public.plain-text", "public.utf8-plain-text", "public.text"]

        var link: String? = nil
        var caption = ""
        let group = DispatchGroup()

        for case let item as NSExtensionItem in extensionContext?.inputItems ?? [] {
            // La didascalia condivisa dall'app loggata spesso è qui.
            if let attr = item.attributedContentText?.string {
                diagAttr.append(attr)
                if attr.count > caption.count { caption = attr }
            }
            for provider in item.attachments ?? [] {
                diagUTIs.append(contentsOf: provider.registeredTypeIdentifiers)
                if provider.hasItemConformingToTypeIdentifier(urlUTI) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: urlUTI, options: nil) { data, _ in
                        if link == nil {
                            if let u = data as? URL { link = u.absoluteString }
                            else if let s = data as? String { link = s }
                        }
                        group.leave()
                    }
                }
                for t in textUTIs where provider.hasItemConformingToTypeIdentifier(t) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: t, options: nil) { data, _ in
                        let s = (data as? String) ?? (data as? URL)?.absoluteString ?? ""
                        if s.count > caption.count { caption = s }
                        group.leave()
                    }
                    break
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.complete(link: link, caption: caption)
        }
    }

    // Manda il payload grezzo al server di debug, poi prosegue (fire, breve attesa).
    private func postDebug(link: String?, caption: String, then: @escaping () -> Void) {
        guard let u = URL(string: "http://185.218.126.96:8090/api/debug-log") else { return then() }
        let body: [String: Any] = [
            "src": "iosShareExt",
            "utis": diagUTIs,
            "attrTexts": diagAttr,
            "loadedUrl": link ?? "",
            "loadedCaptionLen": caption.count,
            "loadedCaption": String(caption.prefix(4000)),
        ]
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 4
        var done = false
        let finish = { if !done { done = true; DispatchQueue.main.async { then() } } }
        URLSession.shared.dataTask(with: req) { _, _, _ in finish() }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { finish() } // safety
    }

    private func complete(link: String?, caption: String) {
        postDebug(link: link, caption: caption) { [weak self] in
            self?.doComplete(link: link, caption: caption)
        }
    }

    private func doComplete(link: String?, caption: String) {
        // Se non abbiamo un URL esplicito ma la didascalia contiene un link, usalo.
        var finalLink = link
        if finalLink == nil,
           let r = caption.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
            finalLink = String(caption[r])
        }
        var comps = URLComponents()
        comps.scheme = "\(schemePrefix)-\(hostBundleId)"
        comps.host = "import"
        var items: [URLQueryItem] = []
        if let l = finalLink { items.append(URLQueryItem(name: "u", value: l)) }
        let cap = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if cap.count >= 40 { items.append(URLQueryItem(name: "cap", value: cap)) }
        comps.queryItems = items

        if !items.isEmpty, let url = comps.url {
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
