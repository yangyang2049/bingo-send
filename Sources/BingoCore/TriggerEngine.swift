import Foundation

public struct TriggerMatch: Equatable {
    /// The keyword's UTF-16 range in the unchanged original draft.
    public let keywordRange: NSRange
    /// The configured keyword that matched, exactly as the user wrote it, so
    /// removal mode deletes only that suffix.
    public let keyword: String

    public init(keywordRange: NSRange, keyword: String) {
        self.keywordRange = keywordRange
        self.keyword = keyword
    }
}

public enum TriggerMatcher {
    /// A user may configure up to three final keywords at once; any one of
    /// them ends the message.
    public static let maximumKeywordCount = 3

    public static func isValidKeyword(_ rawKeyword: String) -> Bool {
        let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty, keyword.count <= 40,
              keyword.rangeOfCharacter(from: .newlines) == nil,
              keyword.unicodeScalars.contains(where: CharacterSet.alphanumerics.contains),
              let last = keyword.last else { return false }
        // Trailing punctuation is treated as dictation punctuation by match().
        return !isTrailingDelimiter(last)
    }

    /// True when the list holds one to three keywords and every non-empty entry
    /// is a usable keyword. Empty entries are unfinished input, not errors.
    public static func isValidKeywordList(_ rawKeywords: [String]) -> Bool {
        let filled = rawKeywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard (1...maximumKeywordCount).contains(filled.count) else { return false }
        return filled.allSatisfy(isValidKeyword)
    }

    /// Drops empty and invalid entries, removes case-insensitive duplicates, and
    /// keeps the configured order up to `maximumKeywordCount` keywords.
    public static func normalizedKeywords(_ rawKeywords: [String]) -> [String] {
        var seen = Set<String>()
        var keywords: [String] = []
        for rawKeyword in rawKeywords {
            let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isValidKeyword(keyword),
                  seen.insert(keyword.lowercased()).inserted else { continue }
            keywords.append(keyword)
            if keywords.count == maximumKeywordCount { break }
        }
        return keywords
    }

    /// Matches the final keyword against a user keyword list. When more than one
    /// keyword matches, the longest wins, so "Bingo Send" beats "Send" and the
    /// removal never leaves half a keyword behind.
    public static func match(text: String, keywords: [String]) -> TriggerMatch? {
        var best: TriggerMatch?
        for keyword in normalizedKeywords(keywords) {
            guard let candidate = match(text: text, keyword: keyword) else { continue }
            if let current = best, current.keywordRange.location <= candidate.keywordRange.location {
                continue
            }
            best = candidate
        }
        return best
    }

    /// Matches a final spoken keyword, including punctuation inserted by dictation.
    public static func match(text: String, keyword: String) -> TriggerMatch? {
        let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty, !text.isEmpty else { return nil }

        var contentEnd = text.endIndex
        while contentEnd > text.startIndex {
            let previous = text.index(before: contentEnd)
            guard isTrailingDelimiter(text[previous]) else { break }
            contentEnd = previous
        }

        let searchable = text[..<contentEnd]
        guard let keywordRange = searchable.range(
            of: keyword,
            options: [.backwards, .anchored, .caseInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        ) else { return nil }

        // Chinese text can directly precede an English spoken command, but an
        // identifier such as "myBingo", "BingoBingo", or "_Bingo" must not match.
        if let first = keyword.unicodeScalars.first, isEnglishWordScalar(first),
           keywordRange.lowerBound > text.startIndex {
            let preceding = text[text.index(before: keywordRange.lowerBound)]
            if preceding.unicodeScalars.contains(where: isEnglishWordScalar) {
                return nil
            }
        }

        let body = text[..<keywordRange.lowerBound]
        guard body.unicodeScalars.contains(where: {
            !CharacterSet.whitespacesAndNewlines.contains($0)
                && !CharacterSet.punctuationCharacters.contains($0)
        }) else { return nil }

        return TriggerMatch(keywordRange: NSRange(keywordRange, in: text), keyword: keyword)
    }

    private static func isEnglishWordScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 48...57, 65...90, 95, 97...122:
            return true
        default:
            return false
        }
    }

    private static func isTrailingDelimiter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy {
            CharacterSet.whitespacesAndNewlines.contains($0)
                || CharacterSet.punctuationCharacters.contains($0)
        }
    }

}

public struct DraftSnapshot: Equatable {
    public let targetID: String
    public let text: String
    public let caretAtEnd: Bool

    public init(targetID: String, text: String, caretAtEnd: Bool) {
        self.targetID = targetID
        self.text = text
        self.caretAtEnd = caretAtEnd
    }
}

public struct TriggerAction {
    public let snapshot: DraftSnapshot
    public let match: TriggerMatch

    public init(snapshot: DraftSnapshot, match: TriggerMatch) {
        self.snapshot = snapshot
        self.match = match
    }
}

/// Pure state machine. All times should come from the same monotonic clock.
/// The adapter can suspend a briefly unavailable field and reset when the
/// remembered baseline should expire or the feature's configuration changes.
public struct TriggerEngine {
    private struct Candidate {
        let snapshot: DraftSnapshot
        let match: TriggerMatch
        let keywords: [String]
        let changedAt: TimeInterval
    }

    private var previousSnapshot: DraftSnapshot?
    private var candidate: Candidate?

    public init() {}

    public mutating func reset() {
        previousSnapshot = nil
        candidate = nil
    }

    /// Cancel a pending send without forgetting the last observed draft. This
    /// accommodates an input method temporarily hiding the original field, then
    /// returning to it after committing a new dictation result.
    public mutating func suspend() {
        candidate = nil
    }

    public mutating func observe(
        _ snapshot: DraftSnapshot,
        now: TimeInterval,
        keywords: [String],
        delay: TimeInterval
    ) -> TriggerAction? {
        let keywords = TriggerMatcher.normalizedKeywords(keywords)
        guard let previous = previousSnapshot,
              previous.targetID == snapshot.targetID else {
            // Existing text when focus enters a field is a baseline, even when
            // that old draft already contains a command.
            previousSnapshot = snapshot
            candidate = nil
            return nil
        }

        previousSnapshot = snapshot
        let textChanged = previous.text != snapshot.text
        if textChanged {
            candidate = nil
        }

        guard snapshot.caretAtEnd, now.isFinite else {
            candidate = nil
            return nil
        }

        if textChanged,
           let match = TriggerMatcher.match(text: snapshot.text, keywords: keywords) {
            candidate = Candidate(
                snapshot: snapshot,
                match: match,
                keywords: keywords,
                changedAt: now
            )
        }

        guard let pending = candidate else { return nil }
        guard pending.keywords == keywords,
              pending.snapshot == snapshot,
              now >= pending.changedAt else {
            candidate = nil
            return nil
        }

        let stableDelay = delay.isFinite ? max(0, delay) : 0.8
        guard now - pending.changedAt >= stableDelay else { return nil }
        // Clearing this candidate prevents repeat sends during subsequent polls.
        // Only another text edit can arm a new candidate.
        candidate = nil
        return TriggerAction(snapshot: snapshot, match: pending.match)
    }
}
