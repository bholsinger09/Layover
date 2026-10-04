import SwiftUI

// MARK: - Background Gradients (Reusable)

struct AppBackgroundGradient {
    // Dark library/content background (used in LibraryView, ProfileView, etc.)
    static var darkContent: LinearGradient {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Dark game background (used in ChessView, CheckersView, ConnectFourView, etc.)
    static var darkGame: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.95),
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.1, green: 0.15, blue: 0.25)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Light/neon accent background
    static var accentGame: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.8),
                Color(red: 0.2, green: 0.1, blue: 0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Music app gradient
    static var musicTheme: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.1, green: 0.05, blue: 0.15)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Language learning gradient
    static var learningTheme: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.05, green: 0.1, blue: 0.15)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Button Styles (Reusable)

struct PrimaryActionButton: ButtonStyle {
    var color: Color = .orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.5), radius: 8, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct DangerButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.gradient)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - View Modifiers (Reusable)

struct GameCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }
}

struct ContentCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct MusicCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.4), radius: 4)
    }
}

struct HeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

struct SubheaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 16)
    }
}

// MARK: - Extension Shortcuts

extension View {
    func gameCardStyle() -> some View {
        modifier(GameCardStyle())
    }

    func contentCardStyle() -> some View {
        modifier(ContentCardStyle())
    }

    func musicCardStyle() -> some View {
        modifier(MusicCardStyle())
    }

    func headerStyle() -> some View {
        modifier(HeaderStyle())
    }

    func subheaderStyle() -> some View {
        modifier(SubheaderStyle())
    }

    func primaryActionButton(_ color: Color = .orange) -> some View {
        buttonStyle(PrimaryActionButton(color: color))
    }

    func secondaryActionButton() -> some View {
        buttonStyle(SecondaryActionButton())
    }

    func dangerButton() -> some View {
        buttonStyle(DangerButton())
    }
}

// MARK: - Usage Examples

#Preview {
    VStack(spacing: 20) {
        Text("App Styles Preview")
            .headerStyle()

        VStack(spacing: 12) {
            Button("Primary Action") { }
                .buttonStyle(PrimaryActionButton(color: .orange))

            Button("Secondary Action") { }
                .buttonStyle(SecondaryActionButton())

            Button("Delete") { }
                .buttonStyle(DangerButton())
        }
        .padding()
        .gameCardStyle()
    }
    .padding()
    .background(AppBackgroundGradient.darkContent)
}
