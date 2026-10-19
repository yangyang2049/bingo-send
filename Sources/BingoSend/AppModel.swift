import AppKit
import SwiftUI
import UniformTypeIdentifiers
import BingoCore

struct ApplicationRule: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var bundleIdentifier: String
    var enabled = true
    var shortcut: SendShortcut = .returnKey
    var allowSingleLine = false
    var restrictToWeb = false
    var domainText = ""

    static let browserIDs: Set<String> = [
        "com.apple.Safari", "com.apple.SafariTechnologyPreview", "com.google.Chrome",
        "com.google.Chrome.canary", "com.microsoft.edgemac", "com.brave.Browser",
        "company.thebrowser.Browser", "org.mozilla.firefox", "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi", "company.thebrowser.dia", "com.openai.atlas"
    ]
    var needsDomainCheck: Bool { restrictToWeb || Self.browserIDs.contains(bundleIdentifier) }
    var hosts: [String] {
        domainText.components(separatedBy: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ",，;；")))
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
    }
}

struct Preferences: Codable, Equatable {
    var keyword = "Bingo"
    var stabilityDelay = 1.0
    var detectOnly = true
    var removeTriggerBeforeSend = false
    var rules: [ApplicationRule] = {
        var rules = [ApplicationRule(name: "Codex / ChatGPT", bundleIdentifier: "com.openai.codex", enabled: false, shortcut: .returnKey)]
        let browsers = [("Safari", "com.apple.Safari"), ("Chrome", "com.google.Chrome"), ("Edge", "com.microsoft.edgemac")]
        for (name, bundleID) in browsers where NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
            rules.append(ApplicationRule(name: name, bundleIdentifier: bundleID, enabled: false,
                restrictToWeb: true, domainText: "chat.deepseek.com\nhuggingface.co"))
        }
        return rules
    }()

    init() {}

    private enum CodingKeys: String, CodingKey {
        case keyword, stabilityDelay, detectOnly, rules, removeTriggerBeforeSend
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        keyword = try values.decode(String.self, forKey: .keyword)
        stabilityDelay = try values.decode(Double.self, forKey: .stabilityDelay)
        detectOnly = try values.decode(Bool.self, forKey: .detectOnly)
        rules = try values.decode([ApplicationRule].self, forKey: .rules)
        removeTriggerBeforeSend = try values.decodeIfPresent(Bool.self, forKey: .removeTriggerBeforeSend) ?? false
    }
}

struct InstalledApplication: Identifiable {
    let bundleIdentifier: String
    let name: String
    let url: URL
    var id: String { bundleIdentifier }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var preferences: Preferences {
        didSet {
            if let data = try? JSONEncoder().encode(preferences) {
                UserDefaults.standard.set(data, forKey: "bingoPreferencesV1")
            }
            sendingTask?.cancel()
            engine.reset()
        }
    }
    @Published var isEnabled = false {
        didSet {
            if !isEnabled { sendingTask?.cancel(); status = "已暂停" }
            if isEnabled { sendFailureMessage = nil }
            engine.reset()
        }
    }
    @Published private(set) var isTrusted = false
    @Published private(set) var status = "已暂停"
    @Published private(set) var lastEvent = "还没有检测记录"
    @Published private(set) var activeApp = ""
    @Published private(set) var isSending = false
    @Published private(set) var sendFailureMessage: String?
    @Published var editorRule: ApplicationRule?
    @Published var notice: String?

    private let client = AccessibilityClient()
    private var engine = TriggerEngine()
    private var timer: Timer?
    private var sendingTask: Task<Void, Never>?
    private var lastObservedAt: TimeInterval = 0

    var keywordIsValid: Bool {
        TriggerMatcher.isValidKeyword(preferences.keyword)
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "bingoPreferencesV1"),
           let saved = try? JSONDecoder().decode(Preferences.self, from: data) {
            preferences = saved
        } else {
            preferences = Preferences()
        }
        isTrusted = AccessibilityClient.isTrusted
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func requestPermission() {
        AccessibilityClient.requestPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func addApplication() {
        let picker = NSOpenPanel()
        picker.title = "选择要启用的 AI 应用或浏览器"
        picker.prompt = "添加应用"
        picker.allowedContentTypes = [.application]
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = false
        picker.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        guard picker.runModal() == .OK, let url = picker.url,
              let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else { return }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        let rule = preferences.rules.first(where: { $0.bundleIdentifier == bundleID })
            ?? ApplicationRule(name: name, bundleIdentifier: bundleID,
                restrictToWeb: ApplicationRule.browserIDs.contains(bundleID))
        // Present the SwiftUI editor after the native file picker has finished
        // leaving its modal session.
        DispatchQueue.main.async { [weak self] in self?.editorRule = rule }
    }

    private func installedApplication(bundleID: String) -> InstalledApplication? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
              let bundle = Bundle(url: url), bundle.bundleIdentifier == bundleID else { return nil }
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        return InstalledApplication(bundleIdentifier: bundleID, name: name, url: url)
    }

    func installedApplications(for preset: AgentPreset) -> [InstalledApplication] {
        preset.nativeBundleIDs.compactMap { installedApplication(bundleID: $0) }
    }

