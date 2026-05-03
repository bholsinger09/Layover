import Foundation
import Observation

/// Service for managing language preferences and localization
@Observable
public final class LanguageService {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let languageStorageKey = "user_language_preference"
    
    public private(set) var currentLanguage: Language
    public private(set) var secondaryLanguages: [Language]
    public private(set) var autoTranslateEnabled: Bool
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Load saved preferences or use system default
        if let savedCode = userDefaults.string(forKey: languageStorageKey),
           let language = Language.from(code: savedCode) {
            self.currentLanguage = language
        } else {
            // Detect system language
            self.currentLanguage = Self.detectSystemLanguage()
        }
        
        self.secondaryLanguages = []
        self.autoTranslateEnabled = true
    }
    
    // MARK: - Public Methods
    
    /// Set the primary language
    public func setLanguage(_ language: Language) {
        currentLanguage = language
        userDefaults.set(language.code, forKey: languageStorageKey)
        
        // Update app locale
        updateAppLocale(language.code)
    }
    
    /// Add a secondary language
    public func addSecondaryLanguage(_ language: Language) {
        if !secondaryLanguages.contains(where: { $0.code == language.code }) {
            secondaryLanguages.append(language)
        }
    }
    
    /// Remove a secondary language
    public func removeSecondaryLanguage(_ language: Language) {
        secondaryLanguages.removeAll { $0.code == language.code }
    }
    
    /// Toggle auto-translate
    public func setAutoTranslate(_ enabled: Bool) {
        autoTranslateEnabled = enabled
    }
    
    /// Get localized string for key
    public func localized(_ key: String, language: Language? = nil) -> String {
        let targetLanguage = language ?? currentLanguage
        
        // In a real app, this would use NSLocalizedString with the appropriate bundle
        // For now, return the key
        return NSLocalizedString(key, tableName: targetLanguage.code, comment: "")
    }
    
    /// Translate text (would integrate with translation API)
    public func translate(_ text: String, to language: Language) async throws -> String {
        // TODO: Integrate with Apple's Translation framework or third-party API
        // For now, return original text
        return text
    }
    
    /// Get content recommendations based on language preferences
    public func recommendedContentLanguages() -> [String] {
        var languages = [currentLanguage.code]
        languages.append(contentsOf: secondaryLanguages.map { $0.code })
        return languages
    }
    
    /// Check if text direction is RTL
    public var isRTL: Bool {
        currentLanguage.isRTL
    }
    
    // MARK: - Private Methods
    
    private static func detectSystemLanguage() -> Language {
        let preferredLanguages = Locale.preferredLanguages
        
        for preferredLang in preferredLanguages {
            let code = String(preferredLang.prefix(2))
            if let language = Language.from(code: code) {
                return language
            }
        }
        
        return .english
    }
    
    private func updateAppLocale(_ languageCode: String) {
        // Update UserDefaults for app language
        userDefaults.set([languageCode], forKey: "AppleLanguages")
        userDefaults.synchronize()
    }
    
    // MARK: - Localization Keys
    
    /// Common localization keys used throughout the app
    public enum LocalizationKey {
        // Navigation
        public static let home = "navigation.home"
        public static let rooms = "navigation.rooms"
        public static let library = "navigation.library"
        public static let profile = "navigation.profile"
        
        // Rooms
        public static let createRoom = "room.create"
        public static let joinRoom = "room.join"
        public static let leaveRoom = "room.leave"
        public static let inviteFriends = "room.invite"
        
        // Activities
        public static let watchTogether = "activity.watch"
        public static let listenTogether = "activity.listen"
        public static let playGame = "activity.game"
        
        // Cultural Events
        public static let culturalEvents = "events.cultural"
        public static let upcoming = "events.upcoming"
        public static let live = "events.live"
        
        // Scheduling
        public static let schedule = "schedule.title"
        public static let scheduleHangout = "schedule.hangout"
        public static let setReminder = "schedule.reminder"
        
        // Time
        public static let now = "time.now"
        public static let today = "time.today"
        public static let tomorrow = "time.tomorrow"
        public static let thisWeek = "time.thisWeek"
        
        // Common
        public static let cancel = "common.cancel"
        public static let save = "common.save"
        public static let delete = "common.delete"
        public static let edit = "common.edit"
        public static let share = "common.share"
    }
}
