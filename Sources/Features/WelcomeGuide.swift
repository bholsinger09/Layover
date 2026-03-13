//
//  WelcomeGuide.swift
//  ShareALayover
//
//  Unique onboarding guide with app-specific features
//

import SwiftUI

/// Custom welcome/onboarding guide specific to ShareALayover
public struct WelcomeGuide: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "wave.3.right.circle.fill",
            title: "Welcome to ShareALayover",
            description: "Your personal hub for synchronized social entertainment. Watch, listen, and play together no matter where you are.",
            color: .cyan
        ),
        WelcomePage(
            icon: "clock.arrow.2.circlepath",
            title: "Real-Time Synchronization",
            description: "Our advanced sync technology keeps everyone perfectly in sync. Every laugh, every beat, every moment - experienced together.",
            color: .blue
        ),
        WelcomePage(
            icon: "person.3.fill",
            title: "Built for Connection",
            description: "Create private rooms, invite friends, and enjoy your favorite content together. Distance doesn't matter anymore.",
            color: .purple
        ),
        WelcomePage(
            icon: "sparkles",
            title: "Privacy-First Design",
            description: "Secure, encrypted connections. Your data stays yours. Sign in with Apple for maximum privacy.",
            color: .green
        )
    ]
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    pages[currentPage].color.opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        WelcomePageView(page: page)
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page)
                #endif
                
                // Continue/Get Started button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        isPresented = false
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(pages[currentPage].color)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct WelcomePage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct WelcomePageView: View {
    let page: WelcomePage
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color.gradient)
            
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    WelcomeGuide(isPresented: .constant(true))
}
