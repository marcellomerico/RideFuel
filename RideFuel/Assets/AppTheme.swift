//
//  AppTheme.swift
//  RideFuel
//
//  Created by Marcello Merico on 13.08.25.
//
import SwiftUI

// Farbpalette
enum AppTheme {
    static let bg = Color(hex: "BCCCE0") // Hellblau-grau als Hintergrund
    static let card = Color.white.opacity(0.9)
    static let accent = Color(hex: "A6D9F7") // hellblau als Akzent
    static let accentAlt = Color(hex: "F3DE8A") // Gelb als sekundärer Akzent
    static let text = Color(hex: "666A86") // Dunkles grau für Text
    static let subtext = Color(hex: "666A86").opacity(0.7)
    static let highlight = Color(hex: "F4BBD3") // rosa für Highlights
    static let cube = Color(hex: "E4C988") // sand für würfel
}

// HEX - Color
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// Einheitlicher Card-Look
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}
extension View {
    func card() -> some View { modifier(CardBackground()) }
}

// Primärer Button-Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12).padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
