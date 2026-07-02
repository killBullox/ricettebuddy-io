import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem { Label("Ricette", systemImage: "book") }

            ImportView()
                .tabItem { Label("Importa", systemImage: "square.and.arrow.down") }

            MealPlanView()
                .tabItem { Label("Piano", systemImage: "calendar") }

            ShoppingListView()
                .tabItem { Label("Spesa", systemImage: "cart") }

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gear") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self, Step.self,
                              MealPlanEntry.self, ShoppingItem.self],
                        inMemory: true)
}
