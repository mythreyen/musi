import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: Root Player Router
// ─────────────────────────────────────────────────────────────

struct PlayerView: View {
    @EnvironmentObject var music: MusicController

    var body: some View {
        ZStack(alignment: .top) {
            switch music.playerStyle {
            case .standard:
                StandardPlayerView()
                    .transition(.liquid)
            case .mini:
                MiniPlayerView()
                    .transition(.liquid)
            case .compact:
                CompactPlayerView()
                    .transition(.liquid)
            }
            
            VStack(spacing: 8) {
                FloatingVolumeHUD()
                    .zIndex(100)
                
                VStack(spacing: 8) {
                    if let msg = music.playbackToastMessage {
                        ToastView(icon: music.playbackToastIcon, iconColor: .white, message: msg)
                            .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                    
                    if music.playerStyle == .compact {
                        if let trackMsg = music.trackToastMessage {
                            ToastView(icon: "music.note", iconColor: .white, message: trackMsg)
                                .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                        }
                    }
                    
                    if let pl = music.lastPlayedPlaylist {
                        ToastView(icon: "play.circle.fill", iconColor: .green, message: "Playing \(pl)")
                            .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                    
                    if music.playPlaylistFailed {
                        ToastView(icon: "exclamationmark.circle.fill", iconColor: .orange, message: "Couldn't play playlist")
                            .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                }
                .zIndex(10)
            }
            .padding(.top, music.playerStyle == .mini ? 8 : 16)
            .zIndex(999)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(music.isPinned ? music.pinnedOpacity : 1.0)
        .animation(.easeInOut(duration: 0.3), value: music.isPinned)
        .animation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.5), value: music.playerStyle)
        .preferredColorScheme(.dark)
        .contextMenu {
            Button("Preferences...") {
                (NSApp.delegate as? AppDelegate)?.openPreferences()
            }
            Divider()
            Button(music.showPlaybackControls ? "Hide Playback Controls" : "Show Playback Controls") {
                withAnimation(.easeInOut(duration: 0.3)) { music.showPlaybackControls.toggle() }
            }
            Button(music.isPinned ? "Unpin Player" : "Pin Player to Desktop") {
                withAnimation { music.isPinned.toggle() }
            }
            Button(music.isWindowLocked ? "Unlock Window Position" : "Lock Window Position") {
                withAnimation { music.isWindowLocked.toggle() }
            }
            Divider()
            Button("Quit MusicBar") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Custom Transition: Liquid Glass Morph
// ─────────────────────────────────────────────────────────────

struct LiquidGlassTransition: ViewModifier {
    let isInactive: Bool
    func body(content: Content) -> some View {
        content
            .blur(radius: isInactive ? 16 : 0)
            .scaleEffect(isInactive ? 0.9 : 1.0)
            .opacity(isInactive ? 0 : 1)
    }
}

extension AnyTransition {
    static var liquid: AnyTransition {
        .modifier(
            active: LiquidGlassTransition(isInactive: true),
            identity: LiquidGlassTransition(isInactive: false)
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Form Factor 1: Standard (Immersive Minimalist)
// ─────────────────────────────────────────────────────────────

struct StandardPlayerView: View {
    @EnvironmentObject var music: MusicController

    var body: some View {
        ZStack(alignment: .top) {
            
            ZStack {
                if let img = music.albumArt {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .id(img)
                } else {
                    PlaceholderArtBackground()
                        .id("placeholder")
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: music.isPlaying ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: music.isPlaying ? .leading : .trailing).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.6), value: music.albumArt)
            .frame(width: 360, height: music.playlistExpanded ? 732 : 570, alignment: .top)
            .animation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.5), value: music.playlistExpanded)
            .clipped()
            .overlay(
                TrackpadSwipeDetector(
                    onSwipeLeft: { music.nextTrack() },
                    onSwipeRight: { music.previousTrack() },
                    onScrollY: { delta in music.adjustVolume(delta: delta) }
                )
            )
            .onTapGesture {
                music.togglePlayPause()
            }

            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 80)
                
                Spacer()
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.4), .black.opacity(0.85), .black.opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: music.playlistExpanded ? 450 : 350)
                .animation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.5), value: music.playlistExpanded)
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HeaderBar()
                Spacer()
                
                StandardTrackInfoView()
                    .padding(.horizontal, 28)
                    .padding(.bottom, 18)
                ScrubberView()
                    .padding(.horizontal, 28)
                
                if music.showPlaybackControls {
                    TransportControls()
                        .padding(.top, 18)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)))
                }
                
                PlayPlaylistButtonOnly()
                    .padding(.horizontal, 28)
                    .padding(.top, music.showPlaybackControls ? 38 : 18)
                    .padding(.bottom, 24)
            }
            .frame(width: 360, height: 570)
            
            ZStack(alignment: .top) {
                PlaylistListView()
                    .frame(width: 304, height: 154)
            }
            .frame(width: 360, height: 160)
            .offset(y: 548)
            .opacity(music.playlistExpanded ? 1 : 0)
            .animation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.5), value: music.playlistExpanded)
            
        }
        .frame(width: 360, height: music.playlistExpanded ? 732 : 570, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .animation(.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.5), value: music.playlistExpanded)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Form Factor 2: Mini (Immersive Horizontal)
