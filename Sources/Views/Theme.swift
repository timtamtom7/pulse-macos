import SwiftUI

enum Theme {
    // MARK: - macOS 26 Liquid Glass Colors
    static let glassBorder = Color.white.opacity(0.18)
    static let glassShadow = Color.black.opacity(0.2)

    // Background colors (content layer)
    static let background = Color(hex: "1E1E2E")
    static let surface = Color(hex: "2A2A3E")
    static let surfaceLight = Color(hex: "363650")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0B8")

    // CPU ring colors - Vibrant for glass effect
    static let cpuUser = Color(hex: "6C9EFF")
    static let cpuSystem = Color(hex: "FF9F6C")
    static let cpuIdle = Color(hex: "4A4A5E")

    // Status colors - Optimistic and clear
    static let statusGreen = Color(hex: "4ADE80")
    static let statusAmber = Color(hex: "FBBF24")
    static let statusRed = Color(hex: "F87171")

    // Network - Distinct and vibrant
    static let networkUp = Color(hex: "4ADE80")
    static let networkDown = Color(hex: "60A5FA")

    // Alert colors (using custom palette for consistency)
    static let alertInfo = Color(hex: "60A5FA")      // Blue
    static let alertWarning = Color(hex: "FBBF24")    // Amber
    static let alertCritical = Color(hex: "F87171")   // Red (matches statusRed)

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

    // MARK: - Spacing - Concentric layout system
    static let paddingMicro: CGFloat = 4
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32

    // MARK: - Typography - Consistent sizing
    static let fontSizeCaption: CGFloat = 10
    static let fontSizeLabel: CGFloat = 11
    static let fontSizeBody: CGFloat = 12
    static let fontSizeSubheadline: CGFloat = 13
    static let fontSizeHeadline: CGFloat = 14
    static let fontSizeTitle: CGFloat = 16
    static let fontSizeLarge: CGFloat = 18
    static let fontSizeIcon: CGFloat = 12
    static let fontSizeIconLarge: CGFloat = 14
    static let fontSizeChartAxis: CGFloat = 11

    // MARK: - Corner Radius - Concentric shapes
    static let cornerRadiusMicro: CGFloat = 4
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusCapsule: CGFloat = 999

    // MARK: - Shadows
    static let glassShadowRadius: CGFloat = 20
    static let glassShadowY: CGFloat = 8

    // MARK: - Layout
    static let tabViewWidth: CGFloat = 380
    static let tabViewHeight: CGFloat = 420
    static let sheetWidth: CGFloat = 350
    static let cpuRingSize: CGFloat = 64

    // MARK: - Animation
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.2)
}

// MARK: - Glass Card Style
struct GlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(reduceTransparency ? AnyShapeStyle(Theme.surface) : AnyShapeStyle(.ultraThinMaterial))
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(reduceTransparency ? Color.clear : Theme.glassBorder, lineWidth: 0.5)
            )
            .shadow(color: Theme.glassShadow.opacity(reduceTransparency ? 0.1 : 0.25), radius: reduceTransparency ? Theme.glassShadowRadius / 2 : Theme.glassShadowRadius, x: 0, y: Theme.glassShadowY / 2)
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    let isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.paddingMedium)
            .padding(.vertical, Theme.paddingSmall)
            .background(
                Capsule()
                    .fill(isProminent ? Color.accentColor.opacity(0.8) : Color.clear)
            )
            .background(
                Capsule()
                    .stroke(isProminent ? Color.clear : Theme.glassBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(Theme.easeInOutAnimation, value: configuration.isPressed)
    }
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

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius))
    }

    func solidCard(cornerRadius: CGFloat = Theme.cornerRadiusSmall) -> some View {
        self
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.glassBorder, lineWidth: 0.5)
            )
    }
}
