import SwiftUI

@main
struct VogaApp: App {
    @StateObject private var languageSettings = LanguageSettings()
    @StateObject private var themeSettings = ThemeSettings()
    @State private var isSplashScreenActive = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashScreenActive {
                    SplashScreenView(isActive: $isSplashScreenActive)
                        .environmentObject(themeSettings)
                } else {
                    ContentView()
                        .environmentObject(languageSettings)
                        .environmentObject(themeSettings)
                        .environment(\.locale, .init(identifier: languageSettings.selectedLanguage.code))
                        .tint(themeSettings.accentColor.colorValue)
                }
            }
        }
    }
}
