import Foundation
import SwiftData

@Model
final class Ingredient {
    @Attribute(.unique) var id: UUID
    /// Testo così come importato, es. "200 g di farina 00".
    var rawText: String
    /// Quantità normalizzata (nil se non riconosciuta).
    var quantity: Double?
    /// Unità normalizzata, es. "g", "ml", "pz".
    var unit: String?
    /// Nome ingrediente normalizzato per aggregazione, es. "farina".
    var normalizedName: String?
    /// Categoria corsia supermercato per l'ordinamento della spesa.
    var aisleCategory: String?

    var recipe: Recipe?

    init(
        id: UUID = UUID(),
        rawText: String,
        quantity: Double? = nil,
        unit: String? = nil,
        normalizedName: String? = nil,
        aisleCategory: String? = nil
    ) {
        self.id = id
        self.rawText = rawText
        self.quantity = quantity
        self.unit = unit
        self.normalizedName = normalizedName
        self.aisleCategory = aisleCategory
    }
}
