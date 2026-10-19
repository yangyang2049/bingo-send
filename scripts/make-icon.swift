import AppKit

struct IconVariant {
    let size: Int
    let scale: Int

    var pixels: Int { size * scale }
    var filename: String { "icon_\(size)x\(size)\(scale == 1 ? "" : "@2x").png" }
}

enum IconError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self { case .invalid(let message): return message }
    }
}

let variants = [16, 32, 128, 256, 512].flatMap { size in
    [1, 2].map { IconVariant(size: size, scale: $0) }
}

func validateIconset(at directory: URL) throws {
    let pngs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "png" }
    guard Set(pngs.map(\.lastPathComponent)) == Set(variants.map(\.filename)) else {
        throw IconError.invalid("Iconset must contain all 10 standard macOS icon variants: \(directory.path)")
    }
    for variant in variants {
        let url = directory.appendingPathComponent(variant.filename)
        let data = try Data(contentsOf: url)
        guard let image = NSBitmapImageRep(data: data),
              image.pixelsWide == variant.pixels, image.pixelsHigh == variant.pixels else {
            throw IconError.invalid("\(variant.filename) must be exactly \(variant.pixels)x\(variant.pixels) pixels")
        }
    }
}

func renderIcon(pixels: Int) throws -> Data {
    // Allocate physical pixels directly. NSImage.lockFocus() uses the display's
    // backing scale and can silently double the exported bitmap on Retina Macs.
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw IconError.invalid("Cannot allocate a \(pixels)x\(pixels) icon bitmap")
    }
    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let cgContext = context.cgContext
    cgContext.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))
    let factor = CGFloat(pixels) / 1024
    cgContext.scaleBy(x: factor, y: factor)
    NSColor.black.setFill()
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
    NSColor.black.setStroke()
    crease.stroke()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconError.invalid("Cannot encode a \(pixels)x\(pixels) icon PNG")
    }
    return data
}

func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let validateOnly = arguments.first == "--validate"
    guard arguments.count == (validateOnly ? 2 : 1) else {
        throw IconError.invalid("Usage: swift make-icon.swift [--validate] <directory.iconset>")
    }
    let destination = URL(fileURLWithPath: arguments.last!, isDirectory: true)
    if !validateOnly {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        for variant in variants {
            try renderIcon(pixels: variant.pixels).write(to: destination.appendingPathComponent(variant.filename))
        }
    }
    try validateIconset(at: destination)
    print("Validated all 10 macOS icon variants (16-1024 pixels).")
}

do {
    try run()
} catch {
    FileHandle.standardError.write(Data("Icon generation failed: \(error)\n".utf8))
    exit(EXIT_FAILURE)
}
