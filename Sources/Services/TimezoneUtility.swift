import Foundation

/// Utilities for timezone handling and conversions
public struct TimezoneUtility {
    
    /// Common timezone regions
    public static let popularTimezones: [TimezoneInfo] = [
        // Americas
        TimezoneInfo(identifier: "America/New_York", displayName: "New York (EST/EDT)", region: "Americas", offset: -5),
        TimezoneInfo(identifier: "America/Los_Angeles", displayName: "Los Angeles (PST/PDT)", region: "Americas", offset: -8),
        TimezoneInfo(identifier: "America/Chicago", displayName: "Chicago (CST/CDT)", region: "Americas", offset: -6),
        TimezoneInfo(identifier: "America/Denver", displayName: "Denver (MST/MDT)", region: "Americas", offset: -7),
        TimezoneInfo(identifier: "America/Sao_Paulo", displayName: "São Paulo (BRT)", region: "Americas", offset: -3),
        TimezoneInfo(identifier: "America/Mexico_City", displayName: "Mexico City (CST)", region: "Americas", offset: -6),
        TimezoneInfo(identifier: "America/Argentina/Buenos_Aires", displayName: "Buenos Aires (ART)", region: "Americas", offset: -3),
        
        // Europe
        TimezoneInfo(identifier: "Europe/London", displayName: "London (GMT/BST)", region: "Europe", offset: 0),
        TimezoneInfo(identifier: "Europe/Paris", displayName: "Paris (CET/CEST)", region: "Europe", offset: 1),
        TimezoneInfo(identifier: "Europe/Berlin", displayName: "Berlin (CET/CEST)", region: "Europe", offset: 1),
        TimezoneInfo(identifier: "Europe/Moscow", displayName: "Moscow (MSK)", region: "Europe", offset: 3),
        TimezoneInfo(identifier: "Europe/Istanbul", displayName: "Istanbul (TRT)", region: "Europe", offset: 3),
        
        // Asia
        TimezoneInfo(identifier: "Asia/Dubai", displayName: "Dubai (GST)", region: "Asia", offset: 4),
        TimezoneInfo(identifier: "Asia/Kolkata", displayName: "Mumbai/Delhi (IST)", region: "Asia", offset: 5, minuteOffset: 30),
        TimezoneInfo(identifier: "Asia/Shanghai", displayName: "Beijing/Shanghai (CST)", region: "Asia", offset: 8),
        TimezoneInfo(identifier: "Asia/Tokyo", displayName: "Tokyo (JST)", region: "Asia", offset: 9),
        TimezoneInfo(identifier: "Asia/Seoul", displayName: "Seoul (KST)", region: "Asia", offset: 9),
        TimezoneInfo(identifier: "Asia/Singapore", displayName: "Singapore (SGT)", region: "Asia", offset: 8),
        TimezoneInfo(identifier: "Asia/Hong_Kong", displayName: "Hong Kong (HKT)", region: "Asia", offset: 8),
        TimezoneInfo(identifier: "Asia/Bangkok", displayName: "Bangkok (ICT)", region: "Asia", offset: 7),
        
        // Pacific
        TimezoneInfo(identifier: "Australia/Sydney", displayName: "Sydney (AEDT/AEST)", region: "Pacific", offset: 10),
        TimezoneInfo(identifier: "Pacific/Auckland", displayName: "Auckland (NZDT/NZST)", region: "Pacific", offset: 12),
        
        // Africa
        TimezoneInfo(identifier: "Africa/Cairo", displayName: "Cairo (EET)", region: "Africa", offset: 2),
        TimezoneInfo(identifier: "Africa/Johannesburg", displayName: "Johannesburg (SAST)", region: "Africa", offset: 2),
        TimezoneInfo(identifier: "Africa/Lagos", displayName: "Lagos (WAT)", region: "Africa", offset: 1),
    ]
    
    public struct TimezoneInfo: Identifiable, Hashable, Sendable {
        public let id = UUID()
        public let identifier: String
        public let displayName: String
        public let region: String
        public let offset: Int // Hours from UTC
        public let minuteOffset: Int // Additional minutes
        
        public init(identifier: String, displayName: String, region: String, offset: Int, minuteOffset: Int = 0) {
            self.identifier = identifier
            self.displayName = displayName
            self.region = region
            self.offset = offset
            self.minuteOffset = minuteOffset
        }
        
        public var timezone: TimeZone {
            TimeZone(identifier: identifier) ?? .current
        }
        
