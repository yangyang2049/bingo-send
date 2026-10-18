// Offline SVG rasterization at an explicit viewport. No Bingo Send app launch.
import AppKit
import WebKit

let args = CommandLine.arguments
if args.count != 3 { fatalError("Usage: swift render-marketing-svg.swift input.svg output.png") }
let source = try String(contentsOfFile: args[1], encoding: .utf8)
let destination = URL(fileURLWithPath: args[2])
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1280, height: 640))
let window = NSWindow(contentRect: webView.frame, styleMask: .borderless, backing: .buffered, defer: false)
window.isReleasedWhenClosed = false
window.contentView = webView
final class Renderer: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let config = WKSnapshotConfiguration()
            config.rect = NSRect(x: 0, y: 0, width: 1280, height: 640)
            config.snapshotWidth = 1280
            webView.takeSnapshot(with: config) { image, error in
                guard let image = image, error == nil else { fputs("Snapshot failed: \(String(describing: error))\n", stderr); exit(1) }
                var rect = NSRect(origin: .zero, size: image.size)
                guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil),
                      let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { exit(1) }
                do { try data.write(to: destination) } catch { fputs("\(error)\n", stderr); exit(1) }
                exit(0)
            }
        }
    }
}
let renderer = Renderer()
webView.navigationDelegate = renderer
webView.loadHTMLString("<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=1280, initial-scale=1'></head><body style='margin:0;padding:0;width:1280px;height:640px;overflow:hidden'>\(source)</body></html>", baseURL: nil)
DispatchQueue.main.asyncAfter(deadline: .now() + 15) { fputs("Snapshot timeout\n", stderr); exit(1) }
app.run()
