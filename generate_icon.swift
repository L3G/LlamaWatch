import AppKit

// Generate an app icon from the eye.fill SF Symbol
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // Draw rounded rect background
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.20, alpha: 1.0).setFill()
    bgPath.fill()

    // Draw the eye symbol
    let symbolSize = size * 0.55
    let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symbolRect = symbol.size
        let x = (size - symbolRect.width) / 2
        let y = (size - symbolRect.height) / 2
        NSColor.white.set()
        symbol.draw(in: NSRect(x: x, y: y, width: symbolRect.width, height: symbolRect.height),
                    from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to render \(name)")
        continue
    }
    try png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

// Convert iconset to icns
let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
try proc.run()
proc.waitUntilExit()

// Clean up iconset
try? fm.removeItem(atPath: iconsetPath)

if proc.terminationStatus == 0 {
    print("Generated AppIcon.icns")
} else {
    print("iconutil failed with status \(proc.terminationStatus)")
}