    var installedBrowsers: [InstalledApplication] {
        ApplicationRule.browserIDs.sorted().compactMap { installedApplication(bundleID: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func configureNativePreset(_ preset: AgentPreset, application: InstalledApplication) {
        var rule = preferences.rules.first { $0.bundleIdentifier == application.bundleIdentifier }
            ?? ApplicationRule(name: preset.name, bundleIdentifier: application.bundleIdentifier)
        rule.enabled = true
        editorRule = rule
    }

    func addWebPreset(_ preset: AgentPreset, browser: InstalledApplication, shortcut: SendShortcut) {
        guard !preset.webHosts.isEmpty,
              ApplicationRule.browserIDs.contains(browser.bundleIdentifier) else { return }
        var rule = preferences.rules.first { $0.bundleIdentifier == browser.bundleIdentifier }
            ?? ApplicationRule(name: browser.name, bundleIdentifier: browser.bundleIdentifier)
        rule.domainText = PresetDomains.merging(existing: rule.domainText, hosts: preset.webHosts)
        rule.restrictToWeb = true
        rule.enabled = true
        rule.shortcut = shortcut
        save(rule)
    }

    func save(_ rule: ApplicationRule) {
        if let index = preferences.rules.firstIndex(where: { $0.id == rule.id }) {
            preferences.rules[index] = rule
        } else {
            preferences.rules.append(rule)
        }
        editorRule = nil
    }

    func remove(_ rule: ApplicationRule) {
        preferences.rules.removeAll { $0.id == rule.id }
        editorRule = nil
    }

    private func tick() {
        let trusted = AccessibilityClient.isTrusted
        if trusted != isTrusted { isTrusted = trusted }
        guard isEnabled else { return }
        guard trusted else { engine.reset(); status = "请先授权辅助功能"; return }
        guard keywordIsValid else { engine.reset(); status = "请填写有效的口令"; return }
        guard !isSending else { return }
        guard let app = client.currentApplicationIdentity(),
              app.bundleIdentifier != Bundle.main.bundleIdentifier else {
            suspendObservation(); status = "等待切换到已启用的应用"; return
        }
        activeApp = app.name
        guard let rule = preferences.rules.first(where: { $0.enabled && $0.bundleIdentifier == app.bundleIdentifier }) else {
            suspendObservation(); status = "\(app.name) 未启用"; return
        }
        do {
            let hosts = rule.needsDomainCheck ? rule.hosts : nil
            let draft = try client.focusedDraft(expectedBundleIdentifier: rule.bundleIdentifier,
                expectedProcessID: app.processID, allowSingleLine: rule.allowSingleLine, allowedPageHosts: hosts)
            guard draft.bundleIdentifier == rule.bundleIdentifier else { engine.reset(); return }
            let observationTime = ProcessInfo.processInfo.systemUptime
            if observationTime - lastObservedAt > 180 { engine.reset() }
            lastObservedAt = observationTime
            status = preferences.detectOnly ? "\(rule.name)：仅检测，不发送" : "\(rule.name)：等待句尾口令"
            let delay = min(3, max(0.5, preferences.stabilityDelay))
            guard engine.observe(draft.snapshot, now: ProcessInfo.processInfo.systemUptime,
                keyword: preferences.keyword, delay: delay) != nil else { return }
            if preferences.detectOnly {
                lastEvent = "\(timeLabel()) · \(rule.name)：识别到口令，未修改、未发送"
                status = "检测成功 · 可关闭「只检测」启用发送"
                NSSound.beep()
                return
            }
            isSending = true
            let removalKeyword = preferences.removeTriggerBeforeSend ? preferences.keyword : nil
            status = removalKeyword == nil ? "正在发送完整正文…" : "正在移除句尾口令并核验…"
            lastEvent = "\(timeLabel()) · \(rule.name)：已识别口令，正在\(removalKeyword == nil ? "原样发送" : "处理句尾口令")"
            sendingTask = Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.isSending = false; self.engine.reset(); self.sendingTask = nil }
                do {
                    try Task.checkCancellation()
                    try await self.client.sendDraft(draft, shortcut: rule.shortcut,
                        allowedPageHosts: hosts, removeKeyword: removalKeyword)
                    self.lastEvent = "\(self.timeLabel()) · 已向 \(rule.name) 发出发送按键；请在目标应用确认"
                    self.status = "已发出发送按键"
                } catch is CancellationError {
                    self.lastEvent = "\(self.timeLabel()) · 已取消发送，请检查输入框\(removalKeyword == nil ? "" : "；草稿或选区可能已变化")"
                    self.status = "已取消发送，请检查输入框"
                } catch {
                    self.isEnabled = false
                    self.sendFailureMessage = error.localizedDescription
                    self.lastEvent = "\(self.timeLabel()) · 已暂停：\(error.localizedDescription)"
                    self.status = "发送已中止，请检查原输入框"
                }
            }
        } catch {
            suspendObservation()
            status = "\(rule.name)：\(error.localizedDescription)"
        }
    }

    private func suspendObservation() {
        if ProcessInfo.processInfo.systemUptime - lastObservedAt > 180 {
            engine.reset()
        } else {
            engine.suspend()
        }
    }

    private func timeLabel() -> String {
        Date().formatted(date: .omitted, time: .shortened)
    }
}
