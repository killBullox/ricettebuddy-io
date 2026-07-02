import Foundation

/// Parser di base per i blocchi JSON-LD `schema.org/Recipe` presenti nella
/// maggior parte dei food blog. Estrae titolo, ingredienti e passaggi.
/// È volutamente minimale: l'estrazione robusta andrà spostata lato server.
enum JSONLDRecipeParser {

    static func parse(html: String, sourceURL: String) -> Recipe? {
        for jsonString in extractJSONLDBlocks(from: html) {
            guard let data = jsonString.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data),
                  let recipeDict = findRecipe(in: object) else { continue }
            return buildRecipe(from: recipeDict, sourceURL: sourceURL)
        }
        return nil
    }

    // MARK: - Estrazione blocchi <script type="application/ld+json">

    private static func extractJSONLDBlocks(from html: String) -> [String] {
        let pattern = "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // MARK: - Ricerca dell'oggetto Recipe (gestisce @graph e array)

    private static func findRecipe(in object: Any) -> [String: Any]? {
        if let dict = object as? [String: Any] {
            if isRecipe(dict) { return dict }
            if let graph = dict["@graph"] as? [Any] {
                for item in graph {
                    if let found = findRecipe(in: item) { return found }
                }
            }
        } else if let array = object as? [Any] {
            for item in array {
                if let found = findRecipe(in: item) { return found }
            }
        }
        return nil
    }

    private static func isRecipe(_ dict: [String: Any]) -> Bool {
        if let type = dict["@type"] as? String { return type == "Recipe" }
        if let types = dict["@type"] as? [String] { return types.contains("Recipe") }
        return false
    }

    // MARK: - Costruzione modello

    private static func buildRecipe(from dict: [String: Any], sourceURL: String) -> Recipe {
        let title = (dict["name"] as? String) ?? String(localized: "Ricetta importata")

        let ingredients = (dict["recipeIngredient"] as? [String] ?? [])
            .map { Ingredient(rawText: $0) }

        let steps = parseInstructions(dict["recipeInstructions"])

        return Recipe(
            title: title,
            sourceURL: sourceURL,
            source: .web,
            ingredients: ingredients,
            steps: steps
        )
    }

    private static func parseInstructions(_ value: Any?) -> [Step] {
        var texts: [String] = []
        if let string = value as? String {
            texts = [string]
        } else if let array = value as? [Any] {
            for item in array {
                if let s = item as? String {
                    texts.append(s)
                } else if let d = item as? [String: Any], let s = d["text"] as? String {
                    texts.append(s)
                }
            }
        }
        return texts.enumerated().map { Step(order: $0.offset, text: $0.element) }
    }
}
