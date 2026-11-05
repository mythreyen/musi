import AppKit
import SwiftUI

class PreferencesWindowController: NSWindowController {
    convenience init(musicController: MusicController) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 600),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Musi Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.init(window: window)
        
        let contentView = PreferencesView().environmentObject(musicController)
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
    }
}
