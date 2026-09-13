import AppKit
import Combine

class MenuBarAnimator {
    private let statusItem: NSStatusItem
    private let music: MusicController
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // 🔥 THE FIX: Pre-render an array of frames to achieve 0% CPU usage during animation
    private var frames: [NSImage] = []
    private var currentFrameIndex = 0
    
    init(statusItem: NSStatusItem, musicController: MusicController) {
        self.statusItem = statusItem
        self.music = musicController
        
        generateFluidFrames()
        
        music.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] playing in
                if playing {
                    self?.startAnimating()
                } else {
                    self?.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        setRestingState()
    }
    
    // MARK: - Core Animation Engine
    
    private func generateFluidFrames() {
        let totalFrames = 35 // 35 frames creates a seamless 1.4 second loop at 25 FPS
        let size = NSSize(width: 18, height: 16)
        let barWidth: CGFloat = 3
        let spacing: CGFloat = 2
        let totalWidth = (barWidth * 3) + (spacing * 2)
        let startX = (size.width - totalWidth) / 2
        
        for i in 0..<totalFrames {
            // Convert current frame into a time variable for our sine waves (0.0 to 2π)
            let t = Double(i) / Double(totalFrames) * 2.0 * .pi
            
            // 🔥 Use smooth trigonometric sine waves instead of random jittery numbers
            // Formula: BaseHeight + MaxVariance * ((sin(time * speed + phaseOffset) + 1) / 2)
            let h1 = 4.0 + 8.0 * CGFloat((sin(t * 2.0) + 1.0) / 2.0)          // Left bar (Range: 4 to 12)
            let h2 = 4.0 + 10.0 * CGFloat((sin(t * 3.0 + 1.5) + 1.0) / 2.0)   // Center bar (Range: 4 to 14)
            let h3 = 3.0 + 7.0 * CGFloat((sin(t * 2.5 + 3.0) + 1.0) / 2.0)    // Right bar (Range: 3 to 10)
            
            let heights = [h1, h2, h3]
            
            let image = NSImage(size: size, flipped: false) { rect in
                NSColor.black.setFill()
                
                for (index, height) in heights.enumerated() {
                    let x = startX + CGFloat(index) * (barWidth + spacing)
                    let y: CGFloat = 2 // Bottom padding offset
                    let barRect = NSRect(x: x, y: y, width: barWidth, height: height)
                    let path = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
                    path.fill()
                }
                
                return true
            }
            
            // isTemplate automatically handles flipping colors for Light/Dark mode!
            image.isTemplate = true
            frames.append(image)
        }
    }
    
    private func startAnimating() {
        timer?.invalidate()
        
        // 🔥 A fast 0.04s interval (25 FPS) for buttery smooth motion.
        // Because we are just cycling pre-rendered images, CPU impact is nonexistent.
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentFrameIndex = (self.currentFrameIndex + 1) % self.frames.count
            self.statusItem.button?.image = self.frames[self.currentFrameIndex]
        }
        
        // Adding to .common guarantees the animation doesn't freeze when the user clicks menus!
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
        currentFrameIndex = 0
        setRestingState()
    }
    
    private func setRestingState() {
        let size = NSSize(width: 18, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            
            let barWidth: CGFloat = 3
            let spacing: CGFloat = 2
            let totalWidth = (barWidth * 3) + (spacing * 2)
            let startX = (rect.width - totalWidth) / 2
            
            // Draw 3 flat resting dots
            for index in 0..<3 {
                let x = startX + CGFloat(index) * (barWidth + spacing)
                let barRect = NSRect(x: x, y: 2, width: barWidth, height: 3)
                let path = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
                path.fill()
            }
            
            return true
        }
        image.isTemplate = true
        statusItem.button?.image = image
    }
}