// ─────────────────────────────────────────────────────────────

struct MiniPlayerView: View {
    @EnvironmentObject var music: MusicController
    @AppStorage("closeHidesPanel") private var closeHidesPanel = true
    @State private var isHoveringIcons = false

    var body: some View {
        ZStack {
            
            ZStack {
                if let img = music.albumArt {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .id(img)
                } else {
                    PlaceholderArtBackground()
                        .id("placeholder")
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: music.isPlaying ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: music.isPlaying ? .leading : .trailing).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.6), value: music.albumArt)
            .frame(width: 500, height: 140)
            .clipped()
            .overlay(
                TrackpadSwipeDetector(
                    onSwipeLeft: { music.nextTrack() },
                    onSwipeRight: { music.previousTrack() },
                    onScrollY: { delta in music.adjustVolume(delta: delta) }
                )
            )
            .onTapGesture {
                music.togglePlayPause()
            }
            
            LinearGradient(
                colors: [.black.opacity(0.3), .black.opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            HStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        MiniTrackInfoView()
                        Spacer(minLength: 0)
                        
                        HStack(spacing: 14) {
                            MiniUtilityButton(
                                icon: music.sleepTimerRemaining != nil ? "moon.zzz.fill" : "moon.zzz",
                                isActive: music.sleepTimerRemaining != nil
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) { music.cycleSleepTimer() }
                            }
                            
                            MiniUtilityButton(icon: music.showLyrics ? "quote.bubble.fill" : "quote.bubble", isActive: music.showLyrics) {
                                withAnimation(.easeInOut(duration: 0.3)) { music.showLyrics.toggle() }
                            }
                            
                            MiniUtilityButton(icon: music.isPinned ? "pin.fill" : "pin", isActive: music.isPinned) {
                                withAnimation(.easeInOut) { music.isPinned.toggle() }
                            }
                            MiniUtilityButton(icon: closeHidesPanel ? "xmark" : "power", isActive: false) {
                                if closeHidesPanel {
                                    (NSApp.delegate as? AppDelegate)?.hideMainPanel()
                                } else {
                                    NSApplication.shared.terminate(nil)
                                }
                            }
                        }
                        .opacity(isHoveringIcons ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringIcons)
                        .padding(12)
                        .background(Color.white.opacity(0.0001))
                        .onHover { isHoveringIcons = $0 }
                        .padding(.top, -12)
                        .padding(.trailing, -12)
                    }
                    
                    Spacer()
                    ScrubberView().padding(.bottom, 2)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, music.showPlaybackControls ? 16 : 0)
                
