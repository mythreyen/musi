import AppKit

class MenuBarMeter {
    private weak var button: NSStatusBarButton?
    private var isPlaying: Bool = false

    init(button: NSStatusBarButton) {
        self.button = button
        
        // Strip away any leftover custom styling, green backgrounds, or text
        self.button?.title = ""
        self.button?.imagePosition = .imageOnly
        self.button?.wantsLayer = false
        self.button?.layer?.backgroundColor = NSColor.clear.cgColor
        
        updateIcon()
    }

    func setPlaying(_ playing: Bool) {
        guard self.isPlaying != playing else { return }
        self.isPlaying = playing
        updateIcon()
    }

    func setArtist(_ artist: String) {
        // Intentionally ignored!
        // We are dropping the text to keep the menu bar hyper-minimalist.
    }

    private func updateIcon() {
        guard let button = button else { return }
        button.image = createEqualizerIcon(playing: isPlaying)
    }

    /// Custom-draws the app's signature 3-pill equalizer right in the menu bar.
    private func createEqualizerIcon(playing: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 16)
        let image = NSImage(size: size)
        
        image.lockFocus()

        // Using black ensures it works perfectly as a macOS Template Image
        // (macOS will automatically invert it to white when in Dark Mode)
        NSColor.black.setFill()

        let barWidth: CGFloat = 3
        let gap: CGFloat = 2.5
        let totalWidth = (barWidth * 3) + (gap * 2)
        let startX = (size.width - totalWidth) / 2

        // If playing, show the iconic wave. If paused, collapse to 3 sleek dots.
        let heights: [CGFloat] = playing ? [10, 14, 8] : [4, 4, 4]

        for (i, h) in heights.enumerated() {
            let x = startX + CGFloat(i) * (barWidth + gap)
            let y = (size.height - h) / 2
            let rect = NSRect(x: x, y: y, width: barWidth, height: h)
            
            // Maximum corner radius for the liquid pill look
            let path = NSBezierPath(roundedRect: rect, xRadius: 1.5, yRadius: 1.5)
            path.fill()
        }

        image.unlockFocus()
        
        // This flag is the magic that makes it match native macOS icons
        image.isTemplate = true
        
        return image
    }
}
