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
    case beforeRemoval = "移除口令前"
    case beforeSend = "发送前"
}

enum RemovalTextState: String {
    case original = "原文"
    case expected = "目标正文"
    case unchanged = "原文与目标相同"
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
    case triggerNotMatched
    case triggerRemovalUnsupported
    case selectedText
    case editTimeout(expected: NSRange, actual: NSRange, textState: RemovalTextState)
    case cursor(expected: NSRange, actual: NSRange)
    case axRead(attribute: String, code: Int)
    case axWrite(attribute: String, code: Int)

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
        case .triggerNotMatched: return "句尾口令已无法确认"
        case .triggerRemovalUnsupported: return "此输入框无法安全移除句尾口令，请关闭移除选项后重试"
        case .selectedText: return "选中文字与句尾口令不一致"
        case let .editTimeout(expected, actual, textState):
            return "输入框修改确认超时（期望选区 \(expected.location):\(expected.length)，实际 \(actual.location):\(actual.length)，正文状态：\(textState.rawValue)）"
        case let .cursor(expected, actual):
            return "光标或选区已变化（期望 \(expected.location):\(expected.length)，实际 \(actual.location):\(actual.length)）"
        case let .axRead(attribute, code): return "读取 \(attribute) 失败（AX \(code)）"
        case let .axWrite(attribute, code): return "修改 \(attribute) 失败（AX \(code)）"
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
    case removalInterrupted(cause: String)

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
        case let .removalInterrupted(cause):
            return "\(cause) 草稿或选区可能已被修改；未继续发送，请检查原输入框。"
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

    func currentApplicationIdentity() -> (name: String, bundleIdentifier: String, processID: pid_t)? {
        guard let application = NSWorkspace.shared.frontmostApplication,
              let bundleID = application.bundleIdentifier else { return nil }
        return (application.localizedName ?? bundleID, bundleID, application.processIdentifier)
    }

