import SwiftUI

@main
struct VogaApp: App {
    @StateObject private var languageSettings = LanguageSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageSettings)
                .environment(\.locale, .init(identifier: languageSettings.selectedLanguage.code))
        }
    }
}
