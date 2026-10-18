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
            Image(systemName: model.isEnabled ? "paperplane.circle.fill" : "paperplane.circle")
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
        Toggle("启用口令发送", isOn: $model.isEnabled)
            .disabled(!model.isTrusted || !model.keywordIsValid)
        Toggle("只检测，不发送", isOn: $model.preferences.detectOnly)
        Divider()
        Button("打开设置…") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")
        Button("退出 Bingo Send") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

private struct MainView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(.teal)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bingo Send").font(.title2.weight(.semibold))
                    Text("继续用豆包输入，说完 Bingo 就发送。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Label(model.isEnabled ? "已启用" : "已暂停", systemImage: model.isEnabled ? "checkmark.circle.fill" : "pause.circle")
                    .font(.callout)
                    .foregroundStyle(model.isEnabled ? Color.teal : Color.secondary)
            }
            .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 5) {
                Text("最近一次结果").font(.caption).foregroundStyle(.secondary)
                Text(model.lastEvent).font(.callout)
                    .textSelection(.enabled).lineLimit(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 14)

            TabView {
                SettingsView(model: model).tabItem { Text("设置") }
                PreviewView(configuredKeyword: model.preferences.keyword).tabItem { Text("试用口令") }
                HelpView().tabItem { Text("使用说明") }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            Divider()
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Label(model.status, systemImage: "circle.fill")
                    Spacer(minLength: 8)
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版")")
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

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.isTrusted ? "辅助功能已授权" : "先授权辅助功能")
                        Text("用于读取聚焦输入框并触发发送，正文保持原样。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(model.isTrusted ? "系统设置…" : "去授权…") { model.requestPermission() }
                }
                Toggle("启用口令发送", isOn: $model.isEnabled)
                    .disabled(!model.isTrusted || !model.keywordIsValid)
                Toggle("只检测，不发送", isOn: $model.preferences.detectOnly)
                Text(model.preferences.detectOnly
                    ? "先在目标应用输入一条以 \(model.preferences.keyword) 结尾的新内容。检测成功后会提示音，正文不会被修改。"
                    : "检测到句尾口令后，会原样发送完整正文，Bingo 也会保留在消息中。")
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text("运行") }

            Section {
                TextField("句尾口令", text: $model.preferences.keyword)
                if !model.keywordIsValid {
                    Text("口令需包含文字或数字，最多 40 个字符。")
                        .font(.caption).foregroundStyle(.red)
                }
                LabeledContent("文字稳定等待") {
                    Slider(value: $model.preferences.stabilityDelay, in: 0.5...3, step: 0.1)
                        .frame(width: 150)
                        .accessibilityLabel("文字稳定等待秒数")
                    Text(String(format: "%.1f 秒", model.preferences.stabilityDelay))
                        .monospacedDigit().frame(width: 54, alignment: .trailing)
                }
                Text("只认句尾口令，兼容结尾标点与英文大小写；需将光标放在正文末尾。")
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text("口令") }

            Section {
                ForEach($model.preferences.rules) { $rule in
                    HStack(spacing: 10) {
                        Toggle(isOn: $rule.enabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(rule.name)
                                Text(rule.needsDomainCheck
                                    ? (rule.hosts.isEmpty ? "请设置允许的网站域名" : rule.hosts.joined(separator: "、"))
                                    : "原生应用 · \(rule.shortcut.title)")
                                    .font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer(minLength: 4)
                        Button { model.editorRule = rule } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderless)
                        .help("配置 \(rule.name)")
                        .accessibilityLabel("配置 \(rule.name)")
                    }
                }
                Button { model.addApplication() } label: {
                    Label("添加应用或浏览器…", systemImage: "plus")
                }
                Text("只处理已启用应用中的聚焦输入框。已识别浏览器强制限制域名；其他浏览器请手动开启「按网页域名限制」。特殊编辑器可能无法读取。")
                    .font(.caption).foregroundStyle(.secondary)
            } header: { Text("启用范围") }
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
                Toggle("启用此应用", isOn: $rule.enabled)
                Picker("发送按键", selection: $rule.shortcut) {
                    ForEach(SendShortcut.allCases, id: \.self) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }
                Toggle("允许单行输入框", isOn: $rule.allowSingleLine)
                Text("默认只识别多行编辑框。仅当聊天框确实是单行控件时才开启。")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("按网页域名限制", isOn: $rule.restrictToWeb)
                    .disabled(ApplicationRule.browserIDs.contains(rule.bundleIdentifier))
                if rule.needsDomainCheck {
                    Text("允许的网站域名").font(.headline)
                    TextEditor(text: $rule.domainText)
                        .font(.body.monospaced())
                        .frame(height: 90)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.quaternary))
                        .accessibilityLabel("允许的网站域名，每行一个")
                    Text("每行一个域名，例如 chat.deepseek.com。包含该域名的子域名；不要填写网址路径或 https://。无法确认网页地址时不会发送。")
                        .font(.caption).foregroundStyle(.secondary)
                    if !domainsAreValid {
                        Text("请至少填写一个有效的域名。")
                            .font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                if model.preferences.rules.contains(where: { $0.id == rule.id }) {
                    Button("移除", role: .destructive) { model.remove(rule) }
                }
                Spacer()
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("保存") { model.save(rule) }
                    .keyboardShortcut(.defaultAction).disabled(!domainsAreValid)
            }
        }
        .padding(24).frame(width: 500, height: rule.needsDomainCheck ? 550 : 390)
    }
}

