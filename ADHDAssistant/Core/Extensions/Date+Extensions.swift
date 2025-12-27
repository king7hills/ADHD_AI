//
//  Date+Extensions.swift
//  ADHDAssistant
//
//  Useful extensions for Date manipulation and formatting
//

import Foundation

extension Date {
    // MARK: - Date Boundaries

    /// Start of the current day (00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    /// Start of the current week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }

    /// End of the current week
    var endOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 7, to: startOfWeek)!.addingTimeInterval(-1)
    }

    /// Start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    /// End of the current month
    var endOfMonth: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfMonth)!
    }

    // MARK: - Date Comparisons

    /// Whether this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Whether this date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Whether this date is in the current week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Whether this date is in the current month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Whether this date is in the current year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// Whether this date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Whether this date is in the future
    var isFuture: Bool {
        self > Date()
    }

    /// Whether this date is a weekend
    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(self)
    }

    // MARK: - Date Calculations

    /// Days between this date and another date
    func daysBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay, to: otherDate.startOfDay)
        return components.day ?? 0
    }

    /// Weeks between this date and another date
    func weeksBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: self, to: otherDate)
        return components.weekOfYear ?? 0
    }

    /// Months between this date and another date
    func monthsBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self, to: otherDate)
        return components.month ?? 0
    }

    /// Add days to date
    func addDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// Add weeks to date
    func addWeeks(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }

    /// Add months to date
    func addMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self)!
    }

    /// Add hours to date
    func addHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }

    /// Add minutes to date
    func addMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    /// Subtract days from date
    func subtractDays(_ days: Int) -> Date {
        addDays(-days)
    }

    // MARK: - Time Formatting

    /// Human-readable "time ago" string (e.g., "5 minutes ago", "2 hours ago")
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Short time ago string (e.g., "5m ago", "2h ago")
    var shortTimeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Short time string (e.g., "2:30 PM")
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Short date string (e.g., "Jan 15")
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Medium date string (e.g., "Jan 15, 2024")
    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Full date and time string
    var fullDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Relative description (e.g., "Today at 2:30 PM", "Yesterday", "Jan 15")
    var relativeDescription: String {
        if isToday {
            return "Today at \(shortTimeString)"
        } else if isYesterday {
            return "Yesterday at \(shortTimeString)"
        } else if isTomorrow {
            return "Tomorrow at \(shortTimeString)"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: self)
        } else if isThisYear {
            return "\(shortDateString) at \(shortTimeString)"
        } else {
            return fullDateTimeString
        }
    }

    /// Compact relative description (shorter version)
    var compactRelativeDescription: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isTomorrow {
            return "Tomorrow"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            return shortDateString
        }
    }

    // MARK: - Date Components

    /// Hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// Minute component (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// Day component (1-31)
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Month component (1-12)
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// Year component
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Weekday component (1 = Sunday, 7 = Saturday)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// Weekday name (e.g., "Monday")
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// Short weekday name (e.g., "Mon")
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Month name (e.g., "January")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    /// Short month name (e.g., "Jan")
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }

    // MARK: - Utility Methods

    /// Set time components while keeping the date
    func settingTime(hour: Int, minute: Int, second: Int = 0) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)
    }

    /// Get time interval until this date
    var timeIntervalUntilNow: TimeInterval {
        timeIntervalSince(Date())
    }

    /// Format duration from this date to now
    var durationFromNow: String {
        let interval = abs(timeIntervalSinceNow)
        return TimeInterval.formatted(interval)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Format time interval as human-readable string
    static func formatted(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    /// Hours from time interval
    var hours: Double {
        self / 3600
    }

    /// Minutes from time interval
    var minutes: Double {
        self / 60
    }

    /// Days from time interval
    var days: Double {
        self / 86400
    }
}

// MARK: - Calendar Helpers

extension Calendar {
    /// Get date from time components (hour and minute)
    static func date(hour: Int, minute: Int) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    /// Get date from date components
    static func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }
}
