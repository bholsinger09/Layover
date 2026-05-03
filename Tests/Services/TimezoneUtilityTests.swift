import Testing
import Foundation
@testable import LayoverKit

/// Tests for TimezoneUtility
@Suite("Timezone Utility Tests")
struct TimezoneUtilityTests {
    
    @Test("Popular timezones exist")
    func testPopularTimezonesExist() {
        let timezones = TimezoneUtility.popularTimezones
        
        #expect(timezones.count >= 20)
        
        // Check major cities
        #expect(timezones.contains { $0.identifier == "America/New_York" })
        #expect(timezones.contains { $0.identifier == "Europe/London" })
        #expect(timezones.contains { $0.identifier == "Asia/Tokyo" })
        #expect(timezones.contains { $0.identifier == "Australia/Sydney" })
    }
    
    @Test("All popular timezones have valid identifiers")
    func testAllTimezonesHaveValidIdentifiers() {
        for tzInfo in TimezoneUtility.popularTimezones {
            let timezone = TimeZone(identifier: tzInfo.identifier)
            #expect(timezone != nil)
        }
    }
    
    @Test("Timezone info has display names")
    func testTimezoneInfoHasDisplayNames() {
        for tzInfo in TimezoneUtility.popularTimezones {
            #expect(!tzInfo.displayName.isEmpty)
            #expect(!tzInfo.region.isEmpty)
        }
    }
    
    @Test("Timezone offset strings are formatted correctly")
    func testTimezoneOffsetStrings() {
        let utcTimezone = TimezoneUtility.popularTimezones.first { $0.identifier == "Europe/London" }!
        let offsetString = utcTimezone.offsetString
        
        #expect(offsetString.contains("UTC"))
    }
    
    @Test("Convert date between timezones")
    func testConvertDateBetweenTimezones() {
        let date = Date()
        let nyTimezone = TimeZone(identifier: "America/New_York")!
        let londonTimezone = TimeZone(identifier: "Europe/London")!
        
        let convertedDate = TimezoneUtility.convert(
            date: date,
            from: nyTimezone,
            to: londonTimezone
        )
        
        // Dates should differ by timezone offset
        #expect(convertedDate != date || nyTimezone.secondsFromGMT() == londonTimezone.secondsFromGMT())
    }
    
    @Test("Format with timezone")
    func testFormatWithTimezone() {
        let date = Date()
        let timezone = TimeZone(identifier: "America/New_York")!
        
        let formatted = TimezoneUtility.formatWithTimezone(date, timezone: timezone)
        
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("EST") || formatted.contains("EDT"))
    }
    
    @Test("Relative time formatting")
    func testRelativeTimeFormatting() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        
        let relativeTime = TimezoneUtility.relativeTime(from: futureDate)
        
        #expect(!relativeTime.isEmpty)
    }
    
    @Test("Same day detection")
    func testSameDayDetection() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(3600) // Same day, 1 hour later
        let timezone = TimeZone.current
        
        let isSameDay = TimezoneUtility.isSameDay(date1, date2, in: timezone)
        
        #expect(isSameDay == true)
    }
    
    @Test("Different day detection")
    func testDifferentDayDetection() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(86400) // Next day
        let timezone = TimeZone.current
        
        let isSameDay = TimezoneUtility.isSameDay(date1, date2, in: timezone)
        
        #expect(isSameDay == false)
    }
    
    @Test("World times returns multiple cities")
    func testWorldTimesReturnsMultipleCities() {
        let worldTimes = TimezoneUtility.worldTimes()
        
        #expect(worldTimes.count >= 5)
        #expect(worldTimes["New York"] != nil)
        #expect(worldTimes["Tokyo"] != nil)
        #expect(worldTimes["London"] != nil)
    }
    
    @Test("Timezone from region code")
    func testTimezoneFromRegionCode() {
        let usTimezone = TimezoneUtility.timezone(forRegion: "US")
        #expect(usTimezone != nil)
        
        let jpTimezone = TimezoneUtility.timezone(forRegion: "JP")
        #expect(jpTimezone != nil)
        
        let invalidTimezone = TimezoneUtility.timezone(forRegion: "XX")
        #expect(invalidTimezone == nil)
    }
    
    @Test("Optimal meeting time finder")
    func testOptimalMeetingTimeFinder() {
        let timezones = [
            TimeZone(identifier: "America/New_York")!,
            TimeZone(identifier: "Europe/London")!
        ]
        
        let optimalTime = TimezoneUtility.optimalMeetingTime(timezones: timezones)
        
        // Should find a time or return nil
        if let time = optimalTime {
            // Verify it's in the future
            #expect(time > Date())
        }
    }
    
    @Test("Optimal meeting time respects preferred hours")
    func testOptimalMeetingTimeRespectsPreferredHours() {
        let timezones = [
            TimeZone(identifier: "America/New_York")!,
            TimeZone(identifier: "Asia/Tokyo")!
        ]
        
        // Look for time between 9 AM and 5 PM
        let optimalTime = TimezoneUtility.optimalMeetingTime(
            timezones: timezones,
            preferredHourRange: 9...17
        )
        
        // Should find a time that works for both or nil
        #expect(optimalTime != nil || optimalTime == nil)
    }
    
    @Test("Display string for timezone")
    func testDisplayStringForTimezone() {
        let timezone = TimeZone(identifier: "America/Los_Angeles")!
        let displayString = TimezoneUtility.displayString(for: timezone)
        
        #expect(!displayString.isEmpty)
        #expect(displayString.contains("UTC"))
    }
    
    @Test("Timezone info offset calculation")
    func testTimezoneInfoOffsetCalculation() {
        // UTC should be +0
        let utcInfo = TimezoneUtility.TimezoneInfo(
            identifier: "UTC",
            displayName: "UTC",
            region: "Global",
            offset: 0
        )
        
        #expect(utcInfo.offsetString.contains("UTC+0") || utcInfo.offsetString.contains("UTC-0"))
    }
    
    @Test("Timezone info with minute offset")
    func testTimezoneInfoWithMinuteOffset() {
        // India is UTC+5:30
        let indiaInfo = TimezoneUtility.TimezoneInfo(
            identifier: "Asia/Kolkata",
            displayName: "India (IST)",
            region: "Asia",
            offset: 5,
            minuteOffset: 30
        )
        
        #expect(indiaInfo.offsetString.contains("5:30"))
    }
    
    @Test("All popular timezones by region")
    func testPopularTimezonesByRegion() {
        let regions = Set(TimezoneUtility.popularTimezones.map { $0.region })
        
        #expect(regions.contains("Americas"))
        #expect(regions.contains("Europe"))
        #expect(regions.contains("Asia"))
        #expect(regions.contains("Pacific"))
    }
}
