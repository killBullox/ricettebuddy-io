import Foundation
import SwiftData

@Model
final class MealPlanEntry {
    @Attribute(.unique) var id: UUID
    /// Giorno del pasto (normalizzato a inizio giornata).
    var date: Date
    var slotRaw: String
    var servings: Int

    @Relationship var recipe: Recipe?

    var slot: MealSlot {
        get { MealSlot(rawValue: slotRaw) ?? .dinner }
        set { slotRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        slot: MealSlot,
        servings: Int = 2,
        recipe: Recipe? = nil
    ) {
        self.id = id
        self.date = date
        self.slotRaw = slot.rawValue
        self.servings = servings
        self.recipe = recipe
    }
}
