import Foundation
import Combine
import SwiftUI

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case portuguese = "Português (Brasil)"

    var id: String { self.rawValue }

    var code: String {
        switch self {
        case .english: return "en"
        case .portuguese: return "pt-BR"
        }
    }
}

class LanguageSettings: ObservableObject {
    
    private let userDefaultsKey = "selectedLanguageCode"
    
    @Published var selectedLanguage: SupportedLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.code, forKey: userDefaultsKey)
            print("Language saved: \(selectedLanguage.code)")
        }
    }
    
    init() {
        if let savedCode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = SupportedLanguage.allCases.first(where: { $0.code == savedCode }) {
            self.selectedLanguage = language
        } else {
            if Locale.current.identifier.contains("pt") {
                self.selectedLanguage = .portuguese
            } else {
                self.selectedLanguage = .english
            }
        }
    }
}
