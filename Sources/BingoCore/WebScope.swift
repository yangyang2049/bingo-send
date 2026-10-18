import Foundation

public enum WebScope {
    /// Match the parsed HTTP(S) host, never text from a URL's path, query, or
    /// user information. Entries in hosts must be plain ASCII domain names.
    public static func allows(_ url: URL?, hosts: [String]) -> Bool {
        guard let url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let rawHost = url.host,
              let pageHost = normalizedDomain(rawHost) else { return false }

        return hosts.contains { entry in
            guard let allowedHost = normalizedDomain(entry) else { return false }
            return pageHost == allowedHost || pageHost.hasSuffix("." + allowedHost)
        }
    }

    private static func normalizedDomain(_ value: String) -> String? {
        var domain = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // A fully qualified DNS name can have one root-label dot at its end.
        if domain.hasSuffix(".") { domain.removeLast() }
        guard !domain.isEmpty, domain.utf8.count <= 253 else { return nil }

        let labels = domain.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2, labels.allSatisfy({ label in
            !label.isEmpty && label.utf8.count <= 63
                && !label.hasPrefix("-") && !label.hasSuffix("-")
                && label.unicodeScalars.allSatisfy { scalar in
                    switch scalar.value {
                    case 45, 48...57, 97...122:
                        return true
                    default:
                        return false
                    }
                }
        }) else { return nil }
        return domain
    }
}
