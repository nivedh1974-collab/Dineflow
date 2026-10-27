import SwiftUI

// MARK: - Color Tokens
extension Color {
    static let dfPrimary               = Color(hex: "#a93000")
    static let dfPrimaryContainer      = Color(hex: "#ff784d")
    static let dfPrimaryFixedDim       = Color(hex: "#ff5d26")
    static let dfOnPrimary             = Color(hex: "#ffefeb")
    static let dfPrimaryDim            = Color(hex: "#942900")

    static let dfSecondary             = Color(hex: "#4b5d70")
    static let dfSecondaryContainer    = Color(hex: "#ccdff6")
    static let dfOnSecondary           = Color(hex: "#ecf3ff")

    static let dfSurface               = Color(hex: "#f9f6f5")
    static let dfSurfaceLowest         = Color(hex: "#ffffff")
    static let dfSurfaceLow            = Color(hex: "#f3f0ef")
    static let dfSurfaceContainer      = Color(hex: "#eae7e7")
    static let dfSurfaceHigh           = Color(hex: "#e5e2e1")
    static let dfSurfaceHighest        = Color(hex: "#dfdcdc")
    static let dfSurfaceDim            = Color(hex: "#d6d4d3")

    static let dfOnSurface             = Color(hex: "#2f2e2e")
    static let dfOnSurfaceVariant      = Color(hex: "#5c5b5b")
    static let dfOutline               = Color(hex: "#787676")
    static let dfOutlineVariant        = Color(hex: "#afacac")

    static let dfError                 = Color(hex: "#b31b25")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.dfPrimary, Color.dfPrimaryContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
extension Font {
    // Plus Jakarta Sans (falls back to system rounded if not installed)
    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("PlusJakartaSans-\(jakartaWeightName(weight))", size: size)
    }
    static func jakartaItalic(_ size: CGFloat) -> Font {
        Font.custom("PlusJakartaSans-ExtraBoldItalic", size: size)
    }
    private static func jakartaWeightName(_ w: Font.Weight) -> String {
        switch w {
        case .bold:       return "Bold"
        case .heavy:      return "ExtraBold"
        case .semibold:   return "SemiBold"
        default:          return "Regular"
        }
    }

    // Manrope
    static func manrope(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Manrope-\(manropeWeightName(weight))", size: size)
    }
    private static func manropeWeightName(_ w: Font.Weight) -> String {
        switch w {
        case .bold:       return "Bold"
        case .heavy:      return "ExtraBold"
        case .semibold:   return "SemiBold"
        case .medium:     return "Medium"
        default:          return "Regular"
        }
    }

    // Semantic tokens
    static let dfDisplayLg   = jakarta(48, weight: .heavy)
    static let dfHeadlineLg  = jakarta(32, weight: .bold)
    static let dfHeadlineMd  = jakarta(24, weight: .bold)
    static let dfHeadlineSm  = jakarta(20, weight: .bold)
    static let dfBodyLg      = manrope(16)
    static let dfBodyMd      = manrope(14)
    static let dfLabelMd     = manrope(12, weight: .bold)
    static let dfLabelSm     = manrope(10, weight: .bold)
}

// MARK: - Spacing
enum Spacing {
    static let s2:  CGFloat = 4
    static let s3:  CGFloat = 8
    static let s4:  CGFloat = 12
    static let s5: CGFloat = 20
    static let s6:  CGFloat = 16
    static let s8:  CGFloat = 20
    static let s10: CGFloat = 24
    static let s12: CGFloat = 32
}

// MARK: - Corner Radius
enum Radius {
    static let sm:   CGFloat = 8
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Shadow Modifiers
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.dfOnSurface.opacity(0.06), radius: 24, x: 0, y: 6)
    }
    func heroShadow() -> some View {
        self.shadow(color: Color.dfOnSurface.opacity(0.08), radius: 32, x: 0, y: 12)
    }
    func primaryShadow() -> some View {
        self.shadow(color: Color.dfPrimary.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}
