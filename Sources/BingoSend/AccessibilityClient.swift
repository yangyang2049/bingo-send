import Foundation
import AppKit
import ApplicationServices
import CoreGraphics
import BingoCore

enum SendShortcut: String, CaseIterable, Codable {
    case returnKey
    case commandReturn
    case controlReturn

    var title: String {
        switch self {
        case .returnKey: return "Return"
        case .commandReturn: return "⌘ Return"
        case .controlReturn: return "⌃ Return"
        }
    }

    fileprivate var flags: CGEventFlags {
        switch self {
        case .returnKey: return []
        case .commandReturn: return .maskCommand
        case .controlReturn: return .maskControl
        }
    }
}

struct FocusedDraft {
    let element: AXUIElement
    let processID: pid_t
    let bundleIdentifier: String
    let role: String
    let snapshot: DraftSnapshot
    let pageURL: URL?
}

enum SendPhase: String {
    case start = "开始"
    case beforeSend = "发送前"
}

/// These diagnostics contain fixed labels, numeric ranges and AX error codes.
/// Draft text, element identifiers, window titles and URLs are never logged.
enum SendFailureReason {
    case permission
    case foregroundApplication
    case focus
    case focusProcess
    case page
    case text
    case controlUnavailable
    case unsupportedTextValue
    case invalidRangeValue
    case keyboardEventCreation
    case cursor(expected: NSRange, actual: NSRange)
    case axRead(attribute: String, code: Int)

    var message: String {
        switch self {
        case .permission: return "辅助功能授权已失效"
        case .foregroundApplication: return "前台应用已变化"
        case .focus: return "输入框焦点已变化"
        case .focusProcess: return "输入框所属进程已变化"
        case .page: return "网页地址已变化或无法确认"
        case .text: return "输入框正文已变化"
        case .controlUnavailable: return "输入框已不可用"
        case .unsupportedTextValue: return "AXValue 未返回纯文本"
        case .invalidRangeValue: return "AXSelectedTextRange 未返回有效范围"
        case .keyboardEventCreation: return "无法创建发送按键"
        case let .cursor(expected, actual):
            return "光标或选区已变化（期望 \(expected.location):\(expected.length)，实际 \(actual.location):\(actual.length)）"
        case let .axRead(attribute, code): return "读取 \(attribute) 失败（AX \(code)）"
        }
    }
}

enum AccessibilityFailure: LocalizedError {
    case permissionRequired
    case noApplication
    case ownApplication
    case noTextField
    case unsupportedField
    case protectedField
    case disabledField
    case readOnlyField
    case textUnavailable
    case selectionUnavailable
    case cursorNotAtEnd
    case pageNotAllowed
    case sendFailure(phase: SendPhase, reason: SendFailureReason)

    var errorDescription: String? {
        switch self {
        case .permissionRequired: return "请在系统设置中允许 Bingo Send 使用辅助功能。"
        case .noApplication: return "没有可用的前台应用。"
        case .ownApplication: return "请切换到要输入消息的应用。"
        case .noTextField: return "请先把光标放进消息输入框。"
        case .unsupportedField: return "当前控件不是已允许的文本输入框。"
        case .protectedField: return "密码或受保护的输入框不会被处理。"
        case .disabledField: return "当前输入框不可用。"
        case .readOnlyField: return "当前输入框为只读。"
        case .textUnavailable: return "当前输入框没有公开可读取的文字。"
        case .selectionUnavailable: return "当前输入框没有公开光标位置。"
        case .cursorNotAtEnd: return "请把光标移到文字末尾，并取消文字选择。"
        case .pageNotAllowed: return "当前网页不在允许的域名内，或无法确认网页地址。"
        case let .sendFailure(phase, reason): return "\(phase.rawValue)：\(reason.message)，已停止发送。"
        }
    }
}

/// Reads only the focused text control in an explicitly enabled frontmost app.
/// The caller checks its app allowlist before invoking `focusedDraft`.
@MainActor
final class AccessibilityClient {
    private let messagingTimeout: Float = 0.15
    private var lastElement: AXUIElement?
    private var lastProcessID: pid_t?
    private var lastTargetID = ""

    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func currentApplicationIdentity() -> (name: String, bundleIdentifier: String)? {
        guard let application = NSWorkspace.shared.frontmostApplication,
              let bundleID = application.bundleIdentifier else { return nil }
        return (application.localizedName ?? bundleID, bundleID)
    }