                if music.showPlaybackControls {
                    TransportControls()
                        .scaleEffect(0.82)
                        .transition(.opacity.combined(with: .scale(scale: 0.82)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
        }
        .frame(width: 500, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Form Factor 3: Compact (Fixed 260x260)
// ─────────────────────────────────────────────────────────────

struct CompactPlayerView: View {
    @EnvironmentObject var music: MusicController
    @AppStorage("closeHidesPanel") private var closeHidesPanel = true
    @State private var isHovering = false
    @State private var isHoveringIcons = false
    
    var body: some View {
        ZStack {
            
            ZStack {
                if let img = music.albumArt {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .id(img)
                } else {
                    PlaceholderArt()
                        .id("placeholder")
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: music.isPlaying ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: music.isPlaying ? .leading : .trailing).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.6), value: music.albumArt)
            .frame(width: 260, height: 260)
            .clipped()
            .overlay(
                TrackpadSwipeDetector(
                    onSwipeLeft: { music.nextTrack() },
                    onSwipeRight: { music.previousTrack() },
                    onScrollY: { delta in music.adjustVolume(delta: delta) }
                )
            )
            .onTapGesture {
                music.togglePlayPause()
            }
            
            ZStack {
                Color.black.opacity(0.55)
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        HStack(spacing: 6) {
                            CompactUtilityButton(
                                icon: music.sleepTimerRemaining != nil ? "moon.zzz.fill" : "moon.zzz",
                                isActive: music.sleepTimerRemaining != nil
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) { music.cycleSleepTimer() }
                            }
                            
                            CompactUtilityButton(icon: music.showLyrics ? "quote.bubble.fill" : "quote.bubble", isActive: music.showLyrics) {
                                withAnimation(.easeInOut(duration: 0.3)) { music.showLyrics.toggle() }
                            }
                            
                            CompactUtilityButton(icon: music.isPinned ? "pin.fill" : "pin", isActive: false) {
                                withAnimation { music.isPinned.toggle() }
                            }
                            CompactUtilityButton(icon: closeHidesPanel ? "xmark" : "power", isActive: false) {
                                if closeHidesPanel {
                                    (NSApp.delegate as? AppDelegate)?.hideMainPanel()
                                } else {
                                    NSApplication.shared.terminate(nil)
                                }
                            }
                        }
                        .opacity(isHoveringIcons ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringIcons)
                        .padding(12)
                        .background(Color.white.opacity(0.0001))
                        .onHover { isHoveringIcons = $0 }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        ScrubberView().padding(.horizontal, 24)
                        
                        if music.showPlaybackControls {
                            TransportControls()
                                .scaleEffect(0.85)
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }.padding(.bottom, 24)
                }
            }
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .frame(width: 260, height: 260)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .onHover { isHovering = $0 }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: PRO-GRADE: Standalone Lyrics Window
// ─────────────────────────────────────────────────────────────

struct LyricsWindowView: View {
    @EnvironmentObject var music: MusicController

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            Color.black.opacity(0.3)
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if music.isFetchingLyrics {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 160)
                        } else if let lyrics = music.lyrics, !lyrics.isEmpty {
                            
                            Spacer().frame(height: 160)
                            
                            ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                                let isActive = music.activeLyricIndex == index
                                let isStatic = line.time == -1
                                let highlighted = isActive || isStatic
                                
                                let scale: CGFloat = highlighted ? 1.0 : 0.82
                                let opacity: Double = highlighted ? 1.0 : 0.25
                                let blurRad: CGFloat = highlighted ? 0 : 2.5
                                
                                Text(line.text)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white)
                                    .opacity(opacity)
                                    .blur(radius: blurRad)
                                    .scaleEffect(scale, anchor: .leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .id(index)
                                    .onTapGesture {
                                        if !isStatic { music.seek(to: line.time) }
                                    }
                            }
                            
                            Spacer().frame(height: 160)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "text.quote")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white.opacity(0.4))
                                Text("No lyrics available")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 160)
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0), value: music.activeLyricIndex)
                }
                .onChange(of: music.activeLyricIndex) { newIndex in
                    guard let index = newIndex else { return }
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
                .onAppear {
                    if let index = music.activeLyricIndex {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
            
            LyricsHeaderBar()
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .opacity(music.isLyricsPinned ? music.pinnedOpacity : 1.0)
        .animation(.easeInOut(duration: 0.3), value: music.isLyricsPinned)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Extracted Utility Buttons & Headers
// ─────────────────────────────────────────────────────────────

struct LyricsHeaderBar: View {
    @EnvironmentObject var music: MusicController
    @State private var isHoveringIcons = false

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 12) {
                StandardUtilityButton(
                    icon: music.isLyricsWindowLocked ? "lock.fill" : "lock.open",
                    isActive: music.isLyricsWindowLocked,
                    helpText: music.isLyricsWindowLocked ? "Unlock Lyrics Window" : "Lock Lyrics Window Position"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) { music.isLyricsWindowLocked.toggle() }
                }
                
                StandardUtilityButton(
                    icon: "link",
                    isActive: music.isLyricsMagnetic,
                    helpText: music.isLyricsMagnetic ? "Unlink from Player" : "Magnetically Link to Player"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) { music.isLyricsMagnetic.toggle() }
                }
                
                StandardUtilityButton(icon: music.isLyricsPinned ? "pin.fill" : "pin", isActive: music.isLyricsPinned, helpText: music.isLyricsPinned ? "Unpin Lyrics" : "Pin Lyrics") {
                    withAnimation(.easeInOut(duration: 0.15)) { music.isLyricsPinned.toggle() }
                }
                
                StandardUtilityButton(icon: "xmark", isActive: false, helpText: "Close Lyrics") {
                    withAnimation(.easeInOut(duration: 0.3)) { music.showLyrics = false }
                }
            }
            .opacity(isHoveringIcons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHoveringIcons)
            .padding(10)
            .background(Color.white.opacity(0.0001))
            .onHover { isHoveringIcons = $0 }
        }
        .padding(.trailing, 10)
        .padding(.top, 8)
    }
}

