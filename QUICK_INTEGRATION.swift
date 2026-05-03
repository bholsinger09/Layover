// Quick Integration Example for ContentView.swift
// Copy this into your ContentView to enable Global Features

// 1. Add this import at the top (if not already there)
import SwiftUI
import LayoverKit

// 2. Add this @State variable to ContentView struct
@State var showingGlobalFeatures = false

// 3. Add this button to your home screen content
// (Place it alongside your existing buttons like Library, Profile, etc.)

Button {
    showingGlobalFeatures = true
} label: {
    VStack(spacing: 12) {
        Image(systemName: "globe.americas.fill")
            .font(.system(size: 48))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        
        Text("Global Features")
            .font(.headline)
            .foregroundStyle(.white)
        
        Text("New!")
            .font(.caption)
            .foregroundStyle(.yellow)
    }
    .frame(width: 180, height: 160)
    .background(.ultraThinMaterial)
    .cornerRadius(12)
}
.buttonStyle(.plain)

// 4. Add this sheet modifier to your NavigationStack or main view
.sheet(isPresented: $showingGlobalFeatures) {
    GlobalFeaturesHubView(currentUser: currentUser)
}

// ALTERNATIVE: Quick Test - Replace entire ContentView body temporarily

var body: some View {
    // For quick testing, replace your entire body with this:
    GlobalFeaturesHubView(
        currentUser: User(username: "TestUser", email: "test@example.com")
    )
}

// Then build and run to immediately see all global features!