        public var offsetString: String {
            let totalMinutes = offset * 60 + minuteOffset
            let hours = abs(totalMinutes / 60)
            let minutes = abs(totalMinutes % 60)
            let sign = totalMinutes >= 0 ? "+" : "-"
            
            if minutes == 0 {
                return "UTC\(sign)\(hours)"
            } else {
                return "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
            }
        }
    }
    
    /// Convert a date from one timezone to another
    public static func convert(date: Date, from sourceTimezone: TimeZone, to targetTimezone: TimeZone) -> Date {
        let sourceOffset = sourceTimezone.secondsFromGMT(for: date)
        let targetOffset = targetTimezone.secondsFromGMT(for: date)
        let offset = targetOffset - sourceOffset
        return date.addingTimeInterval(TimeInterval(offset))
    }
    
    /// Get formatted time string with timezone
    public static func formatWithTimezone(_ date: Date, timezone: TimeZone, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateStyle = .none
        formatter.timeStyle = style
        
        let timeString = formatter.string(from: date)
        let abbreviation = timezone.abbreviation(for: date) ?? ""
        
        return "\(timeString) \(abbreviation)"
    }
    
    /// Get relative time string (e.g., "in 5 minutes", "2 hours ago")
    public static func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Check if two dates are on the same day in a given timezone
    public static func isSameDay(_ date1: Date, _ date2: Date, in timezone: TimeZone) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Get current time in multiple timezones
    public static func worldTimes(for date: Date = Date()) -> [String: String] {
        var times: [String: String] = [:]
        
        let majorCities = [
            "New York": "America/New_York",
            "Los Angeles": "America/Los_Angeles",
            "London": "Europe/London",
            "Paris": "Europe/Paris",
            "Dubai": "Asia/Dubai",
            "Mumbai": "Asia/Kolkata",
            "Tokyo": "Asia/Tokyo",
            "Sydney": "Australia/Sydney"
        ]
        
        for (city, identifier) in majorCities {
            if let timezone = TimeZone(identifier: identifier) {
                times[city] = formatWithTimezone(date, timezone: timezone)
            }
        }
        
        return times
    }
    
    /// Get timezone from region code
    public static func timezone(forRegion region: String) -> TimeZone? {
        let regionMapping: [String: String] = [
            "US": "America/New_York",
            "CA": "America/Toronto",
            "MX": "America/Mexico_City",
            "BR": "America/Sao_Paulo",
            "AR": "America/Argentina/Buenos_Aires",
            "GB": "Europe/London",
            "FR": "Europe/Paris",
            "DE": "Europe/Berlin",
            "ES": "Europe/Madrid",
            "IT": "Europe/Rome",
            "RU": "Europe/Moscow",
            "TR": "Europe/Istanbul",
            "AE": "Asia/Dubai",
            "SA": "Asia/Riyadh",
            "IN": "Asia/Kolkata",
            "CN": "Asia/Shanghai",
            "JP": "Asia/Tokyo",
            "KR": "Asia/Seoul",
            "SG": "Asia/Singapore",
            "HK": "Asia/Hong_Kong",
            "AU": "Australia/Sydney",
            "NZ": "Pacific/Auckland",
            "EG": "Africa/Cairo",
            "ZA": "Africa/Johannesburg"
        ]
        
        guard let identifier = regionMapping[region.uppercased()] else {
            return nil
        }
        
        return TimeZone(identifier: identifier)
    }
    
    /// Calculate optimal meeting time for multiple timezones
    public static func optimalMeetingTime(
        timezones: [TimeZone],
        preferredHourRange: ClosedRange<Int> = 9...21
    ) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Try each hour in the next 7 days
        for day in 0..<7 {
            for hour in 0..<24 {
                guard let testDate = calendar.date(
                    byAdding: .hour,
                    value: day * 24 + hour,
                    to: calendar.startOfDay(for: now)
                ) else { continue }
                
                // Check if this time falls within preferred range for all timezones
                let allGood = timezones.allSatisfy { timezone in
                    var cal = calendar
                    cal.timeZone = timezone
                    let localHour = cal.component(.hour, from: testDate)
                    return preferredHourRange.contains(localHour)
                }
                
                if allGood {
                    return testDate
                }
            }
        }
        
        return nil
    }
    
    /// Get user-friendly timezone display
    public static func displayString(for timezone: TimeZone, at date: Date = Date()) -> String {
        let abbreviation = timezone.abbreviation(for: date) ?? ""
        let offset = timezone.secondsFromGMT(for: date) / 3600
        let sign = offset >= 0 ? "+" : ""
        return "\(abbreviation) (UTC\(sign)\(offset))"
    }
}
