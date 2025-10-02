import Foundation
import Combine // <-- A CORREÇÃO ESTÁ AQUI. ESTA LINHA RESOLVE O ERRO.
import SwiftUI

// Enum para as opções de cor que o utilizador pode escolher
enum ThemeColor: String, CaseIterable, Identifiable {
    case blue, green, orange, purple
    
    var id: String { self.rawValue }
    
    // Converte o nosso enum para uma cor real do SwiftUI
    var colorValue: Color {
        switch self {
        case .blue:
            return .blue
        case .green:
            return .green
        case .orange:
            return .orange
        case .purple:
            return .purple
        }
    }
}

// Classe que gere e guarda a escolha de tema do utilizador
class ThemeSettings: ObservableObject {
    private let userDefaultsKey = "selectedThemeColor"
    
    @Published var accentColor: ThemeColor {
        didSet {
            // Guarda a nova escolha sempre que ela for alterada
            UserDefaults.standard.set(accentColor.rawValue, forKey: userDefaultsKey)
        }
    }
    
    init() {
        // Ao iniciar, tenta carregar a escolha guardada. Se não encontrar, usa azul como padrão.
        if let savedTheme = UserDefaults.standard.string(forKey: userDefaultsKey),
           let theme = ThemeColor(rawValue: savedTheme) {
            self.accentColor = theme
        } else {
            self.accentColor = .blue
        }
    }
}
