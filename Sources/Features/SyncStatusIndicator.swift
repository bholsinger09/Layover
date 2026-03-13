//
//  SyncStatusIndicator.swift
//  ShareALayover
//
//  Unique sync status visualization component
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Custom sync status indicator - unique to this app
public struct SyncStatusIndicator: View {
    let isConnected: Bool
    let participantCount: Int
    @State private var pulseAnimation = false
    
    public init(isConnected: Bool, participantCount: Int = 0) {
        self.isConnected = isConnected
        self.participantCount = participantCount
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Animated sync indicator
            ZStack {
                if isConnected {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: pulseAnimation ? 40 : 30, height: pulseAnimation ? 40 : 30)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                
                Circle()
                    .fill(isConnected ? Color.green : Color.gray)
                    .frame(width: 16, height: 16)
                
                if isConnected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isConnected ? "Sync Active" : "Not Synced")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isConnected ? .green : .gray)
                
                if isConnected && participantCount > 0 {
                    Text("\(participantCount) participant\(participantCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: isConnected ? .green.opacity(0.3) : .clear, radius: 8)
        )
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        Color(.systemBackground)
        #elseif os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(white: 0.15)
        #endif
    }
}

#Preview {
    VStack(spacing: 20) {
        SyncStatusIndicator(isConnected: true, participantCount: 3)
        SyncStatusIndicator(isConnected: false)
    }
    .padding()
    .background(Color.black)
}
