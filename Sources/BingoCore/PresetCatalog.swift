import Foundation

public enum AgentPresetGroup: String, CaseIterable {
    case international
    case china
}

/// A setup suggestion, not a claim that an editor has passed compatibility tests.
public struct AgentPreset: Identifiable {
    public let id: String
    public let name: String
    public let detail: String
    public let group: AgentPresetGroup
    public let nativeBundleIDs: [String]
    public let webHosts: [String]

    public init(id: String, name: String, detail: String, group: AgentPresetGroup,
                nativeBundleIDs: [String], webHosts: [String]) {
        self.id = id
        self.name = name
        self.detail = detail
        self.group = group
        self.nativeBundleIDs = nativeBundleIDs
        self.webHosts = webHosts
    }
}

public enum AgentCatalog {
    // Product pages and editor hosts were checked against official sources on
    // 2026-10-19. Native IDs below were read from installed apps' Info.plist files.
    // Unknown native IDs stay empty; setup can offer the ordinary app picker.
    // CLI tools and local web servers are deliberately not application presets.
    public static let presets: [AgentPreset] = [
        AgentPreset(id: "codex-chatgpt", name: "Codex / ChatGPT",
                    detail: "OpenAI 桌面应用 / ChatGPT 网页版", group: .international,
                    nativeBundleIDs: ["com.openai.codex"], webHosts: ["chatgpt.com"]),
        AgentPreset(id: "claude", name: "Claude / Claude Code",
                    detail: "Claude 网页版；桌面应用可手动添加，终端 CLI 需另行适配", group: .international,
                    nativeBundleIDs: [], webHosts: ["claude.ai"]),
        AgentPreset(id: "gemini", name: "Gemini",
                    detail: "Google Gemini 网页版", group: .international,
                    nativeBundleIDs: [], webHosts: ["gemini.google.com"]),
        AgentPreset(id: "grok", name: "Grok",
                    detail: "xAI 的 Grok 网页版", group: .international,
                    nativeBundleIDs: [], webHosts: ["grok.com"]),
        AgentPreset(id: "cursor", name: "Cursor",
                    detail: "Cursor 云端 Agent；桌面应用可手动添加", group: .international,
                    nativeBundleIDs: [], webHosts: ["cursor.com"]),
        AgentPreset(id: "huggingchat", name: "HuggingChat",
                    detail: "Hugging Face 的网页聊天（huggingface.co/chat）", group: .international,
                    nativeBundleIDs: [], webHosts: ["huggingface.co"]),
        AgentPreset(id: "deepseek", name: "DeepSeek / DeepSeek Harness",
                    detail: "DeepSeek 网页版 / Harness 桌面应用", group: .china,
                    nativeBundleIDs: ["com.deepseek.dsh"], webHosts: ["chat.deepseek.com"]),
        AgentPreset(id: "zcode", name: "ZCode（智谱）",
                    detail: "ZCode 桌面应用可手动添加", group: .china,
                    nativeBundleIDs: [], webHosts: []),
        AgentPreset(id: "kimi", name: "Kimi",
                    detail: "Kimi 国内 / 国际网页版；桌面应用可手动添加", group: .china,
                    nativeBundleIDs: [], webHosts: ["www.kimi.com", "www.kimi.ai"]),
        AgentPreset(id: "kimi-code", name: "Kimi Code",
                    detail: "Kimi Code 桌面应用可手动添加，终端 CLI 需另行适配", group: .china,
                    nativeBundleIDs: [], webHosts: []),
        AgentPreset(id: "workbuddy", name: "WorkBuddy",
                    detail: "腾讯 WorkBuddy 桌面应用", group: .china,
                    nativeBundleIDs: ["com.tencent.workbuddy.mac"], webHosts: []),
        AgentPreset(id: "qoder-cn", name: "Qoder CN",
                    detail: "Qoder 国内版桌面应用；其他版本可手动添加", group: .china,
                    nativeBundleIDs: ["com.qodercn.app"], webHosts: []),
        AgentPreset(id: "trae-cn", name: "TRAE CN",
                    detail: "TRAE 国内版桌面应用；其他版本可手动添加", group: .china,
                    nativeBundleIDs: ["cn.trae.app"], webHosts: [])
    ]
}

public enum KeywordCatalog {
    /// Suggestions for one active keyword. Matching is already case insensitive.
    public static let presets = ["Bingo", "Submit", "Send", "发送", "提交", "完成", "确认", "确定"]
}

public enum PresetDomains {
    /// Add explicit editor hosts to a user's list without replacing existing
    /// entries or turning a chat subdomain into its broader parent domain.
    /// Non-domain tokens remain harmless: WebScope rejects them when matching.
    public static func merging(existing: String, hosts: [String]) -> String {
        let separators = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: ",，;；"))
        let entries = ([existing] + hosts).flatMap { $0.components(separatedBy: separators) }
        var seen = Set<String>()
        return entries.compactMap { rawEntry -> String? in
            var entry = rawEntry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if entry.hasSuffix(".") { entry.removeLast() }
            guard !entry.isEmpty, seen.insert(entry).inserted else { return nil }
            return entry
        }.joined(separator: "\n")
    }
}