    func focusedDraft(expectedBundleIdentifier: String, expectedProcessID: pid_t,
                      allowSingleLine: Bool, allowedPageHosts: [String]? = nil) throws -> FocusedDraft {
        guard Self.isTrusted else { throw AccessibilityFailure.permissionRequired }
        let application = try frontmostApplication()
        // The caller chose a rule for this exact process. Reject a foreground
        // switch before looking up or reading the other app's editor.
        guard application.bundleIdentifier == expectedBundleIdentifier,
              application.processIdentifier == expectedProcessID else {
            throw AccessibilityFailure.sendFailure(phase: .start, reason: .foregroundApplication)
        }
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

    /// The default path sends the unchanged draft, including the spoken trigger.
    /// Optional removal modifies only a verified suffix; clipboard and full-draft
    /// replacement are never used. An interrupted removal is never rolled back.
    func sendDraft(_ draft: FocusedDraft, shortcut: SendShortcut,
                   allowedPageHosts: [String]?, removeKeyword: String? = nil) async throws {
        try Task.checkCancellation()
        guard let source = CGEventSource(stateID: .privateState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeSend, reason: .keyboardEventCreation)
        }
        keyDown.flags = shortcut.flags
        keyUp.flags = shortcut.flags
        var mayHaveModifiedDraft = false
        do {
            var expectedText = draft.snapshot.text
            if let keyword = removeKeyword {
                expectedText = try await removeTriggerSuffix(draft, keyword: keyword,
                    source: source, allowedPageHosts: allowedPageHosts,
                    mayHaveModifiedDraft: &mayHaveModifiedDraft)
            }
            try validateCurrentContext(draft, expectedText: expectedText,
                allowedPageHosts: allowedPageHosts, phase: .beforeSend)
            try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts, phase: .beforeSend)
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == draft.processID else {
                throw AccessibilityFailure.sendFailure(phase: .beforeSend, reason: .foregroundApplication)
            }
            try Task.checkCancellation()
            keyDown.postToPid(draft.processID)
            keyUp.postToPid(draft.processID)
        } catch {
            if mayHaveModifiedDraft {
                let cause = error is CancellationError ? "移除口令操作已取消。" : error.localizedDescription
                throw AccessibilityFailure.removalInterrupted(cause: cause)
            }
            throw error
        }
    }

    private func removeTriggerSuffix(_ draft: FocusedDraft, keyword: String,
                                     source: CGEventSource, allowedPageHosts: [String]?,
                                     mayHaveModifiedDraft: inout Bool) async throws -> String {
        let original = draft.snapshot.text
        guard let body = TriggerText.removingSuffix(from: original, keyword: keyword) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .triggerNotMatched)
        }
        let caret = NSRange(location: original.utf16.count, length: 0)
        let suffixRange = NSRange(location: body.utf16.count,
            length: original.utf16.count - body.utf16.count)
        try Task.checkCancellation()
        try validateCurrentContext(draft, expectedText: original,
            allowedPageHosts: allowedPageHosts, phase: .beforeRemoval)

        var needsKeyboardSelection = true
        if try attributeIsSettable(draft.element, kAXSelectedTextRangeAttribute as String) {
            var range = CFRange(location: suffixRange.location, length: suffixRange.length)
            guard let value = AXValueCreate(.cfRange, &range) else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .invalidRangeValue)
            }
            try validateRemovalContext(draft, expectedText: original, expectedRange: caret,
                allowedPageHosts: allowedPageHosts)
            try Task.checkCancellation()
            mayHaveModifiedDraft = true
            do {
                let result = AXUIElementSetAttributeValue(draft.element,
                    kAXSelectedTextRangeAttribute as CFString, value)
                try requireAXWrite(result, attribute: kAXSelectedTextRangeAttribute as String)
                try await waitForRemovalState(draft, previousText: original, previousRange: caret,
                    expectedText: original, expectedRange: suffixRange, allowedPageHosts: allowedPageHosts)
                needsKeyboardSelection = false
            } catch {
                guard permitsKeyboardSelectionFallback(after: error) else { throw error }
                // Some editors claim the AX setter succeeded but ignore it.
                // Retry only while the exact untouched original caret remains.
                try validateRemovalContext(draft, expectedText: original, expectedRange: caret,
                    allowedPageHosts: allowedPageHosts)
                try Task.checkCancellation()
            }
        }
        if needsKeyboardSelection {
            try await selectSuffixWithKeyboard(draft, original: original, suffixRange: suffixRange,
                source: source, allowedPageHosts: allowedPageHosts,
                mayHaveModifiedDraft: &mayHaveModifiedDraft)
        }

        // Some editors report successful AXSelectedText writes without applying
        // them. Delete the verified selection with one targeted key pair only;
        // never issue a second deletion after a timeout or delayed readback.
        let deletionEvents = try keyboardEvents(source: source, key: 51, flags: [])
        try validateRemovalContext(draft, expectedText: original, expectedRange: suffixRange,
            allowedPageHosts: allowedPageHosts)
        try Task.checkCancellation()
        mayHaveModifiedDraft = true
        deletionEvents.0.postToPid(draft.processID)
        deletionEvents.1.postToPid(draft.processID)
        try await waitForRemovalState(draft, previousText: original, previousRange: suffixRange,
            expectedText: body, expectedRange: NSRange(location: body.utf16.count, length: 0),
            allowedPageHosts: allowedPageHosts)
        try Task.checkCancellation()
        return body
    }

    private func permitsKeyboardSelectionFallback(after error: Error) -> Bool {
        guard let failure = error as? AccessibilityFailure,
              case let .sendFailure(_, reason) = failure else { return false }
        switch reason {
        case .editTimeout:
            return true
        case let .axWrite(attribute, code):
            return attribute == kAXSelectedTextRangeAttribute as String
                && [AXError.attributeUnsupported, .notImplemented].contains { Int($0.rawValue) == code }
        default:
            return false
        }
    }

    private func selectSuffixWithKeyboard(_ draft: FocusedDraft, original: String, suffixRange: NSRange,
                                          source: CGEventSource, allowedPageHosts: [String]?,
                                          mayHaveModifiedDraft: inout Bool) async throws {
        // Read-only AX editors may still expose exact selection ranges. Move
        // one grapheme at a time and confirm every resulting UTF-16 range.
        guard let suffix = Range(suffixRange, in: original),
              original.indices.contains(suffix.lowerBound), original[suffix].count <= 64 else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .triggerRemovalUnsupported)
        }
        var start = original.endIndex
        var previousRange = NSRange(location: original.utf16.count, length: 0)
        try validateRemovalContext(draft, expectedText: original, expectedRange: previousRange,
            allowedPageHosts: allowedPageHosts)
        while start > suffix.lowerBound {
            let next = original.index(before: start)
            guard next >= suffix.lowerBound else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .triggerRemovalUnsupported)
            }
            let nextRange = NSRange(next..<original.endIndex, in: original)
            let events = try keyboardEvents(source: source, key: 123, flags: .maskShift)
            try validateRemovalContext(draft, expectedText: original, expectedRange: previousRange,
                allowedPageHosts: allowedPageHosts)
            try Task.checkCancellation()
            mayHaveModifiedDraft = true
            events.0.postToPid(draft.processID)
            events.1.postToPid(draft.processID)
            try await waitForRemovalState(draft, previousText: original, previousRange: previousRange,
                expectedText: original, expectedRange: nextRange, allowedPageHosts: allowedPageHosts)
            start = next
            previousRange = nextRange
        }
    }

    private func keyboardEvents(source: CGEventSource, key: CGKeyCode,
                                flags: CGEventFlags) throws -> (CGEvent, CGEvent) {
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .keyboardEventCreation)
        }
        down.flags = flags
        up.flags = flags
        return (down, up)
    }

    private func attributeIsSettable(_ element: AXUIElement, _ attribute: String) throws -> Bool {
        var settable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        if result == .attributeUnsupported || result == .notImplemented { return false }
        guard result == .success else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                reason: .axRead(attribute: attribute, code: Int(result.rawValue)))
        }
        return settable.boolValue
    }

    private func requireAXWrite(_ result: AXError, attribute: String) throws {
        guard result == .success else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                reason: .axWrite(attribute: attribute, code: Int(result.rawValue)))
        }
    }

    private func removalState(_ draft: FocusedDraft, allowedPageHosts: [String]?) throws -> (String, NSRange) {
        try Task.checkCancellation()
        try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts, phase: .beforeRemoval)
        do {
            _ = try validateTextControl(draft.element, allowSingleLine: draft.role == kAXTextFieldRole as String)
        } catch {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .controlUnavailable)
        }
        let text = try textForSend(draft.element, phase: .beforeRemoval)
        let range = try selectedRangeForSend(draft.element, phase: .beforeRemoval)
        try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts, phase: .beforeRemoval)
        return (text, NSRange(location: range.location, length: range.length))
    }

    private func validateRemovalContext(_ draft: FocusedDraft, expectedText: String,
                                        expectedRange: NSRange, allowedPageHosts: [String]?) throws {
        let (text, range) = try removalState(draft, allowedPageHosts: allowedPageHosts)
        guard sameText(text, expectedText) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .text)
        }
        guard range == expectedRange else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                reason: .cursor(expected: expectedRange, actual: range))
        }
        if range.length > 0 {
            var selected: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(draft.element, kAXSelectedTextAttribute as CFString, &selected)
            if result == .success {
                guard let selected = selected as? String,
                      sameText(selected, (expectedText as NSString).substring(with: expectedRange)) else {
                    throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .selectedText)
                }
            } else if result != .attributeUnsupported && result != .noValue && result != .notImplemented {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                    reason: .axRead(attribute: kAXSelectedTextAttribute as String, code: Int(result.rawValue)))
            }
        }
        // Recheck the full draft after reading the selection, before mutation.
        guard sameText(try textForSend(draft.element, phase: .beforeRemoval), expectedText) else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .text)
        }
        let finalRange = try selectedRangeForSend(draft.element, phase: .beforeRemoval)
        let finalSelection = NSRange(location: finalRange.location, length: finalRange.length)
        guard finalSelection == expectedRange else {
            throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                reason: .cursor(expected: expectedRange, actual: finalSelection))
        }
        try validateFocusAndPage(draft, allowedPageHosts: allowedPageHosts, phase: .beforeRemoval)
    }

    private func waitForRemovalState(_ draft: FocusedDraft, previousText: String, previousRange: NSRange,
                                    expectedText: String, expectedRange: NSRange,
                                    allowedPageHosts: [String]?) async throws {
        let deadline = ProcessInfo.processInfo.systemUptime + 0.25
        var lastRange = previousRange
        var lastTextState: RemovalTextState = .original
        for attempt in 0..<12 {
            let (text, range) = try removalState(draft, allowedPageHosts: allowedPageHosts)
            if sameText(text, expectedText), range == expectedRange {
                try validateRemovalContext(draft, expectedText: expectedText, expectedRange: expectedRange,
                    allowedPageHosts: allowedPageHosts)
                return
            }
            // AX value and selection are separate IPC reads; a single edit can
            // expose either old/new combination briefly. Wait without posting
            // more input, and accept only the complete expected state above.
            guard sameText(text, previousText) || sameText(text, expectedText) else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval, reason: .text)
            }
            guard range == previousRange || range == expectedRange else {
                throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
                    reason: .cursor(expected: expectedRange, actual: range))
            }
            lastRange = range
            lastTextState = sameText(text, expectedText)
                ? (sameText(text, previousText) ? .unchanged : .expected) : .original
            guard attempt < 11, ProcessInfo.processInfo.systemUptime < deadline else { break }
            try await Task.sleep(nanoseconds: 15_000_000)
        }
        throw AccessibilityFailure.sendFailure(phase: .beforeRemoval,
            reason: .editTimeout(expected: expectedRange, actual: lastRange, textState: lastTextState))
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
