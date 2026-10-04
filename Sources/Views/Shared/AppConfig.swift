import SwiftUI

// MARK: - App Configuration

/// Centralized app-wide configuration values
/// Single source of truth for sizing, colors, timings, and other constants
/// Benefits:
/// - Consistent spacing and sizing across app
/// - Easy theme adjustments (change once, affects everywhere)
/// - No magic numbers scattered throughout code
/// - Supports app-wide design changes easily
public struct AppConfig {
    // MARK: - Sizes

    public struct Sizes {
        /// Standard corner radius for buttons, cards, sheets
        public static let cornerRadius: CGFloat = 12

        /// Small corner radius for minor elements
        public static let smallCornerRadius: CGFloat = 6

        /// Large corner radius for full-screen presentations
        public static let largeCornerRadius: CGFloat = 20

        /// Standard button height
        public static let buttonHeight: CGFloat = 44

        /// Small button height
        public static let smallButtonHeight: CGFloat = 36

        /// Standard padding (edges, between sections)
        public static let standardPadding: CGFloat = 16

        /// Half standard padding
        public static let halfPadding: CGFloat = 8

        /// Double standard padding
        public static let doublePadding: CGFloat = 32

        /// Standard shadow radius
        public static let shadowRadius: CGFloat = 8

        /// Subtle shadow radius (for slight elevation)
        public static let subtleShadowRadius: CGFloat = 4

        /// Header height
        public static let headerHeight: CGFloat = 56

        /// Navigation bar height
        public static let navigationBarHeight: CGFloat = 44

        /// Icon size (small icons like close, menu)
        public static let iconSize: CGFloat = 24

        /// Large icon size
        public static let largeIconSize: CGFloat = 32

        /// Card height (for list items)
        public static let cardHeight: CGFloat = 100
    }

    // MARK: - Colors

    public struct Colors {
        /// Primary accent color (brand color, interactive elements)
        public static let primaryAccent = Color.orange

        /// Danger/destructive action color
        public static let danger = Color.red

        /// Success color (confirmations, completions)
        public static let success = Color.green

        /// Warning color
        public static let warning = Color.yellow

        /// Neutral text color (secondary content)
        public static let neutralText = Color.white.opacity(0.7)

        /// Subtle text color (tertiary content, disabled)
        public static let subtleText = Color.white.opacity(0.5)

        /// Background overlay (semi-transparent dark)
        public static let overlayBackground = Color.black.opacity(0.4)

        /// Card background
        public static let cardBackground = Color(.displayP3, white: 0.94)

        /// Input field background
        public static let inputBackground = Color(.displayP3, white: 0.91)
    }

    // MARK: - Durations

    public struct Durations {
        /// Short animations (micro-interactions)
        public static let shortAnimation: TimeInterval = 0.15

        /// Standard animation duration
        public static let standardAnimation: TimeInterval = 0.3

        /// Long animation duration
        public static let longAnimation: TimeInterval = 0.5

        /// Extra long animation
        public static let extraLongAnimation: TimeInterval = 0.8

        /// Very quick animations (loading spinners, transitions)
        public static let quickAnimation: TimeInterval = 0.1

        /// Default transition duration
        public static let defaultTransition: TimeInterval = 0.2

        /// Haptic feedback delay
        public static let hapticDelay: TimeInterval = 0.05

        /// Toast notification duration
        public static let toastDuration: TimeInterval = 3.0

        /// Sheet dismissal delay
        public static let sheetDismissalDelay: TimeInterval = 0.3
    }

    // MARK: - Spacing

    public struct Spacing {
        /// Vertical spacing between sections
        public static let verticalSection: CGFloat = 20

        /// Vertical spacing between items
        public static let verticalItem: CGFloat = 12

        /// Horizontal spacing between items
        public static let horizontalItem: CGFloat = 12

        /// Horizontal spacing between UI elements
        public static let horizontalElement: CGFloat = 8
    }

    // MARK: - Shadow

    public struct Shadow {
        /// Standard shadow (cards, buttons)
        public static var standard: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(0.1), 8, 0, 2)
        }

        /// Subtle shadow (slight elevation)
        public static var subtle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(0.05), 4, 0, 1)
        }

        /// Elevated shadow (floating elements)
        public static var elevated: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(0.15), 12, 0, 4)
        }
    }

    // MARK: - Typography

    public struct Typography {
        public static let headlineFont = Font.headline
        public static let titleFont = Font.title2
        public static let bodyFont = Font.body
        public static let captionFont = Font.caption
        public static let footnoteFont = Font.footnote
    }

    // MARK: - Animations

    public struct Animations {
        /// Standard spring animation
        public static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)

        /// Quick spring for snappy feel
        public static let quickSpring = Animation.spring(response: 0.2, dampingFraction: 0.6)

        /// Ease in out for smooth transitions
        public static let easeInOut = Animation.easeInOut(duration: Durations.standardAnimation)

        /// Linear animation (no easing)
        public static let linear = Animation.linear(duration: Durations.standardAnimation)
    }
}

// MARK: - Theme Support (Future)

/// This structure can be extended to support multiple themes
/// Example:
/// enum AppTheme {
///     case light
///     case dark
///     case custom(CustomTheme)
/// }

extension AppConfig {
    /// Check if we're in a compact layout (e.g., iPhone in portrait)
    public static func isCompactLayout(_ sizeCategory: ContentSizeCategory) -> Bool {
        sizeCategory <= .large
    }
}

// MARK: - Usage Helpers

extension View {
    /// Apply standard padding to a view
    public func standardPadding() -> some View {
        padding(AppConfig.Sizes.standardPadding)
    }

    /// Apply standard corner radius to a view
    public func standardCorner() -> some View {
        clipShape(RoundedRectangle(cornerRadius: AppConfig.Sizes.cornerRadius))
    }

    /// Apply standard shadow to a view
    public func standardShadow() -> some View {
        shadow(
            color: AppConfig.Shadow.standard.color,
            radius: AppConfig.Shadow.standard.radius,
            x: AppConfig.Shadow.standard.x,
            y: AppConfig.Shadow.standard.y
        )
    }

    /// Apply standard card styling (corner + shadow)
    public func cardStyle() -> some View {
        standardCorner()
            .standardShadow()
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: AppConfig.Sizes.standardPadding) {
        Text("AppConfig Example")
            .font(.headline)
        Text("Corner Radius: \(AppConfig.Sizes.cornerRadius)")
            .font(.caption)
        Text("Standard Padding: \(AppConfig.Sizes.standardPadding)")
            .font(.caption)
    }
    .standardPadding()
    .cardStyle()
}
#endif
