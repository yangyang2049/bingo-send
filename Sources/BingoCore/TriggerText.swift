import Foundation

public enum TriggerText {
    /// Removes only a matched final keyword and everything after it, including
    /// dictation punctuation and whitespace. The prefix is preserved exactly:
    /// punctuation, code, line breaks and whitespace before the keyword stay.
    public static func removingSuffix(from text: String, keyword: String) -> String? {
        guard let match = TriggerMatcher.match(text: text, keyword: keyword),
              let range = Range(match.keywordRange, in: text) else { return nil }
        return String(text[..<range.lowerBound])
    }
}
