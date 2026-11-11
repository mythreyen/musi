import AppKit

class MusicBarPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 570),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        backgroundColor    = .clear
        isOpaque           = false
        hasShadow          = true
        level              = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        isMovable                   = true
        isMovableByWindowBackground = true
        acceptsMouseMovedEvents     = true
        
        // Prevents macOS from automatically hiding the window when it loses focus
        hidesOnDeactivate           = false
        
        alphaValue         = 0
    }

    override var canBecomeKey:  Bool { true  }
    override var canBecomeMain: Bool { false }
}
