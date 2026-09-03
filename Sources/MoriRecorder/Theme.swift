//
//  Theme.swift
//  TimeClip
//
//  Paleta de cores pastel com suporte a modo escuro
//

import SwiftUI

struct Theme {
    // Paleta Pastel - cores se mantêm iguais em ambos os modos
    static let lavender = Color(hex: "E8D5F2")
    static let mint = Color(hex: "B8E6D5")
    static let peach = Color(hex: "FFD5C2")
    static let babyBlue = Color(hex: "C2E5FF")
    static let rose = Color(hex: "FFD1DC")
    
    // Background adapta ao modo
    static func background(isDark: Bool) -> Color {
        isDark ? Color.black : Color(hex: "FFF9F5")
    }
    
    static func cardBackground(isDark: Bool) -> Color {
        isDark ? Color(white: 0.15) : Color.white
    }
    
    static func textPrimary(isDark: Bool) -> Color {
        isDark ? Color.white : Color.black
    }
    
    static func textSecondary(isDark: Bool) -> Color {
        isDark ? Color.gray : Color.gray
    }
}

// MARK: - Color Extension para Hex
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
            (a, r, g, b) = (255, 0, 0, 0)
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
