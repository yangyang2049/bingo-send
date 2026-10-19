import AppKit
import SwiftUI
import BingoCore

struct AgentCatalogView: View {
    @ObservedObject var model: AppModel
    @State private var search = ""
    @State private var group = "all"
    @State private var webPreset: AgentPreset?
    @State private var addedMessage: String?
    @State private var installed: [String: [InstalledApplication]] = [:]

    private var filtered: [AgentPreset] {
        AgentCatalog.presets.filter { preset in
            (group == "all" || preset.group.rawValue == group) &&
                (search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                 (preset.name + " " + preset.detail).localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择常用 AI 或编程助手").font(.title3.weight(.semibold))
            Text("预设帮助填写应用和网站范围。添加后请先用「只检测，不发送」逐项试用。")
                .font(.callout).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                TextField("搜索名称，例如 Claude、Kimi", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("搜索应用预设")
                Picker("区域", selection: $group) {
                    Text("全部").tag("all")
                    Text("国外").tag(AgentPresetGroup.international.rawValue)
                    Text("国内").tag(AgentPresetGroup.china.rawValue)
                }
                .pickerStyle(.segmented).frame(width: 190)
            }
            if let addedMessage {
                Label(addedMessage, systemImage: "checkmark.circle")
                    .font(.callout).foregroundStyle(.teal)
                    .accessibilityLabel(addedMessage)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(AgentPresetGroup.allCases, id: \.rawValue) { section in
                        let entries = filtered.filter { $0.group == section }
                        if !entries.isEmpty {
                            Text(section == .international ? "国外" : "国内")
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                .padding(.top, 12).padding(.bottom, 6)
                            ForEach(entries) { preset in
                                row(preset)
                                Divider()
                            }
                        }
                    }
                    if filtered.isEmpty {
                        Text("没有找到预设，仍可手动添加应用。")
                            .foregroundStyle(.secondary).padding(.vertical, 24)
                    }
                }
            }
            HStack {
                Button { model.addApplication() } label: {
                    Label("手动添加其他应用…", systemImage: "plus")
                }
                Spacer()
                Text("每个应用仍需单独确认发送按键。")
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
                addedMessage = "已添加到 \(browser.name)，请到设置中先检测再发送。"
            }
        }
    }

    private func row(_ preset: AgentPreset) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name).font(.body.weight(.medium))
                Text(preset.detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let apps = installed[preset.id], !apps.isEmpty {
                    Text("已找到桌面应用：" + apps.map(\.name).joined(separator: "、"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Menu("添加…") {
                ForEach(installed[preset.id] ?? []) { application in
                    Button("桌面 · \(application.name)") {
                        model.configureNativePreset(preset, application: application)
                    }
                }
                if !preset.webHosts.isEmpty {
                    Button("网页版 · 选择浏览器…") { webPreset = preset }
                }
                Divider()
                Button("手动选择桌面应用…") { model.addApplication() }
            }
            .fixedSize()
            .accessibilityLabel("添加 \(preset.name) 预设")
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
            Text("添加 \(preset.name) 网页版").font(.title2.weight(.semibold))
            if browsers.isEmpty {
                Text("未检测到可用浏览器。请先安装浏览器，或在设置中手动添加。")
                    .foregroundStyle(.secondary)
            } else {
                Picker("使用浏览器", selection: $browserID) {
                    ForEach(browsers) { app in Text(app.name).tag(app.id) }
                }
                Picker("发送按键", selection: $shortcut) {
                    ForEach(SendShortcut.allCases, id: \.self) { value in Text(value.title).tag(value) }
                }
                Text("本次加入的网站").font(.headline)
                Text(preset.webHosts.joined(separator: "\n"))
                    .font(.body.monospaced()).textSelection(.enabled)
                Text("添加后的允许范围").font(.headline)
                ScrollView {
                    Text(mergedDomains).font(.caption.monospaced()).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 100)
                Text("保留已有域名，并启用所选浏览器。同一浏览器的这些网站共用发送按键；无法确认当前网页地址时不会发送。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("添加到启用范围") {
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
