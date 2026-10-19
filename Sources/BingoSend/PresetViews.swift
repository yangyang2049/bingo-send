import AppKit
import SwiftUI
import BingoCore

struct AgentCatalogView: View {
    @ObservedObject var model: AppModel
    @State private var search = ""
    @State private var webPreset: AgentPreset?
    @State private var addedMessage: String?
    @State private var installed: [String: [InstalledApplication]] = [:]

    private var filtered: [AgentPreset] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return AgentCatalog.presets.filter { preset in
            query.isEmpty || (preset.name + " " + preset.detailEn + " " + preset.detailZh)
                .localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(zh: "选择常用 AI 或编程助手", en: "Choose an AI or coding assistant"))
                .font(.title3.weight(.semibold))
            Text(L10n.text(zh: "预设帮助填写应用和网站范围。添加后请先用「只检测，不发送」逐项试用。",
                           en: "Presets help configure app and website scope. Test each setup in detect-only mode first."))
                .font(.callout).foregroundStyle(.secondary)
            TextField(L10n.text(zh: "搜索名称，例如 Claude、Kimi", en: "Search by name, such as Claude or Kimi"),
                      text: $search)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(L10n.text(zh: "搜索应用预设", en: "Search app presets"))
            if let addedMessage {
                Label(addedMessage, systemImage: "checkmark.circle")
                    .font(.callout).foregroundStyle(.teal)
                    .accessibilityLabel(addedMessage)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filtered) { preset in
                        row(preset)
                        Divider()
                    }
                    if filtered.isEmpty {
                        Text(L10n.text(zh: "没有找到预设，仍可手动添加应用。",
                                       en: "No matching preset. You can still add an app manually."))
                            .foregroundStyle(.secondary).padding(.vertical, 24)
                    }
                }
            }
            HStack {
                Button { model.addApplication() } label: {
                    Label(L10n.text(zh: "手动添加其他应用…", en: "Add another app manually…"), systemImage: "plus")
                }
                Spacer()
                Text(L10n.text(zh: "每个应用仍需单独确认发送按键。", en: "Check the send shortcut for each app."))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .onAppear {
            installed = Dictionary(uniqueKeysWithValues: AgentCatalog.presets.map {
                ($0.id, model.installedApplications(for: $0))
            })
        }
        .sheet(item: $webPreset) { preset in
            WebPresetSheet(model: model, preset: preset) { browser in
                addedMessage = L10n.text(zh: "已添加到 \(browser.name)，请到设置中先检测再发送。",
                                         en: "Added to \(browser.name). Test detection in Settings before sending.")
            }
        }
    }

    private func row(_ preset: AgentPreset) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name).font(.body.weight(.medium))
                Text(L10n.text(zh: preset.detailZh, en: preset.detailEn))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let apps = installed[preset.id], !apps.isEmpty {
                    let names = apps.map(\.name).joined(separator: L10n.text(zh: "、", en: ", "))
                    Text(L10n.text(zh: "已找到桌面应用：\(names)", en: "Installed desktop app: \(names)"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Menu(L10n.text(zh: "添加…", en: "Add…")) {
                ForEach(installed[preset.id] ?? []) { application in
                    Button(L10n.text(zh: "桌面 · \(application.name)", en: "Desktop · \(application.name)")) {
                        model.configureNativePreset(preset, application: application)
                    }
                }
                if !preset.webHosts.isEmpty {
                    Button(L10n.text(zh: "网页版 · 选择浏览器…", en: "Web · choose browser…")) { webPreset = preset }
                }
                Divider()
                Button(L10n.text(zh: "手动选择桌面应用…", en: "Choose desktop app manually…")) { model.addApplication() }
            }
            .fixedSize()
            .accessibilityLabel(L10n.text(zh: "添加 \(preset.name) 预设", en: "Add \(preset.name) preset"))
        }
        .padding(.vertical, 12)
    }
}

private struct WebPresetSheet: View {
    @ObservedObject var model: AppModel
    let preset: AgentPreset
    let onAdded: (InstalledApplication) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var browserID = ""
    @State private var shortcut: SendShortcut = .returnKey

    private var browsers: [InstalledApplication] { model.installedBrowsers }
    private var browser: InstalledApplication? { browsers.first { $0.id == browserID } }
    private var existingRule: ApplicationRule? {
        model.preferences.rules.first { $0.bundleIdentifier == browserID }
    }
    private var mergedDomains: String {
        PresetDomains.merging(existing: existingRule?.domainText ?? "", hosts: preset.webHosts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text(zh: "添加 \(preset.name) 网页版", en: "Add \(preset.name) on the web"))
                .font(.title2.weight(.semibold))
            if browsers.isEmpty {
                Text(L10n.text(zh: "未检测到可用浏览器。请先安装浏览器，或在设置中手动添加。",
                               en: "No browser found. Install a browser or add one manually in Settings."))
                    .foregroundStyle(.secondary)
            } else {
                Picker(L10n.text(zh: "使用浏览器", en: "Browser"), selection: $browserID) {
                    ForEach(browsers) { app in Text(app.name).tag(app.id) }
                }
                Picker(L10n.text(zh: "发送按键", en: "Send shortcut"), selection: $shortcut) {
                    ForEach(SendShortcut.allCases, id: \.self) { value in Text(value.title).tag(value) }
                }
                Text(L10n.text(zh: "本次加入的网站", en: "Websites to add")).font(.headline)
                Text(preset.webHosts.joined(separator: "\n"))
                    .font(.body.monospaced()).textSelection(.enabled)
                Text(L10n.text(zh: "添加后的允许范围", en: "Allowed domains after adding")).font(.headline)
                ScrollView {
                    Text(mergedDomains).font(.caption.monospaced()).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 100)
                Text(L10n.text(zh: "保留已有域名，并启用所选浏览器。同一浏览器的这些网站共用发送按键；无法确认当前网页地址时不会发送。",
                               en: "Existing domains are kept and the selected browser is enabled. Its allowed sites share one send shortcut. Sending stops if the page address cannot be verified."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack {
                Button(L10n.text(zh: "取消", en: "Cancel")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(L10n.text(zh: "添加到启用范围", en: "Add to enabled apps")) {
                    guard let browser else { return }
                    model.addWebPreset(preset, browser: browser, shortcut: shortcut)
                    onAdded(browser)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(browser == nil)
            }
        }
        .padding(24).frame(width: 500, height: 430)
        .onAppear {
            browserID = browsers.first(where: { $0.id == "com.google.Chrome" })?.id ?? browsers.first?.id ?? ""
            shortcut = existingRule?.shortcut ?? .returnKey
        }
        .onChange(of: browserID) { _ in shortcut = existingRule?.shortcut ?? .returnKey }
    }
}
