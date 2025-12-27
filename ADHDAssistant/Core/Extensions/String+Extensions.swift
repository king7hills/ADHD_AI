//
//  String+Extensions.swift
//  ADHDAssistant
//
//  Useful extensions for String manipulation and validation
//

import Foundation

extension String {
    // MARK: - Validation

    /// Check if string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    /// Check if string is not empty (ignoring whitespace)
    var isNotEmpty: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if string contains only digits
    var isNumeric: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }

    /// Check if string contains only letters
    var isAlphabetic: Bool {
        !isEmpty && allSatisfy { $0.isLetter }
    }

    /// Check if string contains only alphanumeric characters
    var isAlphanumeric: Bool {
        !isEmpty && allSatisfy { $0.isLetter || $0.isNumber }
    }

    // MARK: - Formatting

    /// Truncate string to specified length with ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return prefix(length) + trailing
    }

    /// Capitalize first letter only
    var capitalizedFirstLetter: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Convert to title case (capitalize first letter of each word)
    var titleCased: String {
        replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression, range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }

    /// Remove all whitespace
    var removingWhitespace: String {
        filter { !$0.isWhitespace }
    }

    /// Remove extra whitespace (collapse multiple spaces into one)
    var removingExtraWhitespace: String {
        replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Convert string to snake_case
    var snakeCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: count)
        let result = regex?.stringByReplacingMatches(in: self, range: range, withTemplate: "$1_$2")
        return result?.lowercased() ?? lowercased()
    }

    /// Convert string to camelCase
    var camelCased: String {
        let components = split(separator: "_").map { String($0) }
        guard !components.isEmpty else { return self }
        let first = components[0].lowercased()
        let rest = components.dropFirst().map { $0.capitalizedFirstLetter }
        return ([first] + rest).joined()
    }

    // MARK: - Trimming

    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Remove prefix if present
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    /// Remove suffix if present
    func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }

    // MARK: - AI Helpers

    /// Format as user message for AI context
    var asUserMessage: String {
        "User: \(self)"
    }

    /// Format as system message for AI context
    var asSystemMessage: String {
        "System: \(self)"
    }

    /// Format as assistant message for AI context
    var asAssistantMessage: String {
        "Assistant: \(self)"
    }

    /// Clean string for AI prompt (remove problematic characters)
    var cleanedForAIPrompt: String {
        // Remove control characters and excessive whitespace
        var cleaned = self.removingExtraWhitespace
        // Remove any characters that might interfere with prompt parsing
        cleaned = cleaned.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return cleaned
    }

    /// Extract tags/hashtags from string
    var extractedTags: [String] {
        let pattern = "#([a-zA-Z0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
        return results.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return nsString.substring(with: match.range(at: 1))
        }
    }

    // MARK: - Subscript

    /// Safe subscript access by index
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// Subscript access by range
    subscript(range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(count - range.lowerBound, range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    // MARK: - Encoding/Decoding

    /// URL encoded string
    var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    /// Base64 encoded string
    var base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }

    /// Decode base64 string
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Utilities

    /// Count of words in string
    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }

    /// Count of characters (excluding whitespace)
    var characterCountExcludingWhitespace: Int {
        filter { !$0.isWhitespace }.count
    }

    /// Check if string contains substring (case-insensitive)
    func containsIgnoringCase(_ substring: String) -> Bool {
        range(of: substring, options: .caseInsensitive) != nil
    }

    /// Replace multiple occurrences using dictionary
    func replacingOccurrences(using replacements: [String: String]) -> String {
        var result = self
        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value)
        }
        return result
    }

    /// Generate random string of specified length
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    /// Convert string to Int
    var toInt: Int? {
        Int(self)
    }

    /// Convert string to Double
    var toDouble: Double? {
        Double(self)
    }

    /// Convert string to Bool
    var toBool: Bool? {
        switch lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }

    // MARK: - Pluralization

    /// Simple pluralization (adds 's' if count != 1)
    func pluralized(count: Int) -> String {
        count == 1 ? self : self + "s"
    }

    /// Pluralization with custom plural form
    func pluralized(count: Int, plural: String) -> String {
        count == 1 ? self : plural
    }

    // MARK: - Masking

    /// Mask email (show first 2 chars and domain)
    var maskedEmail: String {
        guard isValidEmail else { return self }
        let components = split(separator: "@")
        guard components.count == 2 else { return self }
        let username = String(components[0])
        let domain = String(components[1])
        let maskedUsername = username.prefix(2) + String(repeating: "*", count: max(0, username.count - 2))
        return "\(maskedUsername)@\(domain)"
    }

    /// Mask middle characters (show first and last 2)
    var masked: String {
        guard count > 4 else { return String(repeating: "*", count: count) }
        let first = prefix(2)
        let last = suffix(2)
        let middle = String(repeating: "*", count: count - 4)
        return "\(first)\(middle)\(last)"
    }
}

// MARK: - Optional String Extensions

extension Optional where Wrapped == String {
    /// Check if optional string is nil or empty
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }

    /// Unwrap or return empty string
    var orEmpty: String {
        self ?? ""
    }

    /// Unwrap or return default value
    func or(_ defaultValue: String) -> String {
        self ?? defaultValue
    }
}

// MARK: - Character Extensions

extension Character {
    /// Check if character is emoji
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value >= 0x1F600 || unicodeScalars.count > 1)
    }
}
