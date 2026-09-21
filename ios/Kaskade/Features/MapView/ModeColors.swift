import Foundation
import SwiftUI

enum ModeColors {
    static let table: [String: String] = [
        "foot":  "#1b7f79",
        "bike":  "#c86a1f",
        "car":   "#3b5fbf",
        "train": "#8a3ea8",
        "plane": "#b03a3a",
    ]
    static func hex(for mode: String?) -> String {
        guard let mode, let farbe = table[mode] else { return "#9aa0a6" }
        return farbe
    }

    static func color(for mode: String?) -> Color {
        Color(hex: hex(for: mode))
    }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var wert: UInt64 = 0
        Scanner(string: s).scanHexInt64(&wert)
        let r = Double((wert & 0xFF0000) >> 16) / 255
        let g = Double((wert & 0x00FF00) >> 8) / 255
        let b = Double(wert & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
