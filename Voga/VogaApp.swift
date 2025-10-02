import SwiftUI

@main
struct VogaApp: App {
    @StateObject private var languageSettings = LanguageSettings()
    @StateObject private var themeSettings = ThemeSettings() // 1. Criar o gestor de temas

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageSettings)
                .environmentObject(themeSettings) // 2. Disponibilizá-lo para todas as views
                .environment(\.locale, .init(identifier: languageSettings.selectedLanguage.code))
                .tint(themeSettings.accentColor.colorValue) // 3. APLICAR A COR A TODA A APLICAÇÃO
        }
    }
}
