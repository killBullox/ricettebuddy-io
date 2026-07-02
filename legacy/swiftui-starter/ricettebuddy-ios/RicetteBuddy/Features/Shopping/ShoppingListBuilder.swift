import Foundation
import SwiftData

/// Costruisce/aggiorna la lista della spesa a partire da ricette o piani pasti,
/// aggregando gli ingredienti con stessa unità e nome normalizzato.
enum ShoppingListBuilder {

    /// Aggiunge gli ingredienti di una ricetta alla lista della spesa.
    static func add(recipe: Recipe, to context: ModelContext) {
        for ingredient in recipe.ingredients {
            let name = ingredient.normalizedName ?? ingredient.rawText
            let item = ShoppingItem(
                name: name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                aisleCategory: ingredient.aisleCategory,
                sourceRecipeID: recipe.id
            )
            context.insert(item)
        }
        aggregate(in: context)
    }

    /// Fonde le voci con stesso nome+unità sommando le quantità.
    static func aggregate(in context: ModelContext) {
        guard let items = try? context.fetch(FetchDescriptor<ShoppingItem>()) else { return }

        var merged: [String: ShoppingItem] = [:]
        for item in items where !item.isChecked {
            let key = "\(item.name.lowercased())|\(item.unit ?? "")"
            if let existing = merged[key] {
                existing.quantity = (existing.quantity ?? 0) + (item.quantity ?? 0)
                context.delete(item)
            } else {
                merged[key] = item
            }
        }
    }
}
