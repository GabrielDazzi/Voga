import SwiftUI

@main
struct VogaApp: App {
    @StateObject private var languageSettings = LanguageSettings()
    @State private var isSplashScreenActive = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashScreenActive {
                    SplashScreenView(isActive: $isSplashScreenActive)
                } else {
                    ContentView()
                        .environmentObject(languageSettings)
                        .environment(\.locale, .init(identifier: languageSettings.selectedLanguage.code))
                        .tint(VogaColor.accent)
                }
            }
        }
    }
}
