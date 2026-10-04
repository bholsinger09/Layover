import SwiftUI

/// Reusable home screen button with consistent styling
struct HomeButtonView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: LinearGradient
    let shadowColor: Color
    let badge: String?
    let isLarge: Bool
    let action: () -> Void

    init(
        title: String,
        subtitle: String,
        icon: String,
        color: LinearGradient,
        shadowColor: Color,
        badge: String? = nil,
        isLarge: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.shadowColor = shadowColor
        self.badge = badge
        self.isLarge = isLarge
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isLarge ? 16 : 12) {
                iconView
                textView
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, isLarge ? 28 : 16)
            .padding(.horizontal, isLarge ? 40 : 20)
            .frame(maxWidth: isLarge ? 700 : .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: isLarge ? 20 : 16)
                        .fill(color)
                    RoundedRectangle(cornerRadius: isLarge ? 20 : 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: isLarge ? 2 : 1.5)
                }
                .shadow(color: shadowColor.opacity(0.6), radius: isLarge ? 25 : 15, x: 0, y: isLarge ? 12 : 8)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: isLarge ? 60 : 44, height: isLarge ? 60 : 44)
            Image(systemName: icon)
                .font(.system(size: isLarge ? 32 : 22))
                .foregroundStyle(.white)
        }
    }

    private var textView: some View {
        VStack(alignment: .leading, spacing: isLarge ? 4 : 2) {
            if let badge = badge {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: isLarge ? 32 : 18, weight: .bold))
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .cornerRadius(4)
                }
            } else {
                Text(title)
                    .font(.system(size: isLarge ? 32 : 18, weight: .bold))
            }
            Text(subtitle)
                .font(.system(size: isLarge ? 18 : 12))
                .opacity(0.9)
        }
    }
}

// MARK: - Preset Styles

extension HomeButtonView {
    static func cyanButton(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HomeButtonView(
            title: title,
            subtitle: subtitle,
            icon: "shareplay",
            color: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.1, green: 0.6, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            shadowColor: .cyan,
            action: action
        )
    }

    static func purpleButton(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HomeButtonView(
            title: title,
            subtitle: subtitle,
            icon: "books.vertical.fill",
            color: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.2, blue: 0.8),
                    Color(red: 0.7, green: 0.3, blue: 0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            shadowColor: .purple,
            action: action
        )
    }

    static func orangeButton(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HomeButtonView(
            title: title,
            subtitle: subtitle,
            icon: "gamecontroller.fill",
            color: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.5, blue: 0.1),
                    Color(red: 1.0, green: 0.6, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            shadowColor: .orange,
            action: action
        )
    }

    static func greenButton(
        title: String,
        subtitle: String,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        HomeButtonView(
            title: title,
            subtitle: subtitle,
            icon: "globe.americas.fill",
            color: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.6, blue: 0.4),
                    Color(red: 0.2, green: 0.7, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            shadowColor: .green,
            badge: badge,
            action: action
        )
    }

    static func magentaButton(
        title: String,
        subtitle: String,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        HomeButtonView(
            title: title,
            subtitle: subtitle,
            icon: "message.badge.waveform.fill",
            color: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.8, green: 0.2, blue: 0.5),
                    Color(red: 0.9, green: 0.3, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            shadowColor: .pink,
            badge: badge,
            action: action
        )
    }

    static func largeBlueButton(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HomeButtonView(
            title: title,
            subtitle: subtitle,
            icon: "gamecontroller.fill",
            color: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.1, green: 0.6, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            shadowColor: .cyan,
            isLarge: true,
            action: action
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        HomeButtonView.cyanButton(title: "SharePlay Session", subtitle: "Real-time synchronized experience") {}
        HomeButtonView.purpleButton(title: "My Media Library", subtitle: "Curated collection ready to share") {}
        HomeButtonView.orangeButton(title: "Play Games", subtitle: "Chess, Checkers & Connect Four") {}
        HomeButtonView.greenButton(title: "Global Features", subtitle: "Worldwide rooms, events & scheduling", badge: "NEW") {}
        HomeButtonView.magentaButton(title: "Language Exchange", subtitle: "Practice with real-time translation", badge: "NEW") {}
    }
    .padding()
    .background(Color.black)
}
