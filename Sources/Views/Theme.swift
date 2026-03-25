import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(hex: "1E1E2E")
    static let surface = Color(hex: "2A2A3E")
    static let surfaceLight = Color(hex: "363650")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0B8")

    // CPU ring colors
    static let cpuUser = Color(hex: "6C9EFF")
    static let cpuSystem = Color(hex: "FF9F6C")
    static let cpuIdle = Color(hex: "4A4A5E")

    // Status colors
    static let statusGreen = Color(hex: "4ADE80")
    static let statusAmber = Color(hex: "FBBF24")
    static let statusRed = Color(hex: "F87171")

    // Network
    static let networkUp = Color(hex: "4ADE80")
    static let networkDown = Color(hex: "60A5FA")

    // MARK: - Usage Color
    static func usageColor(for percentage: Double) -> Color {
        if percentage < 0.7 {
            return statusGreen
        } else if percentage < 0.9 {
            return statusAmber
        } else {
            return statusRed
        }
    }

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 6
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