struct StandardUtilityButton: View {
    let icon: String
    let isActive: Bool
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: icon == "power" || icon == "xmark" ? .bold : .medium))
                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.6))
                .frame(width: 24, height: 24)
                .background(Circle().fill(isActive ? Color.white.opacity(0.25) : Color.black.opacity(0.2)))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}

struct MiniUtilityButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct CompactUtilityButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: icon == "power" || icon == "xmark" ? .bold : .semibold))
                .padding(8)
                .background(Circle().fill(Color.white.opacity(isActive ? 0.4 : 0.2)))
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Shared Reused Components
// ─────────────────────────────────────────────────────────────

struct HeaderBar: View {
    @EnvironmentObject var music: MusicController
    @AppStorage("closeHidesPanel") private var closeHidesPanel = true
    @State private var isHoveringIcons = false

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3.5) {
                ForEach(0..<3) { i in NowPlayingDot(index: i, isActive: music.isPlaying) }
            }
            .allowsHitTesting(false)
            .padding(.leading, 4)
            
            Spacer()
            
            HStack(spacing: 12) {
                StandardUtilityButton(
                    icon: music.sleepTimerRemaining != nil ? "moon.zzz.fill" : "moon.zzz",
                    isActive: music.sleepTimerRemaining != nil,
                    helpText: music.sleepTimerRemaining != nil ? "Sleep Timer: \(music.sleepTimerRemaining! / 60)m left. Click to change." : "Set Sleep Timer"
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) { music.cycleSleepTimer() }
                }
                
                StandardUtilityButton(icon: music.showLyrics ? "quote.bubble.fill" : "quote.bubble", isActive: music.showLyrics, helpText: "Show Lyrics") {
                    withAnimation(.easeInOut(duration: 0.3)) { music.showLyrics.toggle() }
                }
                
                StandardUtilityButton(icon: music.isPinned ? "pin.fill" : "pin", isActive: music.isPinned, helpText: music.isPinned ? "Unpin window" : "Pin window to desktop") {
                    withAnimation(.easeInOut(duration: 0.15)) { music.isPinned.toggle() }
                }
                
                StandardUtilityButton(icon: closeHidesPanel ? "xmark" : "power", isActive: false, helpText: closeHidesPanel ? "Hide MusicBar" : "Quit MusicBar") {
                    if closeHidesPanel {
                        (NSApp.delegate as? AppDelegate)?.hideMainPanel()
                    } else {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .opacity(isHoveringIcons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHoveringIcons)
            .padding(10)
            .background(Color.white.opacity(0.0001))
            .onHover { isHoveringIcons = $0 }
        }
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

struct NowPlayingDot: View {
    let index: Int
    let isActive: Bool
    
    @State private var isAnimating = false
    
    private var peakHeight: CGFloat { [12, 16, 10][index % 3] }
    private var animDuration: Double { [0.32, 0.24, 0.38][index % 3] }
    
    var body: some View {
        Capsule()
            .fill(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            .frame(width: 3.5, height: isAnimating ? peakHeight : 4)
            .animation(
                isActive
                    ? Animation.easeInOut(duration: animDuration)
                        .repeatForever(autoreverses: true)
                    : Animation.easeOut(duration: 0.2),
                value: isAnimating
            )
            .onChange(of: isActive) { active in
                isAnimating = active
            }
            .onAppear {
                isAnimating = isActive
            }
    }
}

struct PlaceholderArt: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hue: 0.72, saturation: 0.6, brightness: 0.35), Color(hue: 0.58, saturation: 0.7, brightness: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: "music.note.tv").font(.system(size: 52, weight: .thin)).foregroundStyle(.white.opacity(0.25))
                Text("Nothing Playing").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.2))
            }
        }
    }
}

