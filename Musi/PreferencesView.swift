import SwiftUI
import Carbon

// ─────────────────────────────────────────────────────────────
// MARK: Liquid Glass Settings View
// ─────────────────────────────────────────────────────────────

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    case about = "About"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .appearance: return "paintpalette.fill"
        case .shortcuts: return "keyboard.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct PreferencesView: View {
    @EnvironmentObject var music: MusicController
    @State private var selectedTab: SettingsTab = .general
    @Namespace private var tabAnimation

    var body: some View {
        ZStack {
            SettingsLiquidGlassBackground()
            
            VStack(spacing: 0) {
                // Header & Glass Tab Bar
                SettingsHeaderView(selectedTab: $selectedTab, tabAnimation: tabAnimation)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                Divider()
                    .overlay(Color.white.opacity(0.1))
                
                // Content Tab Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .general:
                            GeneralSettingsTab()
                        case .appearance:
                            AppearanceSettingsTab()
                        case .shortcuts:
                            ShortcutsSettingsTab()
                        case .about:
                            AboutSettingsTab()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                
                Spacer(minLength: 0)
                
                // Bottom Status Bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(music.isPlaying ? Color.green : Color.white.opacity(0.3))
                            .frame(width: 7, height: 7)
                        Text(music.isPlaying ? "Playing on \(music.resolvedPlayer)" : "Ready • \(music.resolvedPlayer)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    
                    Spacer()
                    
                    Text("Musi v1.0.0")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.2))
            }
        }
        .frame(width: 540, height: 600)
        .preferredColorScheme(.dark)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Settings Header & Navigation Bar
// ─────────────────────────────────────────────────────────────

struct SettingsHeaderView: View {
    @Binding var selectedTab: SettingsTab
    var tabAnimation: Namespace.ID

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Settings")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Customize your Musi experience")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                Button {
                    for window in NSApp.windows where window.title == "Musi Settings" {
                        window.close()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.1))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            
            // Liquid Glass Segmented Tab Bar
            HStack(spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 12, weight: .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .medium, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.white.opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "activeTabBadge", in: tabAnimation)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Tab 1: General Settings
// ─────────────────────────────────────────────────────────────

struct GeneralSettingsTab: View {
    @EnvironmentObject var music: MusicController
    @AppStorage("closeHidesPanel") private var closeHidesPanel = true

