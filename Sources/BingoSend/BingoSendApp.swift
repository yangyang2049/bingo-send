import SwiftUI
import AppKit
import BingoCore

@main
struct BingoSendApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Bingo Send", id: "settings") {
            MainView(model: model)
                .tint(.teal)
        }
        .defaultSize(width: 650, height: 710)
        .windowResizability(.contentMinSize)

        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            Image(systemName: model.modeSymbol)
        }
    }
}

private struct MenuContent: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Bingo Send")
        Text(model.status)
        Divider()
        Text(model.modeTitle)
        Picker(L10n.text(zh: "运行模式", en: "Run mode"), selection: $model.runMode) {
            ForEach(RunMode.allCases, id: \.self) { mode in
                Text(mode.title).tag(mode).disabled(mode != .paused && !model.canStart)
            }
        }
        .disabled(!model.canStart && model.runMode == .paused)
        Divider()
        Button(L10n.text(zh: "打开设置…", en: "Open Settings…")) {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")
        Button(L10n.text(zh: "退出 Bingo Send", en: "Quit Bingo Send")) { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

private struct MainView: View {
    @ObservedObject var model: AppModel
    @State private var selectedTab = "settings"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().interpolation(.high)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bingo Send").font(.title2.weight(.semibold))
                    Text(L10n.text(zh: "继续使用原来的输入法，用句尾口令发送。", en: "Keep your input method. End with a keyword to send."))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Label(model.modeTitle, systemImage: model.modeSymbol)
                    .font(.callout)
                    .foregroundStyle(model.runState == .automatic ? Color.teal : Color.secondary)
            }
            .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text(zh: "最近一次结果", en: "Last result")).font(.caption).foregroundStyle(.secondary)
                Text(model.lastEvent).font(.callout)
                    .textSelection(.enabled).lineLimit(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 14)

            TabView(selection: $selectedTab) {
                SettingsView(model: model, showPresets: { selectedTab = "presets" })
                    .tabItem { Text(L10n.text(zh: "设置", en: "Settings")) }.tag("settings")
                AgentCatalogView(model: model).tabItem { Text(L10n.text(zh: "应用预设", en: "App presets")) }.tag("presets")
                PreviewView(configuredKeywords: model.activeKeywords,
                    removeTriggerBeforeSend: model.preferences.removeTriggerBeforeSend,
                    runMode: model.runMode)
                    .tabItem { Text(L10n.text(zh: "试用口令", en: "Try a keyword")) }.tag("preview")
                HelpView().tabItem { Text(L10n.text(zh: "使用说明", en: "Help")) }.tag("help")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            Divider()
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Label(model.status, systemImage: "circle.fill")
                    Spacer(minLength: 8)
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? L10n.text(zh: "开发版", en: "dev"))")
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(.bar)
        }
        .frame(minWidth: 620, minHeight: 650)
        .sheet(item: $model.editorRule) { rule in
            RuleEditor(model: model, rule: rule)
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var model: AppModel
    let showPresets: () -> Void

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.isTrusted ? L10n.text(zh: "辅助功能已授权", en: "Accessibility authorized") : L10n.text(zh: "先授权辅助功能", en: "Allow Accessibility access"))
                        Text(L10n.text(zh: "用于读取聚焦输入框、按选项处理句尾口令并触发发送。", en: "Reads the focused editor, optionally removes the final keyword, and triggers sending."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(model.isTrusted ? L10n.text(zh: "系统设置…", en: "System Settings…") : L10n.text(zh: "去授权…", en: "Grant access…")) { model.requestPermission() }
                }
                Picker(L10n.text(zh: "运行模式", en: "Run mode"), selection: $model.runMode) {
                    ForEach(RunMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode).disabled(mode != .paused && !model.canStart)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!model.canStart && model.runMode == .paused)
                Text(model.modeDescription)
                    .font(.callout).fixedSize(horizontal: false, vertical: true)
                if !model.preferences.rules.contains(where: \.enabled) {
                    Text(L10n.text(zh: "请先在「启用范围」添加并启用一个应用，再选择运行模式。", en: "Add and enable an app under Enabled apps before choosing a running mode."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Toggle(L10n.text(zh: "发送前移除句尾口令", en: "Remove final keyword before sending"), isOn: $model.preferences.removeTriggerBeforeSend)
                    .disabled(model.runMode == .testing)
                if model.runMode == .testing {
                    Text(L10n.text(zh: "测试识别期间，移除设置不生效。切到自动发送后才会按此设置处理。", en: "Removal does not apply during detection tests. It applies only in Auto send."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if model.sendFailureMessage != nil {
                    Label(L10n.text(zh: "发送遇到错误，已自动暂停。请查看「最近一次结果」并检查草稿，确认后重新开启。", en: "Sending paused after an error. Check the last result and your draft before enabling it again."),
                          systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(L10n.text(zh: "每次启动均暂停。切换模式或修改配置后，请在目标输入框输入一条新内容；已有草稿不会立即触发。测试识别成功仅代表能识别口令，实际发送和移除需分别验证。", en: "Every launch starts paused. After changing mode or settings, enter new text in the target editor; existing drafts do not trigger immediately. Detection does not verify sending or removal; test each separately."))
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text(L10n.text(zh: "运行", en: "Sending")) }

            Section {
                ForEach(Array(model.preferences.keywords.indices), id: \.self) { index in
                    HStack {
                        TextField(L10n.text(zh: "句尾口令 \(index + 1)", en: "Final keyword \(index + 1)"),
                                  text: $model.preferences.keywords[index])
                        Button {
                            model.removeKeyword(at: index)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(model.preferences.keywords.count <= 1)
                        .help(L10n.text(zh: "移除这个口令", en: "Remove this keyword"))
                        .accessibilityLabel(L10n.text(zh: "移除口令 \(index + 1)", en: "Remove keyword \(index + 1)"))
                    }
                }
                HStack {
                    Button {
                        model.appendKeyword()
                    } label: {
                        Label(L10n.text(zh: "再加一个口令", en: "Add another keyword"), systemImage: "plus")
                    }
                    .disabled(!model.canAddKeyword)
                    Spacer(minLength: 4)
                    Menu(L10n.text(zh: "填入常用口令", en: "Fill in common keywords")) {
                        Button(L10n.text(zh: "英文三个：Bingo、Submit、Send", en: "English three: Bingo, Submit, Send")) {
                            model.applyKeywordPack(KeywordCatalog.englishPack)
                        }
                        Button(L10n.text(zh: "中文三个：发送、提交、完成", en: "Chinese three: 发送, 提交, 完成")) {
                            model.applyKeywordPack(KeywordCatalog.chinesePack)
                        }
                        Button(L10n.text(zh: "中英混用：Bingo、Send、发送", en: "Mixed: Bingo, Send, 发送")) {
                            model.applyKeywordPack(KeywordCatalog.mixedPack)
                        }
                        Divider()
                        ForEach(KeywordCatalog.presets, id: \.self) { keyword in
                            Button(keyword == "Bingo" ? "Bingo / BINGO" : keyword) {
                                model.appendKeyword(keyword)
                            }
                            .disabled(!model.canAddKeyword)
                        }
                    }
                    .fixedSize()
                }
                Text(L10n.text(zh: "最多 3 个口令，句尾命中任意一个即发送；可中英混用，也可全部自定义。", en: "Up to 3 keywords; any one of them at the end sends. Mix languages or use your own."))
                    .font(.caption).foregroundStyle(.secondary)
                if !model.keywordIsValid {
                    Text(L10n.text(zh: "至少保留一个口令；每个口令需包含文字或数字，最多 40 个字符，不能以标点结尾或包含换行。", en: "Keep at least one keyword. Each needs letters or numbers, up to 40 characters, no line breaks or trailing punctuation."))
                        .font(.caption).foregroundStyle(.red)
                }
                LabeledContent(L10n.text(zh: "文字稳定等待", en: "Wait for text to settle")) {
                    Slider(value: $model.preferences.stabilityDelay, in: 0.5...3, step: 0.1)
                        .frame(width: 150)
                        .accessibilityLabel(L10n.text(zh: "文字稳定等待秒数", en: "Text settling delay in seconds"))
                    Text(String(format: L10n.text(zh: "%.1f 秒", en: "%.1f s"), model.preferences.stabilityDelay))
                        .monospacedDigit().frame(width: 54, alignment: .trailing)
                }
                Text(L10n.text(zh: "只认句尾口令，兼容结尾标点与大小写；需将光标放在正文末尾。", en: "Matches only at the end, ignoring case and trailing punctuation. Keep the caret at the end."))
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text(L10n.text(zh: "口令", en: "Keyword")) }

            Section {
                ForEach($model.preferences.rules) { $rule in
                    HStack(spacing: 10) {
                        Toggle(isOn: $rule.enabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(rule.name)
                                Text(rule.needsDomainCheck
                                    ? (rule.hosts.isEmpty ? L10n.text(zh: "请设置允许的网站域名", en: "Set allowed website domains") : rule.hosts.joined(separator: L10n.text(zh: "、", en: ", ")))
                                    : L10n.text(zh: "原生应用 · \(rule.shortcut.title)", en: "Native app · \(rule.shortcut.title)"))
                                    .font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer(minLength: 4)
                        Button { model.editorRule = rule } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.text(zh: "配置 \(rule.name)", en: "Configure \(rule.name)"))
                        .accessibilityLabel(L10n.text(zh: "配置 \(rule.name)", en: "Configure \(rule.name)"))
                    }
                }
                HStack {
                    Button(action: showPresets) { Label(L10n.text(zh: "从常用预设添加…", en: "Add from presets…"), systemImage: "square.grid.2x2") }
                    Button { model.addApplication() } label: {
                        Label(L10n.text(zh: "手动添加应用…", en: "Add an app manually…"), systemImage: "plus")
                    }
                }
                Text(L10n.text(zh: "只处理已启用应用中的聚焦输入框。已识别浏览器强制限制域名；其他浏览器请手动开启「按网页域名限制」。特殊编辑器可能无法读取。", en: "Only enabled apps are checked. Recognized browsers require allowed domains; enable domain restrictions for other browsers. Some editors may not expose their text."))
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text(L10n.text(zh: "启用范围", en: "Enabled apps")) }
        }
        .formStyle(.grouped)
    }
}

private struct RuleEditor: View {
    @ObservedObject var model: AppModel
    @State var rule: ApplicationRule
    @Environment(\.dismiss) private var dismiss

    private var domainsAreValid: Bool {
        guard rule.needsDomainCheck else { return true }
        return !rule.hosts.isEmpty && rule.hosts.allSatisfy { host in
            WebScope.allows(URL(string: "https://\(host)"), hosts: [host])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(rule.name).font(.title2.weight(.semibold))
            Text(rule.bundleIdentifier).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            Form {
                Toggle(L10n.text(zh: "启用此应用", en: "Enable this app"), isOn: $rule.enabled)
                Picker(L10n.text(zh: "发送按键", en: "Send shortcut"), selection: $rule.shortcut) {
                    ForEach(SendShortcut.allCases, id: \.self) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }
                Toggle(L10n.text(zh: "允许单行输入框", en: "Allow single-line editors"), isOn: $rule.allowSingleLine)
                Text(L10n.text(zh: "默认只识别多行编辑框。仅当聊天框确实是单行控件时才开启。", en: "Only multiline editors are recognized by default. Enable this only for a single-line chat field."))
                    .font(.caption).foregroundStyle(.secondary)
                Toggle(L10n.text(zh: "按网页域名限制", en: "Restrict by website domain"), isOn: $rule.restrictToWeb)
                    .disabled(ApplicationRule.browserIDs.contains(rule.bundleIdentifier))
                if rule.needsDomainCheck {
                    Text(L10n.text(zh: "允许的网站域名", en: "Allowed website domains")).font(.headline)
                    TextEditor(text: $rule.domainText)
                        .font(.body.monospaced())
                        .frame(height: 90)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.quaternary))
                        .accessibilityLabel(L10n.text(zh: "允许的网站域名，每行一个", en: "Allowed website domains, one per line"))
                    Text(L10n.text(zh: "每行一个域名，例如 chat.deepseek.com。包含该域名的子域名；不要填写网址路径或 https://。无法确认网页地址时不会发送。", en: "One domain per line, such as chat.deepseek.com. Subdomains are included. Omit URL paths and https://. Sending stops if the page address cannot be verified."))
                        .font(.caption).foregroundStyle(.secondary)
                    if !domainsAreValid {
                        Text(L10n.text(zh: "请至少填写一个有效的域名。", en: "Enter at least one valid domain."))
                            .font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                if model.preferences.rules.contains(where: { $0.id == rule.id }) {
                    Button(L10n.text(zh: "移除", en: "Remove"), role: .destructive) { model.remove(rule) }
                }
                Spacer()
                Button(L10n.text(zh: "取消", en: "Cancel")) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.text(zh: "保存", en: "Save")) { model.save(rule) }
                    .keyboardShortcut(.defaultAction).disabled(!domainsAreValid)
            }
        }
        .padding(24).frame(width: 500, height: rule.needsDomainCheck ? 550 : 390)
    }
}

private struct PreviewView: View {
    let configuredKeywords: [String]
    let removeTriggerBeforeSend: Bool
    let runMode: RunMode
    @State private var example = ""
    @State private var result: String?
    @State private var matched: String?

    private var keywords: [String] {
        configuredKeywords
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text(zh: "先试试你的说法", en: "Try your wording")).font(.title3.weight(.semibold))
            Text(L10n.text(zh: "本页只检查匹配和文字处理，不读取其他应用、不发出发送按键，也不代表目标应用已兼容。", en: "Checks matching and text handling only. It does not read other apps, post a send shortcut, or verify editor compatibility."))
                .foregroundStyle(.secondary)
            Label(runMode.title, systemImage: runMode == .testing ? "waveform.circle" : "info.circle")
                .font(.callout)
            HStack(spacing: 6) {
                Text(L10n.text(zh: "当前口令", en: "Active keywords")).font(.callout).foregroundStyle(.secondary)
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.callout)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.quaternary.opacity(0.5), in: Capsule())
                }
                Spacer()
            }
            TextEditor(text: $example)
                .font(.body).padding(8)
                .frame(minHeight: 110, maxHeight: 170)
                .background(.background)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .accessibilityLabel(L10n.text(zh: "测试正文，可以用豆包输入法输入", en: "Test message; enter it with your preferred input method"))
            Button(L10n.text(zh: "检查口令", en: "Check keyword")) {
                guard let match = TriggerMatcher.match(text: example, keywords: keywords) else {
                    matched = nil
                    result = L10n.text(zh: "未匹配：请在有正文的内容末尾添加任意一个完整口令。", en: "No match. Add one of the complete keywords after your message.")
                    return
                }
                matched = match.keyword
                result = removeTriggerBeforeSend && runMode != .testing
                    ? TriggerText.removingSuffix(from: example, keyword: match.keyword) : example
            }
            .buttonStyle(.borderedProminent)
            .disabled(keywords.isEmpty)
            if let result {
                Text(matched.map { keyword in
                    runMode == .testing
                        ? L10n.text(zh: "命中「\(keyword)」 · 测试识别，保留原文、不发送", en: "Matched “\(keyword)” · Detection test: unchanged, not sent")
                        : L10n.text(zh: "命中「\(keyword)」 · 发送文字预览（本页不发送）", en: "Matched “\(keyword)” · Message preview only; not sent here")
                } ?? L10n.text(zh: "未匹配口令", en: "No keyword matched"))
                    .font(.headline)
                Text(result).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text(runMode == .testing
                ? L10n.text(zh: "测试识别不会移除口令，也不会验证发送按键。更改示例、口令、模式或移除设置后，需要重新检查。", en: "Detection tests never remove keywords or verify sending. Recheck after changing the sample, keywords, mode, or removal setting.")
                : removeTriggerBeforeSend
                ? L10n.text(zh: "当前已开启移除句尾口令。编辑器必须支持可靠修改并通过读回核验，否则停止发送；中断后请检查草稿和选区。", en: "Final keyword removal is on. Sending requires a verified edit. If interrupted, check your draft and selection.")
                : L10n.text(zh: "当前保留口令。先在目标编辑器选择「测试识别」，再选择「自动发送」验证真实发送。", en: "The keyword will be kept. Use Test detection in the target editor, then Auto send to verify actual sending."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .onAppear {
            if example.isEmpty {
                let sample = keywords.first ?? "Bingo"
                example = L10n.text(zh: "帮我检查这个页面。\(sample)。", en: "Review this page. \(sample).")
            }
        }
        .onChange(of: example) { _ in clearResult() }
        .onChange(of: configuredKeywords) { _ in clearResult() }
        .onChange(of: removeTriggerBeforeSend) { _ in clearResult() }
        .onChange(of: runMode) { _ in clearResult() }
    }

    private func clearResult() { result = nil; matched = nil }
}

private struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.text(zh: "保留你的输入法", en: "Keep your input method")).font(.title3.weight(.semibold))
                Text(L10n.text(zh: "豆包或其他输入法继续负责语音转文字。Bingo Send 只检查允许范围内的当前输入框，检测到口令后发送；默认保留口令，也可选择先移除句尾口令。不录音、不联网、不保存正文。", en: "Keep using Doubao or your preferred dictation input method. Bingo Send checks the focused editor in enabled apps and triggers sending when the final keyword is detected. Keep the keyword, or choose to remove it. No audio recording, network requests, or saved chat text."))
                Text(L10n.text(zh: "第一次使用", en: "Getting started")).font(.headline)
                Text(L10n.text(zh: "1. 在设置中点击「去授权」，亲自在系统辅助功能列表开启 Bingo Send。\n\n2. 添加并启用目标应用；网页版请选择浏览器，确认允许域名与发送按键。\n\n3. 设置最多 3 个口令，选择「测试识别」，再在目标输入框输入一条以口令结尾的新内容。提示音仅代表识别成功，不修改、不发送。\n\n4. 选择「自动发送」，先保持移除关闭，测试另一条新内容；确认真实发送后，再单独测试移除。目标应用本身必须能够发送：模型不可用、发送按钮禁用或网络错误均可能阻止发送。", en: "1. Grant Bingo Send Accessibility access yourself in System Settings.\n\n2. Add and enable a target app. For a website, review the browser, allowed domains, and send shortcut.\n\n3. Set up to 3 keywords and choose Test detection. Enter a new message ending in a keyword in the target editor. The sound confirms detection only; the draft is not edited or sent.\n\n4. Choose Auto send, leave removal off, and test another new message. Test removal separately afterward. The target app must be ready to send: unavailable models, a disabled send button, or network errors can prevent sending."))
                Text(L10n.text(zh: "兼容范围", en: "Compatibility")).font(.headline)
                Text(L10n.text(zh: "原生应用、Electron 应用、浏览器网页都可以添加，但控件必须公开输入框文本和光标位置。预设只帮助填写范围；Claude、Gemini、Grok、DeepSeek、Kimi、ZCode 等需要逐个验证。终端中的 CLI 工具不包含在这些预设的已验证范围内。", en: "You can add native apps, Electron apps, and browser editors that expose their text and caret through Accessibility. Presets simplify setup; test each editor separately. Terminal CLI editors are not covered."))
                Text(L10n.text(zh: "输入法与发送", en: "Dictation and sending")).font(.headline)
                Text(L10n.text(zh: "需等文字写入目标输入框，光标位于正文末尾且没有选中文字。文字稳定等待可减少增量转写时的提前触发，但无法替输入法确认录音已经结束。它不会替豆包按下「结束录音」。\n\n默认保留完整正文与口令。可开启「发送前移除句尾口令」，只去掉最后匹配的口令及其尾随标点、空白；修改后核验成功才发送。若编辑器不支持或过程被中断，会停止发送，请检查草稿和选区。\n\n发送按键发出后，仍应以目标应用实际结果为准。", en: "Wait for dictation text to appear in the editor, with the caret at the end and no selection. The settling delay reduces early triggers during incremental transcription; it cannot confirm or stop your input method’s recording.\n\nThe complete message and keyword are kept by default. Turn on Remove final keyword before sending to remove only that keyword and following punctuation or whitespace. Sending requires a verified edit. If unsupported or interrupted, check your draft and selection.\n\nAlways confirm the actual result in the target app."))
                Text(L10n.text(zh: "随时暂停", en: "Pause anytime")).font(.headline)
                Text(L10n.text(zh: "从菜单栏或设置选择「暂停」，立即停止读取和发送；即使权限失效或口令无效也可暂停。每次启动均暂停，关闭窗口后仍在菜单栏运行，选择「退出 Bingo Send」才完全停止。", en: "Choose Paused from the menu bar or Settings to stop reading and sending, including when permission or keywords are invalid. Every launch starts paused. Closing the window leaves the app running; choose Quit Bingo Send to stop it completely."))
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }
    }
}
