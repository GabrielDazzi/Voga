import Foundation
import Combine
import SwiftUI

enum ThemeColor: String, CaseIterable, Identifiable {
    case blue, green, orange, purple, white
    
    var id: String { self.rawValue }
    
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
        case .white:
            return .white
        }
    }
}

class ThemeSettings: ObservableObject {
    private let userDefaultsKey = "selectedThemeColor"
    
    @Published var accentColor: ThemeColor {
        didSet {
            UserDefaults.standard.set(accentColor.rawValue, forKey: userDefaultsKey)
        }
    }
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: userDefaultsKey),
           let theme = ThemeColor(rawValue: savedTheme) {
            self.accentColor = theme
        } else {
            self.accentColor = .blue
        }
    }
}
