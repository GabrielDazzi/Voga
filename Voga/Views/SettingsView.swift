import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageSettings: LanguageSettings
    @EnvironmentObject var themeSettings: ThemeSettings
    
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
