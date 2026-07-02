import Foundation
import SwiftData

@Model
final class ShoppingItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double?
    var unit: String?
    var aisleCategory: String?
    var isChecked: Bool
    /// Ricetta di origine (nil se voce aggiunta a mano).
    var sourceRecipeID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double? = nil,
        unit: String? = nil,
        aisleCategory: String? = nil,
        isChecked: Bool = false,
        sourceRecipeID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.aisleCategory = aisleCategory
        self.isChecked = isChecked
        self.sourceRecipeID = sourceRecipeID
    }
}
