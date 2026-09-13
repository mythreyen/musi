import SwiftUI
import Carbon

struct PreferencesView: View {
    @EnvironmentObject var music: MusicController
    
    @AppStorage("closeHidesPanel") private var closeHidesPanel = true
    @AppStorage("useAlbumColor") private var useAlbumColor = true

    var body: some View {
        ZStack {
            SettingsGlassBackground()
                .allowsHitTesting(false)
            
            VStack(spacing: 24) {
                HStack {
                    Text("Preferences")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button {
                        NSApp.keyWindow?.close()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    SettingsSection(title: "BEHAVIOR") {
                        GlassStringPickerRow(
                            icon: "hifispeaker.fill",
                            title: "Audio Source",
                            subtitle: "Select Apple Music or Spotify",
                            selection: $music.targetPlayer,
                            options: [("Apple Music", "Music"), ("Spotify", "Spotify")]
                        )
                        
                        Divider().background(.white.opacity(0.1)).padding(.leading, 42)
                        
                        GlassToggleRow(
                            icon: "eye.slash.fill",
                            title: "Close Button Hides App",
                            subtitle: "Keeps MusicBar running in the background",
                            isOn: $closeHidesPanel
                        )
                        
                        Divider().background(.white.opacity(0.1)).padding(.leading, 42)
                        
                        GlassHotKeyRecorderRow(
                            icon: "keyboard.fill",
                            title: "Global Shortcut",
                            subtitle: "Summon application window system-wide"
                        )
                    }
                    
                    SettingsSection(title: "APPEARANCE") {
                        GlassToggleRow(
                            icon: "paintpalette.fill",
                            title: "Dynamic Album Colors",
                            subtitle: "Tint the Mini player using album artwork",
                            isOn: $useAlbumColor
                        )
                        
                        Divider().background(.white.opacity(0.1)).padding(.leading, 42)
                        
                        GlassToggleRow(
                            icon: "playpause.fill",
                            title: "Playback Controls",
                            subtitle: "Show the rewind, play, and skip buttons",
                            isOn: $music.showPlaybackControls
                        )
                        
                        Divider().background(.white.opacity(0.1)).padding(.leading, 42)
                        
                        GlassSliderRow(
                            icon: "square.dashed",
                            title: "Pinned Transparency",
                            subtitle: "Adjust opacity when pinned to desktop",
                            value: $music.pinnedOpacity,
                            range: 0.2...1.0
                        )
                        
                        Divider().background(.white.opacity(0.1)).padding(.leading, 42)
                        
                        GlassLayoutPickerRow(
                            icon: "rectangle.3.group.fill",
                            title: "Default Layout",
                            selection: $music.playerStyle
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text("MusicBar 4.0")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 400, height: 660)
        .edgesIgnoringSafeArea(.all)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: Custom Settings Components
// ─────────────────────────────────────────────────────────────

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.leading, 12)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

struct GlassStringPickerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [(String, String)]
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.1) { option in
                    Text(option.0).tag(option.1)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(width: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct GlassSliderRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Slider(value: $value, in: range)
                .controlSize(.small)
                .tint(.white)
                .frame(width: 100)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct GlassToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .white.opacity(0.7)))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct GlassLayoutPickerRow: View {
    let icon: String
    let title: String
    @Binding var selection: PlayerStyle
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            
            Spacer()
            
            Picker("", selection: $selection) {
                Text("Standard").tag(PlayerStyle.standard)
                Text("Mini").tag(PlayerStyle.mini)
                Text("Compact").tag(PlayerStyle.compact)
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(width: 110)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct GlassHotKeyRecorderRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    @State private var isRecording = false
    @AppStorage("hotkeyCode") private var hotkeyCode = kVK_ANSI_M
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers = (cmdKey | shiftKey)
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
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
                    .background(RoundedRectangle(cornerRadius: 8).fill(isRecording ? Color.red.opacity(0.25) : Color.white.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(isRecording ? 0.4 : 0.2)))
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
// MARK: Liquid Glass Background for Settings
// ─────────────────────────────────────────────────────────────

struct SettingsGlassBackground: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.12, opacity: 0.8), Color(red: 0.05, green: 0.05, blue: 0.07, opacity: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.multiply)
            
            VStack {
                LinearGradient(
                    colors: [.white.opacity(0.12), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}
