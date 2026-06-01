import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct Palette {
    // Sfondi (Slate/Zinc scuro in Dark Mode, Bianco sporco in Light)
    static var mainBackground: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#18181B") : Color(hex: "#F4F4F5") }
    static var cardBackground: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#27272A") : Color(hex: "#FFFFFF") }
    
    // Testi (Contrasto > 4.5:1)
    static var primaryText: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#F8FAFC") : Color(hex: "#0F172A") }
    static var secondaryText: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#94A3B8") : Color(hex: "#64748B") }
    
    // Colori Funzionali e Accenti
    static var highlight: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#3F3F46") : Color(hex: "#E4E4E7") }
    
    // Accento Principale: Electric Indigo (Modern AI Vibe)
    static var growthAccent: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#6366F1") : Color(hex: "#4F46E5") } 
    
    // Altri Accenti
    static var statusTag: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#71717A") : Color(hex: "#A1A1AA") }
    static var avatarAccent: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#E2E8F0") : Color(hex: "#FFFFFF") }
    
    // Colori dei grafici e allarmi
    static var chartStart: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#312E81") : Color(hex: "#818CF8") }
    static var chartEnd: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#4F46E5") : Color(hex: "#4338CA") }
    static var chartCritical: Color { ThemeManager.shared.isDarkMode ? Color(hex: "#EF4444") : Color(hex: "#DC2626") }
}
