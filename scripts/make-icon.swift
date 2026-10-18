import AppKit

let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let canvas = NSImage(size: NSSize(width: pixels, height: pixels))
        canvas.lockFocus()
        let factor = CGFloat(pixels) / 1024
        let transform = NSAffineTransform()
        transform.scale(by: factor)
        transform.concat()
        NSColor(calibratedRed: 0.07, green: 0.43, blue: 0.42, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 192, yRadius: 192).fill()
        let plane = NSBezierPath()
        plane.move(to: NSPoint(x: 248, y: 520))
        plane.line(to: NSPoint(x: 778, y: 764))
        plane.line(to: NSPoint(x: 586, y: 246))
        plane.line(to: NSPoint(x: 472, y: 438))
        plane.close()
        NSColor.white.setFill()
        plane.fill()
        let crease = NSBezierPath()
        crease.move(to: NSPoint(x: 472, y: 438))
        crease.line(to: NSPoint(x: 778, y: 764))
        crease.lineWidth = 21
        crease.lineCapStyle = .round
        NSColor(calibratedRed: 0.07, green: 0.43, blue: 0.42, alpha: 1).setStroke()
        crease.stroke()
        canvas.unlockFocus()
        var rect = NSRect(origin: .zero, size: canvas.size)
        let cgImage = canvas.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
        let rep = NSBitmapImageRep(cgImage: cgImage)
        let data = rep.representation(using: .png, properties: [:])!
        let suffix = scale == 1 ? "" : "@2x"
        try data.write(to: destination.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
