import SwiftUI

struct VogaColor {
    static let accent = Color(red: 0.0, green: 0.47, blue: 0.95)
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.systemGray6)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [accent.opacity(0.9), accent]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
