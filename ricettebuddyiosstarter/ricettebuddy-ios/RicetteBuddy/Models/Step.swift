import Foundation
import SwiftData

@Model
final class Step {
    @Attribute(.unique) var id: UUID
    var order: Int
    var text: String

    var recipe: Recipe?

    init(id: UUID = UUID(), order: Int, text: String) {
        self.id = id
        self.order = order
        self.text = text
    }
}
