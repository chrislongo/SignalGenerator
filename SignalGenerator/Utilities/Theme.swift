import SwiftUI

enum Theme {
    // MARK: - Chassis
    static let body         = Color(hex: "#2a2a2c")
    static let bodyLight    = Color(hex: "#383838")
    static let bodyLighter  = Color(hex: "#484848")
    static let bodyDark     = Color(hex: "#1a1a1c")
    static let bodyDarkest  = Color(hex: "#101012")
    static let groove       = Color(hex: "#141416")

    // MARK: - Accent
    static let teal         = Color(hex: "#38a8a0")
    static let tealDark     = Color(hex: "#288880")
    static let red          = Color(hex: "#d03828")
    static let redDark      = Color(hex: "#a02818")

    // MARK: - Display
    static let amber        = Color(hex: "#f0982c")
    static let amberDim     = Color(hex: "#f0982c").opacity(0.4)
    static let crtTeal      = Color(hex: "#48c8d8")
    static let crtBG        = Color(hex: "#080c06")

    // MARK: - Buttons
    static let buttonFace   = Color(hex: "#484848")
    static let buttonActive = Color(hex: "#d8d0c8")
    static let buttonShadow = Color(hex: "#1a1a1c")

    // MARK: - Text
    static let textCream    = Color(hex: "#b8b4a8")
    static let textDim      = Color(hex: "#6e6e68")
    static let textFaint    = Color(hex: "#7a7872")
    static let textDark     = Color(hex: "#101012")

    // MARK: - Typography
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("SpaceMono-Regular", size: size)
            .weight(weight)
    }

    static func monoBold(_ size: CGFloat) -> Font {
        Font.custom("SpaceMono-Bold", size: size)
    }

    static func display(_ size: CGFloat) -> Font {
        Font.custom("Anybody-Bold", size: size)
    }

    static func displayHeavy(_ size: CGFloat) -> Font {
        Font.custom("Anybody-ExtraBold", size: size)
    }
}

// MARK: - Hex color initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >>  8) & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
