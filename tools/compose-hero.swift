// Junta três prints do painel lado a lado, com sombra e cantos arredondados, para a capa do README.
// Uso: swift tools/compose-hero.swift saída.png a.png b.png c.png
import AppKit

let args = CommandLine.arguments
guard args.count >= 5 else { print("uso: saída.png a.png b.png c.png"); exit(1) }
let images = args[2...].compactMap { NSImage(contentsOfFile: $0) }
guard images.count == 3 else { print("não consegui abrir os prints"); exit(1) }

let shotW: CGFloat = 820, shotH: CGFloat = 1120   // tamanho em pixels de cada print (2x)
let gap: CGFloat = 70, pad: CGFloat = 110
let W = pad * 2 + shotW * 3 + gap * 2
let H = pad * 2 + shotH + 40

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let bg = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: W, height: H), xRadius: 60, yRadius: 60)
NSGradient(colors: [NSColor(calibratedRed: 0.36, green: 0.42, blue: 1.0, alpha: 1),
                    NSColor(calibratedRed: 0.67, green: 0.33, blue: 0.96, alpha: 1)])!.draw(in: bg, angle: -20)

for (i, img) in images.enumerated() {
    let lift: CGFloat = i == 1 ? 40 : 0   // o do meio um pouco mais alto
    let r = NSRect(x: pad + CGFloat(i) * (shotW + gap), y: pad + lift, width: shotW, height: shotH)
    let path = NSBezierPath(roundedRect: r, xRadius: 28, yRadius: 28)
    NSGraphicsContext.current?.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = NSColor.black.withAlphaComponent(0.35)
    s.shadowBlurRadius = 45
    s.shadowOffset = NSSize(width: 0, height: -18)
    s.set()
    NSColor.white.setFill()
    path.fill()
    NSGraphicsContext.current?.restoreGraphicsState()
    NSGraphicsContext.current?.saveGraphicsState()
    path.addClip()
    img.draw(in: r)
    NSGraphicsContext.current?.restoreGraphicsState()
}
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[1]))
