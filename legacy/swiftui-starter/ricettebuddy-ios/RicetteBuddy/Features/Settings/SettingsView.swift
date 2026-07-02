import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredLanguage") private var preferredLanguage = "it"
    @AppStorage("measurementSystem") private var measurementSystem = "metric"

    private let languages = [
        ("it", "Italiano"), ("en", "English"), ("nl", "Nederlands"),
        ("fr", "Français"), ("de", "Deutsch"), ("es", "Español")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Lingua") {
                    Picker("Lingua preferita", selection: $preferredLanguage) {
                        ForEach(languages, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                }

                Section("Unità di misura") {
                    Picker("Sistema", selection: $measurementSystem) {
                        Text("Metrico (g, ml)").tag("metric")
                        Text("Imperiale (oz, cup)").tag("imperial")
                    }
                }

                Section("Account & Sync") {
                    Label("Sincronizzazione iCloud attiva", systemImage: "checkmark.icloud")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("RicetteBuddy · versione 0.1 (scheletro)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}
