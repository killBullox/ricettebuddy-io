import SwiftUI
import SwiftData

@main
struct RicetteBuddyApp: App {
    /// Container SwiftData condiviso. Abilitando CloudKit nel target
    /// (capability "iCloud → CloudKit") la sync multi-dispositivo è automatica.
    let container: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
            Step.self,
            MealPlanEntry.self,
            ShoppingItem.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Impossibile creare il ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