private struct PreviewView: View {
    let configuredKeyword: String
    @State private var example = "帮我检查这个页面，Bingo。"
    @State private var keyword = "Bingo"
    @State private var result: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("先试试你的说法").font(.title3.weight(.semibold))
            Text("这里仅预览将原样发送的完整正文，包含口令，不会向任何应用发送。")
                .foregroundStyle(.secondary)
            TextField("测试口令", text: $keyword)
            TextEditor(text: $example)
                .font(.body).padding(8)
                .frame(minHeight: 110, maxHeight: 170)
                .background(.background)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .accessibilityLabel("测试正文，可以用豆包输入法输入")
            Button("检查口令") {
                result = TriggerMatcher.match(text: example, keyword: keyword) != nil
                    ? example : "未匹配：请在有正文的内容末尾添加完整口令。"
            }
            .buttonStyle(.borderedProminent)
            if let result {
                Text("完整待发送正文").font(.headline)
                Text(result).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text("Bingo 会随正文一起发送。实际读取输入框与发送按键，请在设置中的「只检测，不发送」模式验证。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .onAppear { keyword = configuredKeyword }
    }
}

private struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("保留你的输入法").font(.title3.weight(.semibold))
                Text("豆包或其他输入法继续负责语音转文字。Bingo Send 只检查允许范围内的当前输入框，检测到口令后原样发送完整正文，不录音、不联网、不保存正文。")
                Text("第一次使用").font(.headline)
                Text("1. 在设置中点击「去授权」，在系统辅助功能列表开启 Bingo Send。\n\n2. 启用目标应用，确认它的发送按键。网页应用请添加所用浏览器，并设置允许的网站域名。\n\n3. 保持「只检测，不发送」，打开总开关，再切到目标输入框输入一条新内容，例如「你好，Bingo」。提示音和底部记录表示检测成功。\n\n4. 回来关闭「只检测」，再输入一条无关紧要的新内容，确认目标应用实际发送成功。")
                Text("兼容范围").font(.headline)
                Text("原生应用、Electron 应用、浏览器网页都可以添加，但控件必须公开输入框文本和光标位置。WorkBuddy、DeepSeek、Hugging Face 等需要逐个验证，加入名单不等于已经验证兼容。")
                Text("输入法与发送").font(.headline)
                Text("需等文字写入目标输入框，光标位于正文末尾且没有选中文字。文字稳定等待可减少增量转写时的提前触发，但无法替输入法确认录音已经结束。它不会替豆包按下「结束录音」。\n\n触发时直接发出发送按键，完整正文与 Bingo 保持原样。发送按键发出后，目标应用仍可能因网络、按钮状态或快捷键配置而未发送，请以目标应用结果为准。")
                Text("随时暂停").font(.headline)
                Text("点菜单栏的纸飞机图标即可暂停。每次重新启动都从暂停状态开始。关闭窗口后工具仍在菜单栏，选择「退出 Bingo Send」才会完全停止。")
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }
    }
}
