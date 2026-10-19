import Foundation

/// A setup suggestion, not a claim that an editor has passed compatibility tests.
public struct AgentPreset: Identifiable {
    public let id: String
    public let name: String
    public let detailZh: String
    public let detailEn: String
    public let nativeBundleIDs: [String]
    public let webHosts: [String]

    public init(id: String, name: String, detailZh: String, detailEn: String,
                nativeBundleIDs: [String], webHosts: [String]) {
        self.id = id
        self.name = name
        self.detailZh = detailZh
        self.detailEn = detailEn
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
                    detailZh: "OpenAI 桌面应用 / ChatGPT 网页版",
                    detailEn: "OpenAI desktop app / ChatGPT on the web",
                    nativeBundleIDs: ["com.openai.codex"], webHosts: ["chatgpt.com"]),
        AgentPreset(id: "claude", name: "Claude / Claude Code",
                    detailZh: "Claude 网页版；桌面应用可手动添加，终端 CLI 需另行适配",
                    detailEn: "Claude on the web; add desktop apps manually. Terminal CLI tools need separate support.",
                    nativeBundleIDs: [], webHosts: ["claude.ai"]),
        AgentPreset(id: "gemini", name: "Gemini",
                    detailZh: "Google Gemini 网页版",
                    detailEn: "Google Gemini on the web",
                    nativeBundleIDs: [], webHosts: ["gemini.google.com"]),
        AgentPreset(id: "grok", name: "Grok",
                    detailZh: "xAI 的 Grok 网页版",
                    detailEn: "Grok by xAI on the web",
                    nativeBundleIDs: [], webHosts: ["grok.com"]),
        AgentPreset(id: "cursor", name: "Cursor",
                    detailZh: "Cursor 云端 Agent；桌面应用可手动添加",
                    detailEn: "Cursor cloud agents; add the desktop app manually",
                    nativeBundleIDs: [], webHosts: ["cursor.com"]),
        AgentPreset(id: "huggingchat", name: "HuggingChat",
                    detailZh: "Hugging Face 的网页聊天（huggingface.co/chat）",
                    detailEn: "Hugging Face web chat at huggingface.co/chat",
                    nativeBundleIDs: [], webHosts: ["huggingface.co"]),
        AgentPreset(id: "deepseek", name: "DeepSeek / DeepSeek Harness",
                    detailZh: "DeepSeek 网页版 / Harness 桌面应用",
                    detailEn: "DeepSeek on the web / Harness desktop app",
                    nativeBundleIDs: ["com.deepseek.dsh"], webHosts: ["chat.deepseek.com"]),
        AgentPreset(id: "zcode", name: "ZCode",
                    detailZh: "智谱 ZCode 桌面应用可手动添加",
                    detailEn: "Add the ZCode desktop app by Zhipu manually",
                    nativeBundleIDs: [], webHosts: []),
        AgentPreset(id: "kimi", name: "Kimi",
                    detailZh: "Kimi 网页版；桌面应用可手动添加",
                    detailEn: "Kimi on the web; add the desktop app manually",
                    nativeBundleIDs: [], webHosts: ["www.kimi.com", "www.kimi.ai"]),
        AgentPreset(id: "kimi-code", name: "Kimi Code",
                    detailZh: "Kimi Code 桌面应用可手动添加，终端 CLI 需另行适配",
                    detailEn: "Add the Kimi Code desktop app manually. Terminal CLI tools need separate support.",
                    nativeBundleIDs: [], webHosts: []),
        AgentPreset(id: "workbuddy", name: "WorkBuddy",
                    detailZh: "腾讯 WorkBuddy 桌面应用",
                    detailEn: "WorkBuddy desktop app by Tencent",
                    nativeBundleIDs: ["com.tencent.workbuddy.mac"], webHosts: []),
        AgentPreset(id: "qoder-cn", name: "Qoder CN",
                    detailZh: "Qoder 桌面应用；其他版本可手动添加",
                    detailEn: "Qoder desktop app; add other editions manually",
                    nativeBundleIDs: ["com.qodercn.app"], webHosts: []),
        AgentPreset(id: "trae-cn", name: "TRAE CN",
                    detailZh: "TRAE 桌面应用；其他版本可手动添加",
                    detailEn: "TRAE desktop app; add other editions manually",
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
