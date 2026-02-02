//
//  CustomBackgroundView.swift
//  Social Sync Lounge
//
//  Custom background component replacing generic stock images
//

import SwiftUI

/// Unique custom background gradient with animated elements
/// Replaces generic stock images with app-specific design
public struct CustomBackgroundView: View {
    @State private var animateGradient = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Multi-layer gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.08, green: 0.15, blue: 0.28),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Decorative overlay pattern
            GeometryReader { geometry in
                ZStack {
                    // Large ambient circles
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.1),
                                    Color.cyan.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: animateGradient ? -50 : -100, y: -150)
                        .animation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true), value: animateGradient)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.12),
                                    Color.blue.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .offset(
                            x: geometry.size.width * (animateGradient ? 0.75 : 0.65),
                            y: geometry.size.height * 0.3
                        )
                        .animation(.easeInOut(duration: 12.0).repeatForever(autoreverses: true), value: animateGradient)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.08),
                                    Color.purple.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 175
                            )
                        )
                        .frame(width: 350, height: 350)
                        .offset(
                            x: geometry.size.width * (animateGradient ? 0.25 : 0.15),
                            y: geometry.size.height * (animateGradient ? 0.75 : 0.85)
                        )
                        .animation(.easeInOut(duration: 14.0).repeatForever(autoreverses: true), value: animateGradient)
                    
                    // Subtle grid pattern overlay
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.01),
                                    Color.white.opacity(0.03),
                                    Color.white.opacity(0.01)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            GeometryReader { geo in
                                Path { path in
                                    let spacing: CGFloat = 50
                                    // Vertical lines
                                    for i in stride(from: 0, through: geo.size.width, by: spacing) {
                                        path.move(to: CGPoint(x: i, y: 0))
                                        path.addLine(to: CGPoint(x: i, y: geo.size.height))
                                    }
                                    // Horizontal lines
                                    for i in stride(from: 0, through: geo.size.height, by: spacing) {
                                        path.move(to: CGPoint(x: 0, y: i))
                                        path.addLine(to: CGPoint(x: geo.size.width, y: i))
                                    }
                                }
                                .stroke(Color.white.opacity(0.02), lineWidth: 0.5)
                            }
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animateGradient = true
        }
    }
}

#Preview {
    CustomBackgroundView()
}
