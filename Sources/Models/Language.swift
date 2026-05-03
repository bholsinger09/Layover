import Foundation

/// Represents a supported language in the app
public struct Language: LayoverModel {
    public let id: UUID
    public let code: String // ISO 639-1 code (e.g., "en", "es", "zh")
    public let name: String // Native name (e.g., "English", "Español", "中文")
    public let englishName: String
    public let isRTL: Bool // Right-to-left languages (Arabic, Hebrew)
    public let flag: String // Emoji flag
    
    public init(
        id: UUID = UUID(),
        code: String,
        name: String,
        englishName: String,
        isRTL: Bool = false,
        flag: String
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.englishName = englishName
        self.isRTL = isRTL
        self.flag = flag
    }
    
    // MARK: - Supported Languages
    
    public static let english = Language(
        code: "en",
        name: "English",
        englishName: "English",
        flag: "🇺🇸"
    )
    
    public static let spanish = Language(
        code: "es",
        name: "Español",
        englishName: "Spanish",
        flag: "🇪🇸"
    )
    
    public static let mandarin = Language(
        code: "zh",
        name: "中文",
        englishName: "Mandarin Chinese",
        flag: "🇨🇳"
    )
    
    public static let hindi = Language(
        code: "hi",
        name: "हिन्दी",
        englishName: "Hindi",
        flag: "🇮🇳"
    )
    
    public static let arabic = Language(
        code: "ar",
        name: "العربية",
        englishName: "Arabic",
        isRTL: true,
        flag: "🇸🇦"
    )
    
    public static let portuguese = Language(
        code: "pt",
        name: "Português",
        englishName: "Portuguese",
        flag: "🇧🇷"
    )
    
    public static let french = Language(
        code: "fr",
        name: "Français",
        englishName: "French",
        flag: "🇫🇷"
    )
    
    public static let german = Language(
        code: "de",
        name: "Deutsch",
        englishName: "German",
        flag: "🇩🇪"
    )
    
    public static let japanese = Language(
        code: "ja",
        name: "日本語",
        englishName: "Japanese",
        flag: "🇯🇵"
    )
    
    public static let korean = Language(
        code: "ko",
        name: "한국어",
        englishName: "Korean",
        flag: "🇰🇷"
    )
    
    public static let allSupported: [Language] = [
        .english,
        .spanish,
        .mandarin,
        .hindi,
        .arabic,
        .portuguese,
        .french,
        .german,
        .japanese,
        .korean
    ]
    
    public static func from(code: String) -> Language? {
        allSupported.first { $0.code == code }
    }
}

/// User's language preferences
public struct UserLanguagePreference: LayoverModel {
    public let id: UUID
    public let userId: UUID
    public let primaryLanguage: Language
    public let secondaryLanguages: [Language]
    public let autoTranslate: Bool
    public let showOriginalWithTranslation: Bool
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        primaryLanguage: Language,
        secondaryLanguages: [Language] = [],
        autoTranslate: Bool = true,
        showOriginalWithTranslation: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.primaryLanguage = primaryLanguage
        self.secondaryLanguages = secondaryLanguages
        self.autoTranslate = autoTranslate
        self.showOriginalWithTranslation = showOriginalWithTranslation
    }
}

/// Regional content preference
public struct RegionalPreference: LayoverModel {
    public let id: UUID
    public let userId: UUID
    public let region: String // ISO 3166-1 alpha-2 (e.g., "US", "BR", "IN")
    public let timezone: String // IANA timezone (e.g., "America/New_York")
    public let culturalInterests: [CulturalInterest]
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        region: String,
        timezone: String,
        culturalInterests: [CulturalInterest] = []
    ) {
        self.id = id
        self.userId = userId
        self.region = region
        self.timezone = timezone
        self.culturalInterests = culturalInterests
    }
}

/// Cultural interests for personalized content
public enum CulturalInterest: String, Codable, Sendable, CaseIterable {
    case kpop = "K-Pop"
    case anime = "Anime"
    case bollywood = "Bollywood"
    case football = "Football/Soccer"
    case cricket = "Cricket"
    case basketball = "Basketball"
    case esports = "Esports"
    case hollywood = "Hollywood"
    case latinMusic = "Latin Music"
    case jDrama = "Japanese Drama"
    case kDrama = "Korean Drama"
    case cDrama = "Chinese Drama"
    case worldCup = "World Cup"
    case olympics = "Olympics"
    case awards = "Award Shows"
    case festivals = "Cultural Festivals"
}
