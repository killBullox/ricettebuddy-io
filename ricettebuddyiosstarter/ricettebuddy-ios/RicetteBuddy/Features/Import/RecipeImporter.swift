import Foundation

enum ImportError: LocalizedError {
    case invalidURL
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .invalidURL:     return String(localized: "Link non valido.")
        case .notImplemented: return String(localized: "Import non ancora implementato.")
        }
    }
}

/// Punto di ingresso per l'import ricette.
///
/// Nella versione finale, l'estrazione robusta (parsing JSON-LD schema.org/Recipe,
/// fallback euristico, structuring AI dei video/foto, traduzione) dovrebbe avvenire
/// lato **server** per proteggere le API key e poter aggiornare i parser senza
/// rilasciare una nuova build. Qui è predisposto lo scheletro con un parser
/// JSON-LD di base come primo passo lato client.
final class RecipeImporter {
    static let shared = RecipeImporter()
    private init() {}

    func importRecipe(from urlString: String) async throws -> Recipe {
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            throw ImportError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(decoding: data, as: UTF8.self)

        if let recipe = JSONLDRecipeParser.parse(html: html, sourceURL: urlString) {
            return recipe
        }

        // Fallback: crea una bozza con il solo link, da completare a mano o via AI server-side.
        return Recipe(
            title: url.host ?? String(localized: "Ricetta importata"),
            sourceURL: urlString,
            source: .web
        )
    }
}