struct TransportControls: View {
    @EnvironmentObject var music: MusicController
    
    var body: some View {
        let isStandard = music.playerStyle == .standard
        let spacing: CGFloat = isStandard ? 24 : 12
        let shufRepWidth: CGFloat = isStandard ? 24 : 18
        let shufRepSize: CGFloat = isStandard ? 15 : 13
        
        HStack(spacing: spacing) {
            
            // Shuffle
            Button { music.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: shufRepSize, weight: .semibold))
                    .foregroundStyle(.white.opacity(music.isShuffleEnabled ? 1.0 : 0.35))
                    .shadow(color: music.isShuffleEnabled ? .white.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
            }
            .buttonStyle(.plain)
            .frame(width: shufRepWidth)
            
            TransportButton(icon: "backward.fill", size: isStandard ? 20 : 16, circleSize: isStandard ? 44 : 36) { music.previousTrack() }
            TransportButton(icon: music.isPlaying ? "pause.fill" : "play.fill", size: isStandard ? 26 : 22, circleSize: isStandard ? 58 : 46, isMain: true) { music.togglePlayPause() }
            TransportButton(icon: "forward.fill", size: isStandard ? 20 : 16, circleSize: isStandard ? 44 : 36) { music.nextTrack() }
            
            // Repeat
            Button { music.toggleRepeat() } label: {
                Image(systemName: music.repeatMode == "one" ? "repeat.1" : "repeat")
                    .font(.system(size: shufRepSize, weight: .semibold))
                    .foregroundStyle(.white.opacity(music.repeatMode != "off" ? 1.0 : 0.35))
                    .shadow(color: music.repeatMode != "off" ? .white.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
            }
            .buttonStyle(.plain)
            .frame(width: shufRepWidth)
        }
    }
}

