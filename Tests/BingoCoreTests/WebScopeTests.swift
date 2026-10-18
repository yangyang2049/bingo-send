import Foundation
import XCTest
@testable import BingoCore

final class WebScopeTests: XCTestCase {
    func testExactHostAndRealSubdomainsAreAllowed() {
        XCTAssertTrue(WebScope.allows(URL(string: "https://chat.deepseek.com/"), hosts: ["chat.deepseek.com"]))
        XCTAssertTrue(WebScope.allows(URL(string: "http://huggingface.co/chat"), hosts: ["huggingface.co"]))
        XCTAssertTrue(WebScope.allows(URL(string: "https://chat.huggingface.co/"), hosts: ["huggingface.co"]))
        XCTAssertTrue(WebScope.allows(URL(string: "https://a.b.huggingface.co:443/"), hosts: ["huggingface.co"]))
    }

    func testCaseWhitespaceAndOneFinalDNSDotAreNormalized() {
        XCTAssertTrue(WebScope.allows(URL(string: "https://CHAT.DEEPSEEK.COM/"), hosts: ["  Chat.DeepSeek.Com.\n"]))
        XCTAssertTrue(WebScope.allows(URL(string: "https://chat.deepseek.com./"), hosts: ["chat.deepseek.com"]))
    }

    func testSuffixImpersonationAndParentDomainAreRejected() {
        let hosts = ["chat.deepseek.com"]
        for address in [
            "https://evilchat.deepseek.com/",
            "https://chat.deepseek.com.evil.com/",
            "https://evil-chat.deepseek.com/",
            "https://deepseek.com/"
        ] {
            XCTAssertFalse(WebScope.allows(URL(string: address), hosts: hosts), address)
        }
    }

    func testAllowedDomainInQueryPathOrUserInformationDoesNotGrantAccess() {
        let hosts = ["chat.deepseek.com"]
        for address in [
            "https://evil.com/?next=https://chat.deepseek.com/",
            "https://evil.com/chat.deepseek.com/",
            "https://chat.deepseek.com@evil.com/",
            "https://user:chat.deepseek.com@evil.com/"
        ] {
            XCTAssertFalse(WebScope.allows(URL(string: address), hosts: hosts), address)
        }
    }

    func testNonWebSchemesMissingURLAndRelativeURLAreRejected() {
        let hosts = ["chat.deepseek.com"]
        for address in [
            "file://chat.deepseek.com/tmp/index.html",
            "javascript://chat.deepseek.com/alert(1)",
            "ftp://chat.deepseek.com/file",
            "//chat.deepseek.com/",
            "/chat.deepseek.com"
        ] {
            XCTAssertFalse(WebScope.allows(URL(string: address), hosts: hosts), address)
        }
        XCTAssertFalse(WebScope.allows(nil, hosts: hosts))
    }

    func testEmptyOrInvalidAllowedDomainsNeverGrantAccess() {
        let url = URL(string: "https://chat.deepseek.com/")
        XCTAssertFalse(WebScope.allows(url, hosts: []))
        for invalid in [
            "", "  \n", ".", "com", "https://chat.deepseek.com", "chat.deepseek.com/path",
            "user@chat.deepseek.com", "*.deepseek.com", ".chat.deepseek.com", "chat..deepseek.com",
            "-chat.deepseek.com", "chat-.deepseek.com", "chat.deepseek.com..",
            "chat .deepseek.com", "chat.deepseek.com:443", "chat_deepseek.com", "例子.com"
        ] {
            XCTAssertFalse(WebScope.allows(url, hosts: [invalid]), invalid)
        }
    }

    func testASCIIHyphenAndDigitLabelsAreSupported() {
        XCTAssertTrue(WebScope.allows(URL(string: "https://chat-2.example-ai.com/"), hosts: ["example-ai.com"]))
        XCTAssertFalse(WebScope.allows(URL(string: "https://chat-2.example-ai.com/"), hosts: ["example.com"]))
    }
}
