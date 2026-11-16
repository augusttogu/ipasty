// Desenha o ícone do Ipasty (prancheta com carinha) e gera Resources/AppIcon.icns.
// Uso: swift tools/make-icon.swift <pasta-de-saída>
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/icon")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = size / 1024

    // Fundo: quadrado arredondado com degradê (grade padrão de ícones do macOS: 824 dentro de 1024)
    let bg = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let bgPath = NSBezierPath(roundedRect: bg, xRadius: 185 * s, yRadius: 185 * s)
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = 20 * s
    shadow.shadowOffset = NSSize(width: 0, height: -10 * s)
    shadow.set()
    NSGradient(colors: [NSColor(calibratedRed: 0.36, green: 0.42, blue: 1.0, alpha: 1),
                        NSColor(calibratedRed: 0.67, green: 0.33, blue: 0.96, alpha: 1)])!
        .draw(in: bgPath, angle: -60)
    NSGraphicsContext.current?.restoreGraphicsState()

    // Prancheta
    let board = NSRect(x: 292 * s, y: 215 * s, width: 440 * s, height: 540 * s)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: board, xRadius: 60 * s, yRadius: 60 * s).fill()

    // Presilha
    let clip = NSRect(x: 412 * s, y: 700 * s, width: 200 * s, height: 110 * s)
    NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.45, alpha: 1).setFill()
    NSBezierPath(roundedRect: clip, xRadius: 40 * s, yRadius: 40 * s).fill()
    NSColor(calibratedRed: 0.36, green: 0.42, blue: 1.0, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 487 * s, y: 760 * s, width: 50 * s, height: 30 * s)).fill()

    // Carinha
    let face = NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.45, alpha: 1)
    face.setFill()
    NSBezierPath(ovalIn: NSRect(x: 405 * s, y: 505 * s, width: 56 * s, height: 72 * s)).fill()
    NSBezierPath(ovalIn: NSRect(x: 563 * s, y: 505 * s, width: 56 * s, height: 72 * s)).fill()
    let smile = NSBezierPath()
    smile.lineWidth = 34 * s
    smile.lineCapStyle = .round
    smile.appendArc(withCenter: NSPoint(x: 512 * s, y: 455 * s), radius: 120 * s, startAngle: 215, endAngle: 325)
    face.setStroke()
    smile.stroke()

    // Bochechas
    NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.70, alpha: 0.55).setFill()
    NSBezierPath(ovalIn: NSRect(x: 355 * s, y: 430 * s, width: 70 * s, height: 40 * s)).fill()
    NSBezierPath(ovalIn: NSRect(x: 599 * s, y: 430 * s, width: 70 * s, height: 40 * s)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let iconset = out.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = CGFloat(base * scale)
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try drawIcon(size: px).representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
try drawIcon(size: 1024).representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent("icon-1024.png"))
print(iconset.path)
