import SwiftUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var context
    @State private var urlText = ""
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Da sito web o social") {
                    TextField("Incolla un link…", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Button {
                        Task { await importFromURL() }
                    } label: {
                        if isImporting {
                            ProgressView()
                        } else {
                            Label("Importa da link", systemImage: "square.and.arrow.down")
                        }
                    }
                    .disabled(urlText.isEmpty || isImporting)
                }

                Section("Da fotocamera") {
                    Button {
                        // TODO: presentare VisionKit DataScanner per OCR (anche scrittura a mano).
                    } label: {
                        Label("Scansiona ricetta", systemImage: "camera")
                    }
                }

                Section {
                    Text("""
                    Puoi anche importare dai social usando il tasto **Condividi** \
                    dall'app (TikTok, Instagram, ecc.) tramite la Share Extension.
                    """)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Importa")
            .alert("Import non riuscito", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func importFromURL() async {
        isImporting = true
        defer { isImporting = false }
        do {
            let recipe = try await RecipeImporter.shared.importRecipe(from: urlText)
            context.insert(recipe)
            urlText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
