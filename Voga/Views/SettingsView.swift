import SwiftUI

struct SettingsView: View {
    // Acessa o nosso gerenciador de idioma que virá do "ambiente"
    @EnvironmentObject var languageSettings: LanguageSettings
    
    // Para fechar a tela modal (sheet)
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("language")) {
                    // O Picker mostra os idiomas e atualiza a escolha do usuário
                    Picker("select_language", selection: $languageSettings.selectedLanguage) {
                        ForEach(SupportedLanguage.allCases) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Text("language_change_notice")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageSettings())
}
