import Foundation
import BingoCore

/// UI language follows the system's ordered preferred languages. The app has
/// no language/region setting, and unsupported language lists use English.
enum L10n {
    enum Language: Equatable {
        case english
        case simplifiedChinese
    }

    static func language(for preferredLanguages: [String]) -> Language {
        for identifier in preferredLanguages {
            let language = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "_", with: "-")
                .split(separator: "-").first?.lowercased()
            switch language {
            case "en": return .english
            // All Chinese preferences use the app's Simplified Chinese copy,
            // including zh-Hant, instead of falling back to English.
            case "zh": return .simplifiedChinese
            default: continue
            }
        }
        return .english
    }

    static func text(zh: String, en: String,
                     preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        language(for: preferredLanguages) == .simplifiedChinese ? zh : en
    }

    /// Fresh installs start with a three-keyword pack in the interface language.
    static func defaultKeywords(for preferredLanguages: [String] = Locale.preferredLanguages) -> [String] {
        KeywordCatalog.defaultPack(forSimplifiedChinese: language(for: preferredLanguages) == .simplifiedChinese)
    }

    /// Joins a keyword list for status text, e.g. "Bingo、Submit、Send".
    static func joinedKeywords(_ keywords: [String]) -> String {
        keywords.joined(separator: text(zh: "、", en: ", "))
    }
}