    func focusedDraft(allowSingleLine: Bool, allowedPageHosts: [String]? = nil) throws -> FocusedDraft {
        guard Self.isTrusted else { throw AccessibilityFailure.permissionRequired }
        let application = try frontmostApplication()
        let pid = application.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        setTimeout(appElement)
        guard let element = elementAttribute(appElement, kAXFocusedUIElementAttribute as String) else {
            throw AccessibilityFailure.noTextField
        }
        setTimeout(element)
        var elementPID: pid_t = 0
        guard AXUIElementGetPid(element, &elementPID) == .success, elementPID == pid else {
            throw AccessibilityFailure.noTextField
        }
        let role = try validateTextControl(element, allowSingleLine: allowSingleLine)

        // Resolve and validate the web scope before reading any draft text.
        let pageURL = ancestorPageURL(element)
        if let hosts = allowedPageHosts, !Self.hostIsAllowed(pageURL, hosts: hosts) {
            throw AccessibilityFailure.pageNotAllowed
        }
        guard let text = attribute(element, kAXValueAttribute as String) as? String else {
            throw AccessibilityFailure.textUnavailable
        }
        let range = try selectedRange(element)
        guard range.location == text.utf16.count, range.length == 0 else {
            throw AccessibilityFailure.cursorNotAtEnd
        }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else {
            throw AccessibilityFailure.sendFailure(phase: .start, reason: .foregroundApplication)
        }

        let draft = FocusedDraft(element: element, processID: pid,
            bundleIdentifier: application.bundleIdentifier!, role: role,
            snapshot: DraftSnapshot(targetID: targetID(for: element, pid: pid) + ":" + (pageURL?.absoluteString ?? ""),
                text: text, caretAtEnd: true), pageURL: pageURL)
        try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts)
        return draft
    }

    static func hostIsAllowed(_ url: URL?, hosts: [String]) -> Bool {
        WebScope.allows(url, hosts: hosts)
    }

    /// Sends the unchanged draft, including the spoken trigger word.
    /// No selection, text, clipboard or deletion operation is performed.
    func sendDraft(_ draft: FocusedDraft, shortcut: SendShortcut,
                   allowedPageHosts: [String]?) async throws {
        try Task.checkCancellation()
        guard let source = CGEventSource(stateID: .privateState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeSend, reason: .keyboardEventCreation)
        }
        keyDown.flags = shortcut.flags
        keyUp.flags = shortcut.flags
        try validateCurrentContext(draft, expectedText: draft.snapshot.text,
            allowedPageHosts: allowedPageHosts, phase: .beforeSend)
        try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts, phase: .beforeSend)
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == draft.processID else {
            throw AccessibilityFailure.sendFailure(phase: .beforeSend, reason: .foregroundApplication)
        }
        try Task.checkCancellation()
        keyDown.postToPid(draft.processID)
        keyUp.postToPid(draft.processID)
    }

    private func frontmostApplication() throws -> NSRunningApplication {
        guard let application = NSWorkspace.shared.frontmostApplication,
              application.bundleIdentifier != nil else { throw AccessibilityFailure.noApplication }
        guard application.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              application.bundleIdentifier != Bundle.main.bundleIdentifier else {
            throw AccessibilityFailure.ownApplication
        }
        return application
    }

    private func validateTextControl(_ element: AXUIElement, allowSingleLine: Bool) throws -> String {
        guard let role = attribute(element, kAXRoleAttribute as String) as? String else {
            throw AccessibilityFailure.unsupportedField
        }
        let subrole = attribute(element, kAXSubroleAttribute as String) as? String
        guard subrole != kAXSecureTextFieldSubrole as String,
              boolAttribute(element, "AXProtectedContent") != true else {
            throw AccessibilityFailure.protectedField
        }
        guard role == kAXTextAreaRole as String || (allowSingleLine && role == kAXTextFieldRole as String) else {
            throw AccessibilityFailure.unsupportedField
        }
        guard boolAttribute(element, kAXEnabledAttribute as String) != false else {
            throw AccessibilityFailure.disabledField
        }
        guard boolAttribute(element, "AXReadOnly") != true,
              boolAttribute(element, "AXEditable") != false else {
            throw AccessibilityFailure.readOnlyField
        }
        return role
    }

    private func validateCurrentContext(_ draft: FocusedDraft, expectedText: String,
                                        allowedPageHosts: [String]?, phase: SendPhase) throws {
        try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts, phase: phase)
        do {
            _ = try validateTextControl(draft.element, allowSingleLine: draft.role == kAXTextFieldRole as String)
        } catch {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .controlUnavailable)
        }
        let currentText = try textForSend(draft.element, phase: phase)
        guard sameText(currentText, expectedText) else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .text)
        }
        let range = try selectedRangeForSend(draft.element, phase: phase)
        guard range.location == expectedText.utf16.count, range.length == 0 else {
            throw AccessibilityFailure.sendFailure(phase: phase,
                reason: .cursor(expected: NSRange(location: expectedText.utf16.count, length: 0),
                    actual: NSRange(location: range.location, length: range.length)))
        }
    }

    private func validateFocusAndPage(_ draft: FocusedDraft, allowedPageHosts: [String]?,
                                       phase: SendPhase = .start) throws {
        guard Self.isTrusted else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .permission)
        }
        guard let application = NSWorkspace.shared.frontmostApplication,
              application.processIdentifier == draft.processID,
              application.bundleIdentifier == draft.bundleIdentifier else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .foregroundApplication)
        }
        let appElement = AXUIElementCreateApplication(draft.processID)
        setTimeout(appElement)
        let focusedValue = try attributeForSend(appElement,
            kAXFocusedUIElementAttribute as String, phase: phase)
        guard CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .focus)
        }
        let currentElement = unsafeBitCast(focusedValue, to: AXUIElement.self)
        guard CFEqual(currentElement, draft.element) else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .focus)
        }
        var elementPID: pid_t = 0
        let pidResult = AXUIElementGetPid(currentElement, &elementPID)
        guard pidResult == .success else {
            throw AccessibilityFailure.sendFailure(phase: phase,
                reason: .axRead(attribute: "AXPID", code: Int(pidResult.rawValue)))
        }
        guard elementPID == draft.processID else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .focusProcess)
        }
        let currentURL = ancestorPageURL(currentElement)
        guard currentURL?.absoluteString == draft.pageURL?.absoluteString else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .page)
        }
        if let hosts = allowedPageHosts, !Self.hostIsAllowed(currentURL, hosts: hosts) {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .page)
        }
    }

    private func attributeForSend(_ element: AXUIElement, _ name: String,
                                   phase: SendPhase) throws -> CFTypeRef {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        guard result == .success, let value else {
            let code = result == .success ? AXError.noValue.rawValue : result.rawValue
            throw AccessibilityFailure.sendFailure(phase: phase,
                reason: .axRead(attribute: name, code: Int(code)))
        }
        return value
    }

    private func textForSend(_ element: AXUIElement, phase: SendPhase) throws -> String {
        let value = try attributeForSend(element, kAXValueAttribute as String, phase: phase)
        guard let text = value as? String else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .unsupportedTextValue)
        }
        return text
    }

    private func sameText(_ lhs: String, _ rhs: String) -> Bool {
        // Ranges are UTF-16 offsets, so canonically equivalent spellings with
        // different UTF-16 lengths must still count as a changed draft.
        lhs.utf16.elementsEqual(rhs.utf16)
    }

    private func selectedRangeForSend(_ element: AXUIElement, phase: SendPhase) throws -> CFRange {
        let value = try attributeForSend(element, kAXSelectedTextRangeAttribute as String, phase: phase)
        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .invalidRangeValue)
        }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        var range = CFRange()
        guard AXValueGetType(axValue) == .cfRange, AXValueGetValue(axValue, .cfRange, &range),
              range.location >= 0, range.length >= 0 else {
            throw AccessibilityFailure.sendFailure(phase: phase, reason: .invalidRangeValue)
        }
        return range
    }

    private func selectedRange(_ element: AXUIElement) throws -> CFRange {
        guard let value = attribute(element, kAXSelectedTextRangeAttribute as String),
              CFGetTypeID(value) == AXValueGetTypeID() else { throw AccessibilityFailure.selectionUnavailable }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        var range = CFRange()
        guard AXValueGetType(axValue) == .cfRange, AXValueGetValue(axValue, .cfRange, &range),
              range.location >= 0, range.length >= 0 else { throw AccessibilityFailure.selectionUnavailable }
        return range
    }

    private func targetID(for element: AXUIElement, pid: pid_t) -> String {
        if lastProcessID == pid, let previous = lastElement, CFEqual(previous, element) {
            return lastTargetID
        }
        lastElement = element
        lastProcessID = pid
        lastTargetID = "\(pid):\(UUID().uuidString)"
        return lastTargetID
    }

    private func ancestorPageURL(_ element: AXUIElement) -> URL? {
        var current: AXUIElement? = element
        var visited: [AXUIElement] = []
        for _ in 0..<24 {
            guard let candidate = current,
                  !visited.contains(where: { CFEqual($0, candidate) }) else { break }
            visited.append(candidate)
            setTimeout(candidate)
            let role = attribute(candidate, kAXRoleAttribute as String) as? String
            if role == "AXWebArea" || role == kAXWindowRole as String {
                for name in ["AXURL", kAXDocumentAttribute as String] {
                    if let value = attribute(candidate, name), let url = httpURL(value) { return url }
                }
            }
            if role == kAXWindowRole as String { break }
            current = elementAttribute(candidate, kAXParentAttribute as String)
        }
        return nil
    }

    private func httpURL(_ value: CFTypeRef) -> URL? {
        let url: URL?
        if let string = value as? String {
            url = URL(string: string)
        } else if CFGetTypeID(value) == CFURLGetTypeID() {
            url = value as? URL
        } else {
            url = nil
        }
        guard let url, let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), url.host != nil else { return nil }
        return url
    }

    private func setTimeout(_ element: AXUIElement) {
        _ = AXUIElementSetMessagingTimeout(element, messagingTimeout)
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func elementAttribute(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func boolAttribute(_ element: AXUIElement, _ name: String) -> Bool? {
        (attribute(element, name) as? NSNumber)?.boolValue
    }

}
