/// Listening and sending are presented as one mutually exclusive choice.
/// The paused state is session-only; saved preferences never auto-start sending.
public enum RunMode: String, CaseIterable {
    case paused
    case testing
    case automatic

    public init(isEnabled: Bool, detectOnly: Bool) {
        self = !isEnabled ? .paused : (detectOnly ? .testing : .automatic)
    }
}

public enum RunState: Equatable {
    case paused, needsPermission, invalidKeywords, noEnabledApps, testing, automatic

    public static func resolve(mode: RunMode, trusted: Bool, validKeywords: Bool,
                               hasEnabledApps: Bool) -> RunState {
        guard mode != .paused else { return .paused }
        guard trusted else { return .needsPermission }
        guard validKeywords else { return .invalidKeywords }
        guard hasEnabledApps else { return .noEnabledApps }
        return mode == .testing ? .testing : .automatic
    }
}
