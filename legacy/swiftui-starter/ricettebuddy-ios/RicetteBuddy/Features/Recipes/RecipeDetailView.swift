import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            if let data = recipe.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .listRowInsets(EdgeInsets())
            }

            Section {
                Stepper("Porzioni: \(recipe.servings)", value: $recipe.servings, in: 1...50)
            }

            Section("Ingredienti") {
                if recipe.ingredients.isEmpty {
                    Text("Nessun ingrediente").foregroundStyle(.secondary)
                } else {
                    ForEach(recipe.ingredients) { ingredient in
                        Text(ingredient.rawText)
                    }
                }
            }

            Section("Preparazione") {
                if recipe.steps.isEmpty {
                    Text("Nessun passaggio").foregroundStyle(.secondary)
                } else {
                    ForEach(recipe.steps.sorted { $0.order < $1.order }) { step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(step.order + 1).").bold()
                            Text(step.text)
                        }
                    }
                }
            }

            if let url = recipe.sourceURL, let link = URL(string: url) {
                Section("Fonte") {
                    Link(destination: link) {
                        Label(url, systemImage: "link")
                    }
                }
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    recipe.isFavorite.toggle()
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    ShoppingListBuilder.add(recipe: recipe, to: context)
                } label: {
                    Label("Aggiungi alla spesa", systemImage: "cart.badge.plus")
                }
            }
        }
    }
}
