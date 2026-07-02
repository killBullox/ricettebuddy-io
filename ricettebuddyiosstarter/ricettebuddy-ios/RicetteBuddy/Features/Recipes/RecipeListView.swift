import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.updatedAt, order: .reverse) private var recipes: [Recipe]
    @State private var searchText = ""

    private var filtered: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "Nessuna ricetta",
                        systemImage: "book",
                        description: Text("Importa la tua prima ricetta dalla scheda Importa.")
                    )
                } else {
                    List {
                        ForEach(filtered) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeRow(recipe: recipe)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Ricette")
            .searchable(text: $searchText, prompt: "Cerca ricette")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addSample()
                    } label: {
                        Label("Aggiungi", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filtered[index])
        }
    }

    /// Placeholder: crea una ricetta di esempio. Da sostituire con l'editor.
    private func addSample() {
        let recipe = Recipe(title: "Nuova ricetta")
        context.insert(recipe)
    }
}

private struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(imageData: recipe.imageData)
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title).font(.headline)
                if let total = totalMinutes {
                    Label("\(total) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if recipe.isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
            }
        }
    }

    private var totalMinutes: Int? {
        let total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0)
        return total > 0 ? total : nil
    }
}

private struct RecipeThumbnail: View {
    let imageData: Data?

    var body: some View {
        Group {
            if let data = imageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "fork.knife")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
