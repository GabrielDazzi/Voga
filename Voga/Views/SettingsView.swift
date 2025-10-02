import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageSettings: LanguageSettings
    @EnvironmentObject var themeSettings: ThemeSettings // 1. Aceder ao gestor de temas
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("language")) {
                    Picker("select_language", selection: $languageSettings.selectedLanguage) {
                        ForEach(SupportedLanguage.allCases) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 2. NOVA SECÇÃO PARA A COR DO TEMA
                Section(header: Text("appearance")) {
                    Picker("accent_color", selection: $themeSettings.accentColor) {
                        ForEach(ThemeColor.allCases) { color in
                            Text(LocalizedStringKey(color.rawValue.capitalized)).tag(color)
                        }
                    }
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
        .environmentObject(ThemeSettings())
}
