//
//  UniqueFeatureConstants.swift
//  Social Sync Lounge
//
//  App-specific constants and unique identifiers
//

import Foundation

/// Unique feature constants for Social Sync Lounge
public enum AppFeatures {
    /// Unique app identifier
    public static let appIdentifier = "com.socialsynclounge.app"
    
    /// Unique app name
    public static let appName = "Social Sync Lounge"
    
    /// Unique taglines
    public static let primaryTagline = "Your Personal Social Entertainment Hub"
    public static let secondaryTagline = "Experience Entertainment Together"
    public static let tertiaryTagline = "Where Distance Disappears"
    
    /// Unique feature descriptions
    public static let syncTechnology = "Real-Time Sync Technology"
    public static let syncDescription = "Our proprietary synchronization engine ensures everyone experiences content at exactly the same moment"
    
    public static let socialHub = "Social Entertainment Hub"
    public static let socialDescription = "Curate, share, and enjoy your favorite media with friends and family"
    
    /// Unique room types with custom names
    public enum RoomTypes {
        public static let watchParty = "Watch Party Room"
        public static let listenTogether = "Listen Together Lounge"
        public static let gameNight = "Game Night Arena"
    }
    
    /// Unique feature highlights
    public static let uniqueFeatures = [
        "Real-time content synchronization",
        "Multi-platform seamless experience", 
        "Curated media library integration",
        "Advanced playback coordination",
        "Privacy-first group sessions"
    ]
    
    /// Version and copyright
    public static let version = "1.0"
    public static let copyright = "© 2025 Social Sync Lounge. All rights reserved."
}
