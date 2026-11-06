import AppKit

/// Extracts a representative "vibrant" color from an NSImage by:
/// 1. Scaling to a small bitmap to reduce computation
/// 2. Sampling every pixel in HSB space
/// 3. Discarding near-grey and very dark/light pixels
/// 4. Bucketing hues and picking the dominant bucket
/// 5. Averaging the winning samples for a smooth result
enum AlbumColorExtractor {

    static func extract(from image: NSImage) -> NSColor {
        guard let bitmap = rasterize(image, size: NSSize(width: 64, height: 64)) else {
            return .systemPurple
        }

        var hueAccumulators: [Int: (h: Double, s: Double, b: Double, count: Int)] = [:]

        autoreleasepool {
            for y in 0..<64 {
                for x in 0..<64 {
                    guard let color = bitmap.colorAt(x: x, y: y) else { continue }

                    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

                    // Skip transparent, near-white, near-black, near-grey
                    guard a > 0.5, s > 0.18, b > 0.15, b < 0.97 else { continue }

                    // Bucket hues into 24 segments (15° each) for dominance voting
                    let bucket = Int(h * 24) % 24
                    if var acc = hueAccumulators[bucket] {
                        acc.h     += Double(h)
                        acc.s     += Double(s)
                        acc.b     += Double(b)
                        acc.count += 1
                        hueAccumulators[bucket] = acc
                    } else {
                        hueAccumulators[bucket] = (Double(h), Double(s), Double(b), 1)
                    }
                }
            }
        }

        // No usable pixels → neutral fallback
        guard let winner = hueAccumulators.values.max(by: { $0.count < $1.count }) else {
            return NSColor(hue: 0.72, saturation: 0.55, brightness: 0.55, alpha: 1)
        }

        let n  = Double(winner.count)
        let hF = CGFloat(winner.h / n)
        // Boost saturation a little so the tint reads through the dark glass
        let sF = CGFloat(min(winner.s / n + 0.15, 1.0))
        // Keep brightness in the mid range — too dark won't show, too bright blows out
        let bF = CGFloat(max(0.35, min(winner.b / n, 0.75)))

        return NSColor(hue: hF, saturation: sF, brightness: bF, alpha: 1.0)
    }

    // MARK: – Private helpers

    private static func rasterize(_ image: NSImage, size: NSSize) -> NSBitmapImageRep? {
        guard let cgRef = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let rep else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.draw(cgRef, in: CGRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()

        return rep
    }
}