    var body: some View {
        VStack(spacing: 18) {
            // Audio Source Card
            LiquidGlassSection(title: "MUSIC SERVICE", subtitle: "Select your active music streaming provider") {
                HStack(spacing: 10) {
                    AudioServiceButton(
                        serviceName: "Auto Detect",
                        identifier: "Auto",
                        icon: "sparkles",
                        accentColor: .blue,
                        isSelected: music.targetPlayer == "Auto"
                    ) {
                        music.targetPlayer = "Auto"
                    }

                    AudioServiceButton(
                        serviceName: "Apple Music",
                        identifier: "Music",
                        icon: "music.note.house.fill",
                        accentColor: .pink,
                        isSelected: music.targetPlayer == "Music"
                    ) {
                        music.targetPlayer = "Music"
                    }
                    
                    AudioServiceButton(
                        serviceName: "Spotify",
                        identifier: "Spotify",
                        icon: "waveform.circle.fill",
                        accentColor: .green,
                        isSelected: music.targetPlayer == "Spotify"
                    ) {
                        music.targetPlayer = "Spotify"
                    }
                }
                .padding(14)
            }
            
            // Behavior & Window Actions Card
            LiquidGlassSection(title: "WINDOW BEHAVIOR") {
                VStack(spacing: 0) {
                    LiquidGlassToggleRow(
                        icon: "eye.slash.fill",
                        iconColor: .blue,
                        title: "Close Button Hides Musi",
                        subtitle: "Keeps Musi running smoothly in the menu bar",
                        isOn: $closeHidesPanel
                    )
                    
                    Divider().overlay(.white.opacity(0.08)).padding(.leading, 50)
                    
                    LiquidGlassToggleRow(
                        icon: "link",
                        iconColor: .purple,
                        title: "Magnetic Lyrics Docking",
                        subtitle: "Auto-snap lyrics window alongside the main player",
                        isOn: $music.isLyricsMagnetic
                    )
                    
                    Divider().overlay(.white.opacity(0.08)).padding(.leading, 50)
                    
                    LiquidGlassToggleRow(
                        icon: "lock.fill",
                        iconColor: .orange,
                        title: "Lock Player Window Position",
                        subtitle: "Prevent dragging or accidental relocation",
                        isOn: $music.isWindowLocked
                    )
                    
                    Divider().overlay(.white.opacity(0.08)).padding(.leading, 50)
                    
                    LiquidGlassToggleRow(
                        icon: "lock.shield.fill",
                        iconColor: .yellow,
                        title: "Lock Lyrics Window Position",
                        subtitle: "Keep lyrics anchored to its desktop coordinates",
                        isOn: $music.isLyricsWindowLocked
                    )
                }
            }
            
            // Playback Options Card
            LiquidGlassSection(title: "PLAYBACK INTERACTION") {
                VStack(spacing: 0) {
                    LiquidGlassToggleRow(
                        icon: "playpause.fill",
                        iconColor: .cyan,
                        title: "Show Playback Controls",
                        subtitle: "Display rewind, play/pause, and skip transport buttons",
                        isOn: $music.showPlaybackControls
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Tab 2: Appearance Settings
// ─────────────────────────────────────────────────────────────

struct AppearanceSettingsTab: View {
    @EnvironmentObject var music: MusicController
    @AppStorage("useAlbumColor") private var useAlbumColor = true

    var body: some View {
        VStack(spacing: 18) {
            // Form Factor Picker
            LiquidGlassSection(title: "DEFAULT PLAYER FORM FACTOR", subtitle: "Choose your primary player layout") {
                HStack(spacing: 12) {
                    ForEach(PlayerStyle.allCases, id: \.self) { style in
                        LayoutOptionCard(
                            style: style,
                            isSelected: music.playerStyle == style
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                music.playerStyle = style
                            }
                        }
                    }
                }
                .padding(14)
            }
            
            // Ambient Aesthetic
            LiquidGlassSection(title: "LIQUID GLASS AESTHETICS") {
                VStack(spacing: 0) {
                    LiquidGlassToggleRow(
                        icon: "paintpalette.fill",
                        iconColor: .pink,
                        title: "Dynamic Album Colors",
                        subtitle: "Extract vibrant ambient tinting from active album art",
                        isOn: $useAlbumColor
                    )
                    
                    Divider().overlay(.white.opacity(0.08)).padding(.leading, 50)
                    
                    LiquidGlassSliderRow(
                        icon: "square.dashed",
                        iconColor: .teal,
                        title: "Desktop Pinned Opacity",
                        subtitle: "Transparency level when player is pinned to wallpaper",
                        value: $music.pinnedOpacity,
                        range: 0.2...1.0
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Tab 3: Shortcuts & Gestures
// ─────────────────────────────────────────────────────────────

struct ShortcutsSettingsTab: View {
    var body: some View {
        VStack(spacing: 18) {
            // Global Summon Shortcut
            LiquidGlassSection(title: "GLOBAL SHORTCUT", subtitle: "Summon Musi instantly from any desktop or app") {
                GlassHotKeyRecorderRow(
                    icon: "keyboard.fill",
                    title: "Summon Player Window",
                    subtitle: "Default: ⌘ + Shift + M"
                )
            }
            
            // Multi-Directional Gestures Guide
            LiquidGlassSection(title: "MENU BAR TRACKPAD GESTURES") {
                VStack(alignment: .leading, spacing: 12) {
                    GestureGuideRow(
                        icon: "arrow.left.and.right",
                        title: "Horizontal Swipe on Status Icon",
                        description: "Swipe left or right over the menu bar to jump between tracks."
                    )
                    
                    Divider().overlay(.white.opacity(0.08))
                    
                    GestureGuideRow(
                        icon: "arrow.down",
                        title: "Swipe Down from Menu Bar",
                        description: "Smoothly drops down the compact now-playing controller."
                    )
                    
                    Divider().overlay(.white.opacity(0.08))
                    
                    GestureGuideRow(
                        icon: "arrow.up",
                        title: "Swipe Up towards Menu Bar",
                        description: "Instantly tucks away the active player panel."
                    )
                }
                .padding(14)
            }
            
            // Keyboard Shortcuts Reference
            LiquidGlassSection(title: "MEDIA HOTKEYS REFERENCE") {
                VStack(spacing: 8) {
                    ShortcutBadgeRow(keys: ["⌘", "⇧", "Space"], action: "Play / Pause Toggle")
                    ShortcutBadgeRow(keys: ["⌘", "⇧", "→"], action: "Next Track")
                    ShortcutBadgeRow(keys: ["⌘", "⇧", "←"], action: "Previous Track")
                    ShortcutBadgeRow(keys: ["⌘", ","], action: "Open Settings")
                    ShortcutBadgeRow(keys: ["⌘", "L"], action: "Toggle Lyrics Panel")
                }
                .padding(14)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Tab 4: About Settings
// ─────────────────────────────────────────────────────────────

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                Text("Musi")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Version 1.0.0 (Build 1)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text("Native macOS Liquid Glass Menu Bar Companion for Apple Music & Spotify.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: 380)
            }
            .padding(.top, 10)
            
            LiquidGlassSection(title: "CREDITS & REPOSITORY") {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Created by")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Mythreyen Sakthivel")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Button {
                            if let url = URL(string: "https://github.com/mythreyen") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text("GitHub Profile")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.white.opacity(0.12)))
                                .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider().overlay(.white.opacity(0.08))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Source")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("mythreyen/musi")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Button {
                            if let url = URL(string: "https://github.com/mythreyen/musi") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                Text("View Repo")
                            }
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.white.opacity(0.12)))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Custom Liquid Glass Components
// ─────────────────────────────────────────────────────────────

struct LiquidGlassSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct AudioServiceButton: View {
    let serviceName: String
    let identifier: String
    let icon: String
    let accentColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.3) : .white.opacity(0.08))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? accentColor : .white.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                    Text(isSelected ? "Active Provider" : "Available")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? accentColor : .white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? accentColor : .white.opacity(0.2))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.12) : .white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? accentColor.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LayoutOptionCard: View {
    let style: PlayerStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.06))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(isSelected ? .white.opacity(0.4) : .white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Image(systemName: style.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                }
                
                Text(style.displayName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.14) : .white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? .white.opacity(0.45) : .white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LiquidGlassToggleRow: View {
    let icon: String
    var iconColor: Color = .white
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.purple.opacity(0.8)))
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct LiquidGlassSliderRow: View {
    let icon: String
    var iconColor: Color = .white
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Slider(value: $value, in: range)
                    .controlSize(.small)
                    .tint(.purple)
                    .frame(width: 90)
                
                Text("\(Int(value * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 38, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct GestureGuideRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineSpacing(2)
            }
        }
    }
}

struct ShortcutBadgeRow: View {
    let keys: [String]
    let action: String

    var body: some View {
        HStack {
            Text(action)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.white.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Hotkey Recorder
// ─────────────────────────────────────────────────────────────

struct GlassHotKeyRecorderRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    @State private var isRecording = false
    @AppStorage("hotkeyCode") private var hotkeyCode = kVK_ANSI_M
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers = (cmdKey | shiftKey)
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            
            Spacer()
            
            Button {
                isRecording.toggle()
                if isRecording {
                    HotKeyManager.shared.unregisterCurrentHotKey()
                } else {
                    HotKeyManager.shared.registerSavedHotKey()
                }
            } label: {
                Text(isRecording ? "Press Shortcut..." : currentComboString)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isRecording ? Color.red.opacity(0.5) : Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .foregroundStyle(isRecording ? .red : .white)
            }
            .buttonStyle(.plain)
            .background(KeyEventResponder(isRecording: $isRecording, onRecord: { code, mods in
                self.hotkeyCode = code
                self.hotkeyModifiers = mods
                self.isRecording = false
                HotKeyManager.shared.registerSavedHotKey()
            }))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private var currentComboString: String {
        let modSymbols = HotKeyManager.stringForModifiers(hotkeyModifiers)
        let keySymbol = HotKeyManager.stringForKeyCode(hotkeyCode)
        return modSymbols + keySymbol
    }
}

struct KeyEventResponder: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onRecord: (Int, Int) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ResponderNSView()
        view.onKeyEvent = { event in
            guard isRecording else { return }
            
            let code = Int(event.keyCode)
            var carbonMods = 0
            
            if event.modifierFlags.contains(.command) { carbonMods |= cmdKey }
            if event.modifierFlags.contains(.shift) { carbonMods |= shiftKey }
            if event.modifierFlags.contains(.option) { carbonMods |= optionKey }
            if event.modifierFlags.contains(.control) { carbonMods |= controlKey }
            
            guard carbonMods != 0 else { return }
            
            if code != 54 && code != 55 && code != 56 && code != 59 && code != 60 && code != 61 && code != 62 {
                onRecord(code, carbonMods)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

class ResponderNSView: NSView {
    var onKeyEvent: ((NSEvent) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        onKeyEvent?(event)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Liquid Glass Background for Settings Window
// ─────────────────────────────────────────────────────────────

struct SettingsLiquidGlassBackground: View {
    var body: some View {
        ZStack {
            // macOS Ultra Thin Translucent Material
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // Obsidian dark glass wash
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.14).opacity(0.85),
                    Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.multiply)
            
            // Subtle ambient specular sheen along top edge
            VStack {
                LinearGradient(
                    colors: [.white.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Dual-tone specular glass border
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}
