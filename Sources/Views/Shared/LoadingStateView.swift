import SwiftUI

// MARK: - Loading State Enum

/// Represents the state of an async operation
public enum LoadingState<T> {
    case loading
    case empty
    case error(String)
    case success(T)
}

// MARK: - Loading State View

/// Generic view for handling loading, error, empty, and success states
/// Provides consistent UX across the app for content loading patterns
public struct LoadingStateView<Content: View>: View {
    let state: LoadingState<Void>
    let content: () -> Content
    let emptyMessage: String
    let onRetry: (() -> Void)?

    public init(
        state: LoadingState<Void>,
        emptyMessage: String = "No content available",
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.emptyMessage = emptyMessage
        self.onRetry = onRetry
        self.content = content
    }

    public var body: some View {
        switch state {
        case .loading:
            loadingView
        case .empty:
            emptyView
        case .error(let message):
            errorView(message: message)
        case .success:
            content()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2, anchor: .center)
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.displayP3, white: 0.95))
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(emptyMessage)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.displayP3, white: 0.95))
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.displayP3, white: 0.95))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LoadingStateView(state: .loading) {
        Text("Content")
    }
}
#endif
