import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ShoppingItem.name) private var items: [ShoppingItem]
    @State private var groupByAisle = true

    /// Voci raggruppate per corsia (categoria) o in un unico gruppo.
    private var sections: [(title: String, items: [ShoppingItem])] {
        guard groupByAisle else { return [(String(localized: "Tutti"), items)] }
        let grouped = Dictionary(grouping: items) { $0.aisleCategory ?? String(localized: "Varie") }
        return grouped.keys.sorted().map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Lista vuota",
                        systemImage: "cart",
                        description: Text("Aggiungi ricette al piano o usa il pulsante carrello in una ricetta.")
                    )
                } else {
                    List {
                        ForEach(sections, id: \.title) { section in
                            Section(section.title) {
                                ForEach(section.items) { item in
                                    Button {
                                        item.isChecked.toggle()
                                    } label: {
                                        ShoppingRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spesa")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Ordina", selection: $groupByAisle) {
                        Text("Per corsia").tag(true)
                        Text("In elenco").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}

private struct ShoppingRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        HStack {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isChecked ? .green : .secondary)
            Text(item.name)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? .secondary : .primary)
            Spacer()
            if let qty = item.quantity {
                Text(formatted(qty) + (item.unit.map { " \($0)" } ?? ""))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
