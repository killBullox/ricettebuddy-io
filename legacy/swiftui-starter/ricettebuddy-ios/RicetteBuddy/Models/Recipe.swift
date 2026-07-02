import Foundation
import SwiftData

/// Tipo di fonte da cui è stata importata la ricetta.
enum RecipeSource: String, Codable, CaseIterable {
    case manual
    case web
    case social
    case photo
}

/// Slot del piano pasti giornaliero.
enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast   // colazione
    case lunch       // pranzo
    case snack       // spuntino
    case dinner      // cena

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .breakfast: return String(localized: "Colazione")
        case .lunch:     return String(localized: "Pranzo")
        case .snack:     return String(localized: "Spuntino")
        case .dinner:    return String(localized: "Cena")
        }
    }
}

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var imageData: Data?
    var sourceURL: String?
    var sourceRaw: String
    var originalLanguage: String?
    var prepMinutes: Int?
    var cookMinutes: Int?
    var servings: Int
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relazioni
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]

    @Relationship(deleteRule: .cascade, inverse: \Step.recipe)
    var steps: [Step]

    var source: RecipeSource {
        get { RecipeSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        imageData: Data? = nil,
        sourceURL: String? = nil,
        source: RecipeSource = .manual,
        originalLanguage: String? = nil,
        prepMinutes: Int? = nil,
        cookMinutes: Int? = nil,
        servings: Int = 2,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        ingredients: [Ingredient] = [],
        steps: [Step] = []
    ) {
        self.id = id
        self.title = title
        self.imageData = imageData
        self.sourceURL = sourceURL
        self.sourceRaw = source.rawValue
        self.originalLanguage = originalLanguage
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.servings = servings
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ingredients = ingredients
        self.steps = steps
    }
}
