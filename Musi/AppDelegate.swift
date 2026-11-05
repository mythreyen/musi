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
    
    // Panel state tracking
    private enum LyricsSide { case left, right }
    private var currentLyricsSide: LyricsSide = .right
    
    private enum PanelSide { case left, right, center, topMiddle }
    private var currentPanelSide: PanelSide = .center
    
    // Multi-Directional Swipe detection variables
    private var menuBarSwipeAccumulatorX: CGFloat = 0
    private var menuBarSwipeAccumulatorY: CGFloat = 0
    private var menuBarSwipeTimer: Timer?
    private var lastSwipeActionTime: Date = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        musicController = MusicController()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(toggleMainPanel)
            button.target = self
        }
        
        menuBarAnimator = MenuBarAnimator(statusItem: statusItem, musicController: musicController)

        // Initialize Panels
        panel = MusicBarPanel()
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: PlayerView().environmentObject(musicController))
        
        lyricsPanel = MusicBarPanel()
        lyricsPanel.delegate = self
        lyricsPanel.contentView = NSHostingView(rootView: LyricsWindowView().environmentObject(musicController))

        setupObservers()
        setupMenuBarSwipeDetector()
        setupEventMonitors()
        
        // Hotkey Setup
        HotKeyManager.shared.action = { [weak self] in self?.toggleMainPanel() }
        HotKeyManager.shared.registerSavedHotKey()
    }

    // MARK: - Setup Observers & Monitors
    
    private func setupObservers() {
        musicController.$playerStyle
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.updatePanelSize(for: $0, playlistExpanded: self?.musicController.playlistExpanded ?? false)
            }
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
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                    if self.musicController.showLyrics {
                        if !self.panel.isVisible {
                            self.showMainPanel(side: self.currentPanelSide)
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
    
    private func setupEventMonitors() {
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
        
        // Media Hotkeys
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleMediaHotkey(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleMediaHotkey(event) == true { return nil }
            return event
        }
    }

    // MARK: - Multi-Directional Swipe Detection
    
    private func setupMenuBarSwipeDetector() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            
            // Kill momentum (don't react if finger is off glass)
            if event.momentumPhase.rawValue != 0 {
                self.menuBarSwipeAccumulatorX = 0
                self.menuBarSwipeAccumulatorY = 0
                return
            }
            if event.phase == .began {
                self.menuBarSwipeAccumulatorX = 0
                self.menuBarSwipeAccumulatorY = 0
            }
            
            guard Date().timeIntervalSince(self.lastSwipeActionTime) > 0.4 else { return }
            
            let mouseLoc = NSEvent.mouseLocation
            guard let screen = NSScreen.screens.first(where: { $0.frame.insetBy(dx: -1, dy: -1).contains(mouseLoc) }) else { return }
            
            // Only trigger if hovering top menu bar
            if (screen.frame.maxY - mouseLoc.y) <= 40 {
                let deltaX = event.scrollingDeltaX
                let deltaY = event.scrollingDeltaY
                
                if abs(deltaX) > 2 { self.menuBarSwipeAccumulatorX += deltaX }
                if abs(deltaY) > 2 { self.menuBarSwipeAccumulatorY += deltaY }
                
                if abs(deltaX) > 2 || abs(deltaY) > 2 {
                    self.menuBarSwipeTimer?.invalidate()
                    self.menuBarSwipeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                        self?.menuBarSwipeAccumulatorX = 0
                        self?.menuBarSwipeAccumulatorY = 0
                    }
                    
                    let dirMult: CGFloat = event.isDirectionInvertedFromDevice ? 1.0 : -1.0
                    let physX = self.menuBarSwipeAccumulatorX * dirMult
                    let physY = self.menuBarSwipeAccumulatorY * dirMult
                    let threshold: CGFloat = 40.0
                    
                    // Determine dominant swipe direction (Horizontal vs Vertical)
                    if abs(physX) > abs(physY) {
                        // 👉 Horizontal Swipe
                        if physX > threshold { // Swipe Right -> Open Left or Close Right
                            if !self.panel.isVisible { self.showMainPanel(side: .left) }
                            else if self.currentPanelSide == .right { self.hideMainPanel() }
                            self.resetSwipeState()
                        } else if physX < -threshold { // Swipe Left -> Open Right or Close Left
                            if !self.panel.isVisible { self.showMainPanel(side: .right) }
                            else if self.currentPanelSide == .left { self.hideMainPanel() }
                            self.resetSwipeState()
                        }
                    } else {
                        // 👇 Vertical Swipe
                        if physY > threshold { // Swipe Down -> Drop Compact View
                            if !self.panel.isVisible {
                                self.musicController.playerStyle = .compact
                                self.showMainPanel(side: .topMiddle)
                            }
                            self.resetSwipeState()
                        } else if physY < -threshold { // Swipe Up -> Push back to Menu Bar
                            if self.panel.isVisible {
                                self.hideMainPanel()
                            }
                            self.resetSwipeState()
                        }
                    }
                }
            }
        }
        NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel, handler: handler)
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { handler($0); return $0 }
    }
    
    private func resetSwipeState() {
        self.lastSwipeActionTime = Date()
        self.menuBarSwipeAccumulatorX = 0
        self.menuBarSwipeAccumulatorY = 0
    }

    // MARK: - Animation Engine
    
    @objc func toggleMainPanel() {
        if panel.isVisible { hideMainPanel() } else { showMainPanel(side: .center) }
    }

    private func showMainPanel(side: PanelSide) {
        guard let button = statusItem.button, let screen = button.window?.screen ?? NSScreen.main else { return }
        self.currentPanelSide = side
        
        let targetSize = getTargetSize(for: musicController.playerStyle, playlistExpanded: musicController.playlistExpanded)
        let gap: CGFloat = 12
        var targetX: CGFloat = 0, targetY: CGFloat = 0
        
        switch side {
        case .left:
            targetX = screen.visibleFrame.minX + gap
            targetY = screen.visibleFrame.maxY - targetSize.height - gap
        case .right:
            targetX = screen.visibleFrame.maxX - targetSize.width - gap
            targetY = screen.visibleFrame.maxY - targetSize.height - gap
        case .topMiddle:
            targetX = screen.visibleFrame.midX - (targetSize.width / 2)
            targetY = screen.visibleFrame.maxY - targetSize.height - gap
        case .center:
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: "hasSavedAnchor") {
                targetX = CGFloat(defaults.double(forKey: "anchorX")) - (targetSize.width / 2)
                targetY = CGFloat(defaults.double(forKey: "anchorY")) - targetSize.height
            } else {
                let btnRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
                targetX = btnRect.midX - (targetSize.width / 2)
                targetY = btnRect.minY - targetSize.height - 6
            }
        }

        // Clamp to screen bounds
        targetX = max(screen.visibleFrame.minX + 8, min(targetX, screen.visibleFrame.maxX - targetSize.width - 8))
        targetY = max(screen.visibleFrame.minY + 4, min(targetY, screen.visibleFrame.maxY - targetSize.height - 4))

        let finalFrame = NSRect(x: targetX, y: targetY, width: targetSize.width, height: targetSize.height)
        var startFrame = finalFrame
        
        switch side {
        case .left: startFrame.origin.x -= 20
        case .right: startFrame.origin.x += 20
        case .topMiddle: startFrame.origin.y += 20
        case .center: startFrame.origin.y += 15
        }

        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if musicController.showLyrics && musicController.isLyricsMagnetic {
            updateLyricsPanelPosition(animate: false, forceSnap: true)
            panel.addChildWindow(lyricsPanel, ordered: .above)
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().setFrame(finalFrame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    func hideMainPanel() {
        musicController.playlistExpanded = false
        var endFrame = panel.frame
        
        switch currentPanelSide {
        case .left: endFrame.origin.x -= 20
        case .right: endFrame.origin.x += 20
        case .topMiddle: endFrame.origin.y += 20
        case .center: endFrame.origin.y += 15
        }
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().setFrame(endFrame, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            self.panel.orderOut(nil)
        })
    }
    
    // MARK: - Lyrics Window Logic
    
    private func toggleLyricsPanel(show: Bool) {
        if show {
            let target = calculateTargetLyricsFrame()
            let finalFrame = target.frame
            let startFrame = NSRect(x: finalFrame.minX, y: finalFrame.minY + 15, width: finalFrame.width, height: finalFrame.height)
            
            if !lyricsPanel.isVisible {
                lyricsPanel.setFrame(startFrame, display: false)
                currentLyricsSide = target.side
            } else {
                lyricsPanel.setFrame(startFrame, display: true)
            }
            
            lyricsPanel.alphaValue = 0
            lyricsPanel.orderFront(nil)
            
            if musicController.isLyricsMagnetic {
                panel.addChildWindow(lyricsPanel, ordered: .above)
            }
            
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                lyricsPanel.animator().setFrame(finalFrame, display: true)
                lyricsPanel.animator().alphaValue = 1
            }
        } else {
            let currentFrame = lyricsPanel.frame
            let endFrame = NSRect(x: currentFrame.minX, y: currentFrame.minY + 15, width: currentFrame.width, height: currentFrame.height)
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                lyricsPanel.animator().setFrame(endFrame, display: true)
                lyricsPanel.animator().alphaValue = 0
            }, completionHandler: {
                self.panel.removeChildWindow(self.lyricsPanel)
                self.lyricsPanel.orderOut(nil)
            })
        }
    }
    
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

    // MARK: - Window Delegate & Utilities
    
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
        case .standard: return NSSize(width: 360, height: playlistExpanded ? 735 : 570)
        case .mini:     return NSSize(width: 500, height: 140)
        case .compact:  return NSSize(width: 260, height: 260)
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

    private func handleMediaHotkey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.command, .shift] {
            if event.keyCode == 124 { musicController.nextTrack(); return true }
            else if event.keyCode == 123 { musicController.previousTrack(); return true }
            else if event.keyCode == 49 { musicController.togglePlayPause(); return true }
        }
        return false
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
