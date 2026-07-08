import receive_sharing_intent

// Share Extension di Beet-It: riceve link/testo/immagini condivisi da altre app
// (Instagram, TikTok, Facebook, YouTube, Safari...) e li passa all'app principale
// tramite l'App Group, che poi li importa.
class ShareViewController: RSIShareViewController {
    // Reindirizza automaticamente all'app principale dopo aver ricevuto il contenuto.
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
