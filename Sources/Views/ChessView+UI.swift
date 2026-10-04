import SwiftUI

// MARK: - Chess UI Styling Constants

struct ChessUILayout {
    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let componentSpacing: CGFloat = 20
    static let sectionSpacing: CGFloat = 30
    static let tightSpacing: CGFloat = 8
    static let buttonSpacing: CGFloat = 12

    // Sizing
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 20
    static let colorCircleSize: CGFloat = 80
    static let colorCircleGlow: CGFloat = 100
}

struct ChessUIStyle {
    // Opacity values
    static let primaryOpacity: Double = 0.95
    static let secondaryOpacity: Double = 0.85
    static let tertiaryOpacity: Double = 0.3
    static let highlightOpacity: Double = 0.8
    static let strikeOpacity: Double = 0.25

    // Fonts
    static let titleFont = Font.system(size: 72, weight: .bold)
    static let headerFont = Font.title
    static let boldFont = Font.headline
    static let captionFont = Font.caption

    // Gradients
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.black.opacity(0.95),
            Color(red: 0.05, green: 0.1, blue: 0.2),
            Color(red: 0.1, green: 0.15, blue: 0.25)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let whiteCircleGradient = LinearGradient(
        colors: [Color.white, Color.white.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let blackCircleGradient = LinearGradient(
        colors: [Color.black, Color.black.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Colors
    static let shadowColor = Color.black
    static let textColor = Color.white
    static let accentColor = Color.orange
}
