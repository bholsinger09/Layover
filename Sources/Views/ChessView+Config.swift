import SwiftUI

// MARK: - Chess UI Layout Constants

struct ChessUILayout {
    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 20
    static let componentSpacing: CGFloat = 20
    static let tightSpacing: CGFloat = 8
    static let elementSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 30
    static let sectionVerticalSpacing: CGFloat = 40

    // Sizing
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20
    static let colorCircleSize: CGFloat = 80
    static let colorCircleGlowSize: CGFloat = 100
    static let checkmarkIconSize: CGFloat = 40
    static let checkmarkCircleSize: CGFloat = 44
    static let buttonIconSize: CGFloat = 12
    static let capturedPieceSize: CGFloat = 24

    // Board
    static let boardSquareSpacing: CGFloat = 0
    
    // Typography sizes
    static let titleSize: CGFloat = 72
    static let header1Size: CGFloat = 32
    static let headerSize: CGFloat = 20
}

struct ChessUIStyle {
    // Opacity values
    static let primaryOpacity: Double = 0.95
    static let secondaryOpacity: Double = 0.85
    static let tertiaryOpacity: Double = 0.7
    static let highlightOpacity: Double = 0.8
    static let dimOpacity: Double = 0.3
    static let mediumOpacity: Double = 0.5
    static let lowOpacity: Double = 0.15
    static let shadowOpacity: Double = 0.8
    static let strikeOpacity: Double = 0.25
    static let glowOpacity: Double = 0.3

    // Fonts
    static let titleFont = Font.system(size: ChessUILayout.titleSize, weight: .bold)
    static let header1Font = Font.system(size: ChessUILayout.header1Size, weight: .bold)
    static let headerFont = Font.title
    static let subheaderFont = Font.title2
    static let regularFont = Font.body
    static let boldFont = Font.headline
    static let captionFont = Font.caption
    static let subCaptionFont = Font.caption2

    // Shadows
    static let shadowSmall = (color: Color.black.opacity(0.4), radius: 5.0, x: 0.0, y: 2.0)
    static let shadowMedium = (color: Color.black.opacity(0.5), radius: 8.0, x: 0.0, y: 4.0)
    static let shadowLarge = (color: Color.black.opacity(0.5), radius: 15.0, x: 0.0, y: 8.0)
    static let shadowDeep = (color: Color.black.opacity(0.8), radius: 5.0, x: 0.0, y: 2.0)

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
    
    static let purpleButtonGradient = LinearGradient(
        colors: [Color.purple.opacity(ChessUIStyle.primaryOpacity), Color.purple.opacity(ChessUIStyle.secondaryOpacity)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueButtonGradient = LinearGradient(
        colors: [Color.blue.opacity(ChessUIStyle.primaryOpacity), Color.blue.opacity(ChessUIStyle.secondaryOpacity)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let redButtonGradient = LinearGradient(
        colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Stroke styles
    static let primaryStrokeColor = Color.white
    static let primaryStrokeWidth: CGFloat = 3
    static let secondaryStrokeColor = Color.white.opacity(ChessUIStyle.strikeOpacity)
    static let secondaryStrokeWidth: CGFloat = 1

    // Colors - Chess pieces
    static let capturedPieceRedBackground = Color.red.opacity(0.9)
    static let whiteCheckColor = Color.white
    static let blackCheckColor = Color.black
    static let checkStateColor = Color.red
    static let winnersTextColor = Color.green
}