struct TransportButton: View {
    let icon: String
    let size: CGFloat
    let circleSize: CGFloat
    var isMain: Bool = false
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white.opacity(isMain ? 0.22 : 0.12))
                    .frame(width: circleSize, height: circleSize)
                
                Image(systemName: icon)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain).contentShape(Circle())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in withAnimation(.easeInOut(duration: 0.08)) { pressed = true } }.onEnded { _ in withAnimation(.easeInOut(duration: 0.12)) { pressed = false } })
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Play Playlist Dropdown Panel
// ─────────────────────────────────────────────────────────────

struct PlayPlaylistButtonOnly: View {
    @EnvironmentObject var music: MusicController
    
    var body: some View {
        let isSpotify = music.targetPlayer == "Spotify"
        
        Button {
            music.playlistExpanded.toggle()
            if music.playlistExpanded && !isSpotify {
                music.refreshPlaylists()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSpotify ? "lock.fill" : "music.note.list")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(isSpotify ? 0.4 : 0.8))
                    .frame(width: 20)
                
                Text(isSpotify ? "Playlists Locked" : "Play Playlist")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(isSpotify ? 0.6 : 1.0))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSpotify ? 0.3 : 0.6))
                    .rotationEffect(.degrees(music.playlistExpanded && !isSpotify ? 180 : 0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(GlassPill())
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PlaylistListView: View {
    @EnvironmentObject var music: MusicController
    
    var body: some View {
        Group {
            if music.targetPlayer == "Spotify" {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.06))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Playlists Locked")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("Spotify restricts third-party apps\nfrom reading your library.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(music.playlists.enumerated()), id: \.element) { idx, pl in
                            PlaylistRow(name: pl) { music.playPlaylist(pl) }
                            
                            if idx < music.playlists.count - 1 {
                                Divider()
                                    .background(.white.opacity(0.1))
                                    .padding(.leading, 42)
                                    .padding(.trailing, 16)
                                    .padding(.vertical, 2)
                            }
                        }
                        if music.playlists.isEmpty {
                            HStack(spacing: 6) { ProgressView().scaleEffect(0.7); Text("Loading playlists…") }
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.vertical, 18)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

struct PlaylistRow: View {
    let name: String
    let action: () -> Void
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "music.note.list").font(.system(size: 13)).foregroundStyle(.white.opacity(0.6)).frame(width: 20)
                Text(name).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
                Spacer()
                Image(systemName: "play.circle.fill").font(.system(size: 13)).foregroundStyle(.white.opacity(hovered ? 0.8 : 0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(hovered ? Color.white.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovered)
    }
}

struct ToastView: View {
    let icon: String
    let iconColor: Color
    let message: String
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(iconColor).font(.system(size: 14))
            Text(message).font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
        )
    }
}

struct GlassPill: View {
    var body: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .overlay(
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                VStack {
                    LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 12)
                        .clipShape(Capsule())
                    Spacer()
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
}

struct LiquidGlassSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEditingChanged: ((Bool) -> Void)? = nil
    var height: CGFloat
    
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geo in
            let percent = max(0, min(1, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
            let fillWidth = max(0, geo.size.width * percent)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: fillWidth)
                    .animation(.interactiveSpring(response: 0.1, dampingFraction: 1.0), value: fillWidth)
            }
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .background(WindowDragBlocker())
            .contentShape(Capsule())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged?(true)
                        }
                        let p = max(0, min(1, val.location.x / geo.size.width))
                        value = range.lowerBound + p * (range.upperBound - range.lowerBound)
                    }
                    .onEnded { val in
                        let p = max(0, min(1, val.location.x / geo.size.width))
                        value = range.lowerBound + p * (range.upperBound - range.lowerBound)
                        isDragging = false
                        onEditingChanged?(false)
                    }
            )
        }
        .frame(height: height)
    }
}

struct FloatingVolumeHUD: View {
    @EnvironmentObject var music: MusicController

