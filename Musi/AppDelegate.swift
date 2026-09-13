import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var panel: MusicBarPanel!
    var lyricsPanel: MusicBarPanel!
    
    var musicController: MusicController!
    var preferencesController: PreferencesWindowController?
    var eventMonitor: Any?

    private var menuBarAnimator: MenuBarAnimator?
    private var cancellables = Set<AnyCancellable>()
    
    private enum LyricsSide { case left, right }
    private var currentLyricsSide: LyricsSide = .right

    func applicationDidFinishLaunching(_ notification: Notification) {
        musicController = MusicController()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(toggleMainPanel)
            button.target = self
        }
        
        menuBarAnimator = MenuBarAnimator(statusItem: statusItem, musicController: musicController)

        // 1. Setup Main Panel
        panel = MusicBarPanel()
        panel.delegate = self
        let root = PlayerView().environmentObject(musicController)
        let hosting = NSHostingView(rootView: root)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = CGColor.clear
        panel.contentView = hosting
        
        // 2. Setup Secondary Lyrics Panel
        lyricsPanel = MusicBarPanel()
        lyricsPanel.delegate = self
        let lyricsRoot = LyricsWindowView().environmentObject(musicController)
        let lyricsHosting = NSHostingView(rootView: lyricsRoot)
        lyricsHosting.wantsLayer = true
        lyricsHosting.layer?.backgroundColor = CGColor.clear
        lyricsPanel.contentView = lyricsHosting

        // 3. Observers
        musicController.$playerStyle
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updatePanelSize(for: $0, playlistExpanded: self?.musicController.playlistExpanded ?? false) }
            .store(in: &cancellables)

        musicController.$playlistExpanded
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.updatePanelSize(for: self.musicController.playerStyle, playlistExpanded: $0)
            }
            .store(in: &cancellables)
            
        musicController.$showLyrics
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.toggleLyricsPanel(show: show)
            }
            .store(in: &cancellables)

        musicController.$isWindowLocked
            .receive(on: RunLoop.main)
            .sink { [weak self] isLocked in
                self?.panel.isMovableByWindowBackground = !isLocked
                self?.panel.isMovable = !isLocked
            }
            .store(in: &cancellables)
            
        musicController.$isLyricsWindowLocked
            .receive(on: RunLoop.main)
            .sink { [weak self] isLocked in
                self?.lyricsPanel.isMovableByWindowBackground = !isLocked
                self?.lyricsPanel.isMovable = !isLocked
            }
            .store(in: &cancellables)
            
        musicController.$isLyricsMagnetic
            .receive(on: RunLoop.main)
            .sink { [weak self] isMagnetic in
                guard let self = self else { return }
                if isMagnetic {
                    // 🔥 THE FIX: Haptic Feedback when explicitly turning the magnet ON
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                    
                    if self.musicController.showLyrics {
                        if !self.panel.isVisible {
                            self.showMainPanel()
                        } else {
                            self.updateLyricsPanelPosition(animate: true, forceSnap: true)
                            self.panel.addChildWindow(self.lyricsPanel, ordered: .above)
                        }
                    }
                } else {
                    self.panel.removeChildWindow(self.lyricsPanel)
                }
            }
            .store(in: &cancellables)

        HotKeyManager.shared.action = { [weak self] in
            self?.toggleMainPanel()
        }
        HotKeyManager.shared.registerSavedHotKey()
        
        // 🔥 NEW: Global Media Hotkeys (Cmd + Shift + Arrows/Space)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleMediaHotkey(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleMediaHotkey(event) == true {
                return nil // Consume event if it was a hotkey
            }
            return event
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self else { return }
            let mouseLoc = NSEvent.mouseLocation
            
            let clickedMain = self.panel.isVisible && self.panel.frame.contains(mouseLoc)
            let clickedLyrics = self.lyricsPanel.isVisible && self.lyricsPanel.frame.contains(mouseLoc)
            
            if clickedMain || clickedLyrics { return }
            
            if self.panel.isVisible && !self.musicController.isPinned {
                self.hideMainPanel()
            }
            if self.lyricsPanel.isVisible && !self.musicController.isLyricsPinned {
                self.musicController.showLyrics = false
            }
        }
        
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.panel.isVisible && !self.musicController.isPinned {
                    self.hideMainPanel()
                }
                if self.lyricsPanel.isVisible && !self.musicController.isLyricsPinned {
                    self.musicController.showLyrics = false
                }
            }
            .store(in: &cancellables)
    }

    // 🔥 NEW: Hotkey Interceptor Method
    @discardableResult
    private func handleMediaHotkey(_ event: NSEvent) -> Bool {
        // Strip out hardware flags like numpad, caps lock, etc. to get pure modifiers
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Strictly require only Command + Shift
        if flags == [.command, .shift] {
            if event.keyCode == 124 { // Right Arrow
                musicController.nextTrack()
                return true
            } else if event.keyCode == 123 { // Left Arrow
                musicController.previousTrack()
                return true
            } else if event.keyCode == 49 { // Spacebar
                musicController.togglePlayPause()
                return true
            }
        }
        return false
    }

    func windowWillMove(_ notification: Notification) {
        if notification.object as? NSWindow == lyricsPanel {
            if musicController.isLyricsMagnetic {
                DispatchQueue.main.async { [weak self] in
                    self?.musicController.isLyricsMagnetic = false
                }
            }
        }
    }

    func windowDidMove(_ notification: Notification) {
        if notification.object as? NSWindow == panel {
            let anchorX = panel.frame.midX
            let anchorY = panel.frame.maxY
            UserDefaults.standard.set(Double(anchorX), forKey: "anchorX")
            UserDefaults.standard.set(Double(anchorY), forKey: "anchorY")
            UserDefaults.standard.set(true, forKey: "hasSavedAnchor")
            
            if musicController.showLyrics && musicController.isLyricsMagnetic {
                updateLyricsPanelPosition(animate: false, forceSnap: false)
            }
        }
    }

    private func getTargetSize(for style: PlayerStyle, playlistExpanded: Bool) -> NSSize {
        switch style {
        case .standard:
            return NSSize(width: 360, height: playlistExpanded ? 735 : 570)
        case .mini:
            return NSSize(width: 500, height: 140)
        case .compact:
            return NSSize(width: 260, height: 260)
        }
    }

    private func updatePanelSize(for style: PlayerStyle, playlistExpanded: Bool) {
        guard panel != nil else { return }
        panel.styleMask.remove(.resizable)
        
        let targetSize = getTargetSize(for: style, playlistExpanded: playlistExpanded)
        guard panel.frame.size != targetSize else { return }

        let currentTopY = panel.frame.maxY
        let currentMidX = panel.frame.midX
        
        var frame = panel.frame
        frame.size = targetSize
        frame.origin.y = currentTopY - targetSize.height
        frame.origin.x = currentMidX - (targetSize.width / 2)

        if let screen = NSScreen.main {
            frame.origin.y = max(frame.origin.y, screen.visibleFrame.minY + 4)
            frame.origin.x = max(screen.visibleFrame.minX + 8, min(frame.origin.x, screen.visibleFrame.maxX - targetSize.width - 8))
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.5
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }, completionHandler: {
            if self.musicController.showLyrics && self.musicController.isLyricsMagnetic {
                self.updateLyricsPanelPosition(animate: true, forceSnap: true)
            }
        })
    }
    
    // MARK: - Instant Edge-Detection Logic
    
    private func calculateTargetLyricsFrame() -> (frame: NSRect, side: LyricsSide) {
        let mainFrame = panel.frame
        let gap: CGFloat = 8
        let lWidth: CGFloat = 280
        let lHeight: CGFloat = mainFrame.height < 200 ? 380 : mainFrame.height
        
        guard let screen = panel.screen ?? NSScreen.main else {
            return (NSRect(x: mainFrame.maxX + gap, y: mainFrame.maxY - lHeight, width: lWidth, height: lHeight), .right)
        }
        
        var expectedSide: LyricsSide = .right
        var targetX = mainFrame.maxX + gap
        
        if targetX + lWidth > screen.visibleFrame.maxX {
            expectedSide = .left
            targetX = mainFrame.minX - lWidth - gap
        }
        
        if targetX < screen.visibleFrame.minX {
            let rightSpace = screen.visibleFrame.maxX - mainFrame.maxX
            let leftSpace = mainFrame.minX - screen.visibleFrame.minX
            if rightSpace > leftSpace {
                expectedSide = .right
                targetX = mainFrame.maxX + gap
            } else {
                expectedSide = .left
                targetX = mainFrame.minX - lWidth - gap
            }
        }
        
        let targetY = mainFrame.maxY - lHeight
        return (NSRect(x: targetX, y: targetY, width: lWidth, height: lHeight), expectedSide)
    }
    
    private func updateLyricsPanelPosition(animate: Bool, forceSnap: Bool = false) {
        guard panel.isVisible else { return }
        
        let target = calculateTargetLyricsFrame()
        let newFrame = target.frame
        let expectedSide = target.side
        
        let sideChanged = currentLyricsSide != expectedSide
        let sizeChanged = lyricsPanel.frame.size != newFrame.size
        let distance = hypot(lyricsPanel.frame.minX - newFrame.minX, lyricsPanel.frame.minY - newFrame.minY)
        
        if sideChanged || sizeChanged || (forceSnap && distance > 1.0) {
            currentLyricsSide = expectedSide
            
            // 🔥 THE FIX: Haptic Feedback bump when it auto-flips edges
            if sideChanged && musicController.isLyricsMagnetic {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
            
            let shouldAnimate = animate && !sideChanged
            
            if shouldAnimate {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.4
                    ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                    ctx.allowsImplicitAnimation = true
                    lyricsPanel.animator().setFrame(newFrame, display: true)
                }
            } else {
                lyricsPanel.setFrame(newFrame, display: true)
            }
        }
    }
    
    private func toggleLyricsPanel(show: Bool) {
        if show {
            if !lyricsPanel.isVisible {
                let target = calculateTargetLyricsFrame()
                lyricsPanel.setFrame(target.frame, display: false)
                currentLyricsSide = target.side
            }
            
            lyricsPanel.alphaValue = 0
            lyricsPanel.orderFront(nil)
            
            if musicController.isLyricsMagnetic {
                panel.addChildWindow(lyricsPanel, ordered: .above)
            }
            
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                lyricsPanel.animator().alphaValue = 1
            }
        } else {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                lyricsPanel.animator().alphaValue = 0
            }, completionHandler: {
                self.panel.removeChildWindow(self.lyricsPanel)
                self.lyricsPanel.orderOut(nil)
            })
        }
    }

    // MARK: - Main Panel Visibility
    
    @objc func toggleMainPanel() {
        if panel.isVisible { hideMainPanel() } else { showMainPanel() }
    }

    func showMainPanel() {
        guard let button = statusItem.button,
              let screen = button.window?.screen ?? NSScreen.main else { return }
        
        if musicController.playlistExpanded { musicController.playlistExpanded = false }

        let targetSize = getTargetSize(for: musicController.playerStyle, playlistExpanded: false)
        let W = targetSize.width
        let H = targetSize.height
        
        var targetX: CGFloat = 0
        var targetY: CGFloat = 0
        
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "hasSavedAnchor") {
            let anchorX = CGFloat(defaults.double(forKey: "anchorX"))
            let anchorY = CGFloat(defaults.double(forKey: "anchorY"))
            targetX = anchorX - (W / 2)
            targetY = anchorY - H
        } else {
            let btnRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
            let gap: CGFloat = 6
            targetX = btnRect.midX - W / 2
            targetY = btnRect.minY - H - gap
        }

        targetX = max(screen.visibleFrame.minX + 8, min(targetX, screen.visibleFrame.maxX - W - 8))
        targetY = max(screen.visibleFrame.minY + 4, min(targetY, screen.visibleFrame.maxY - H - 4))

        panel.setFrame(NSRect(x: targetX, y: targetY, width: W, height: H), display: false)
        panel.alphaValue = 0

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if musicController.showLyrics && musicController.isLyricsMagnetic {
            updateLyricsPanelPosition(animate: false, forceSnap: true)
            panel.addChildWindow(lyricsPanel, ordered: .above)
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hideMainPanel() {
        musicController.playlistExpanded = false
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.14
            panel.animator().alphaValue = 0
        }, completionHandler: {
            self.panel.orderOut(nil)
        })
    }

    func openPreferences() {
        hideMainPanel()
        
        if preferencesController == nil {
            preferencesController = PreferencesWindowController(musicController: self.musicController)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.preferencesController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
        cancellables.removeAll()
    }
}
