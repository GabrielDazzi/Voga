import Foundation
import Combine
import SwiftUI

// Enum para os idiomas que nosso app suporta
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case portuguese = "Português (Brasil)"

    var id: String { self.rawValue }

    // Código de localidade que o iOS entende
    var code: String {
        switch self {
        case .english: return "en"
        case .portuguese: return "pt-BR"
        }
    }
}

// Classe que gerencia e salva a escolha de idioma do usuário
class LanguageSettings: ObservableObject {
    
    private let userDefaultsKey = "selectedLanguageCode"
    
    @Published var selectedLanguage: SupportedLanguage {
        didSet {
            // Salva a nova escolha sempre que ela for alterada
            UserDefaults.standard.set(selectedLanguage.code, forKey: userDefaultsKey)
            print("Language saved: \(selectedLanguage.code)")
        }
    }
    
    init() {
        // Ao iniciar, tenta carregar a escolha salva.
        if let savedCode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = SupportedLanguage.allCases.first(where: { $0.code == savedCode }) {
            self.selectedLanguage = language
        } else {
            // Se for o primeiro acesso, detecta o idioma do sistema. Se não for pt-BR, usa inglês como padrão.
            if Locale.current.identifier.contains("pt") {
                self.selectedLanguage = .portuguese
            } else {
                self.selectedLanguage = .english
            }
        }
    }
}