    var body: some View {
        if music.showVolumeIndicator {
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.8))
                
                LiquidGlassSlider(
                    value: Binding(
                        get: { music.volume },
                        set: {
                            music.setVolume(to: $0)
                            music.triggerVolumeHUD()
                        }
                    ),
                    range: 0...100,
                    height: 12
                )
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .frame(width: 220)
            .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        }
    }
}

struct StandardTrackInfoView: View {
    @EnvironmentObject var music: MusicController

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(music.trackName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            
            Text(music.artistName.isEmpty ? "—" : music.artistName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
    }
}

struct MiniTrackInfoView: View {
    @EnvironmentObject var music: MusicController

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(music.trackName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .truncationMode(.tail)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Text(music.artistName.isEmpty ? "—" : music.artistName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .truncationMode(.tail)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

struct PlaceholderArtBackground: View {
    var body: some View {
        ZStack {
            Color(white: 0.08)
            Image(systemName: "music.note")
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(.white.opacity(0.05))
        }
    }
}

struct ScrubberView: View {
    @EnvironmentObject var music: MusicController

    private func format(_ t: Double) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    var body: some View {
        VStack(spacing: 8) {
            LiquidGlassSlider(
                value: Binding(
                    get: { music.currentTime },
                    set: { music.currentTime = $0 }
                ),
                range: 0...max(music.duration, 1),
                onEditingChanged: { editing in
                    music.isScrubbing = editing
                    if !editing { music.seek(to: music.currentTime) }
                },
                height: 10
            )
            
            HStack {
                Text(format(music.currentTime))
                Spacer()
                Text(format(music.duration))
            }
            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.75))
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
        }
    }
}

struct WindowDragBlocker: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return NonDraggingView()
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class NonDraggingView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return false
    }
}

struct TrackpadSwipeDetector: NSViewRepresentable {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onScrollY: (CGFloat) -> Void
    
    func makeNSView(context: Context) -> TrackpadScrollTracker {
        let view = TrackpadScrollTracker()
        view.onSwipeLeft = onSwipeLeft
        view.onSwipeRight = onSwipeRight
        view.onScrollY = onScrollY
        return view
    }
    
    func updateNSView(_ nsView: TrackpadScrollTracker, context: Context) {
        nsView.onSwipeLeft = onSwipeLeft
        nsView.onSwipeRight = onSwipeRight
        nsView.onScrollY = onScrollY
    }
}

class TrackpadScrollTracker: NSView {
    enum ScrollAxis { case none, horizontal, vertical }
    
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    var onScrollY: ((CGFloat) -> Void)?
    
    private var accumulatedX: CGFloat = 0
    private let swipeThreshold: CGFloat = 40.0
    private var hasTriggered: Bool = false
    private var currentAxis: ScrollAxis = .none
    
    override func scrollWheel(with event: NSEvent) {
        if event.phase == .began || event.phase == .mayBegin {
            accumulatedX = 0
            hasTriggered = false
            currentAxis = .none
        }
        
        if currentAxis == .none {
            if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
                currentAxis = .horizontal
            } else if abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) {
                currentAxis = .vertical
            }
        }
        
        if currentAxis == .horizontal {
            guard !hasTriggered else {
                if event.phase == .ended || event.phase == .cancelled {
                    accumulatedX = 0
                    hasTriggered = false
                    currentAxis = .none
                }
                return
            }
            
            accumulatedX += event.scrollingDeltaX
            if accumulatedX < -swipeThreshold {
                onSwipeLeft?()
                hasTriggered = true
            } else if accumulatedX > swipeThreshold {
                onSwipeRight?()
                hasTriggered = true
            }
            
        } else if currentAxis == .vertical {
            onScrollY?(event.scrollingDeltaY)
        }
        
        if event.phase == .ended || event.phase == .cancelled {
            accumulatedX = 0
            hasTriggered = false
            currentAxis = .none
        }
    }
}
