# Musi

<p align="center">
  <img src="docs/images/musi-banner.png" alt="Musi banner" width="100%">
</p>

<p align="center">
  A focused, beautiful music controller for macOS.
</p>

<p align="center">
  <a href="https://github.com/mythreyen/Musi/stargazers"><img src="https://img.shields.io/github/stars/mythreyen/Musi?style=flat-square&color=8B5CF6" alt="GitHub stars"></a>
  <a href="https://github.com/mythreyen/Musi/issues"><img src="https://img.shields.io/github/issues/mythreyen/Musi?style=flat-square" alt="GitHub issues"></a>
  <a href="https://github.com/mythreyen/Musi/blob/main/LICENSE"><img src="https://img.shields.io/github/license/mythreyen/Musi?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS-111827?style=flat-square" alt="Platform: macOS">
</p>

> **Project status:** Early development. The core player experience is actively evolving.

## Overview

Musi is a lightweight menu-bar music controller designed for people who want immediate access to playback without opening a full-size music app. It provides a compact, always-available interface for Apple Music and Spotify, with album-art-driven visuals, global controls, configurable layouts, and live synchronized lyrics.

<p align="center">
  <img src="docs/images/musi-player.png" alt="Musi player window" width="720">
</p>

## Highlights

- **Three player layouts** - Standard, Mini, and Compact form factors for different workflows.
- **Apple Music and Spotify support** - Choose the active audio source in Preferences.
- **Global keyboard control** - Summon Musi with a configurable shortcut; use `Command` + `Shift` + `Space` to play or pause and the arrow keys to change tracks.
- **Live synchronized lyrics** - Fetches LRC lyrics and displays them in a dedicated, pinnable lyrics window.
- **Album-art-driven interface** - Artwork, transitions, and optional dynamic accent colors keep the player visually connected to the current track.
- **Desktop-friendly behavior** - Pin the player, lock its position, adjust opacity, and keep it available across Spaces and full-screen apps.
- **Playlist access** - Browse and start available playlists without leaving the player.
- **Native macOS interaction** - Menu-bar presence, swipe gestures, volume scrolling, playback toasts, and haptic feedback.

## Screenshots

Use this section for polished product screenshots. Replace the placeholder paths with committed images when they are available.

| Standard player | Mini player |
|:---:|:---:|
| <img src="docs/images/screenshot-standard.png" alt="Standard player layout" width="420"> | <img src="docs/images/screenshot-mini.png" alt="Mini player layout" width="420"> |

| Compact player | Live lyrics |
|:---:|:---:|
| <img src="docs/images/screenshot-compact.png" alt="Compact player layout" width="420"> | <img src="docs/images/screenshot-lyrics.png" alt="Live synchronized lyrics window" width="420"> |

## Requirements

- macOS 15.5 or later
- Xcode with Swift 5 support
- Apple Music and/or Spotify installed for playback integration

Musi uses macOS media automation and may ask for permission to control the selected player. Some global interaction features may also require Accessibility permission in **System Settings → Privacy & Security → Accessibility**.

## Getting started

### Build from source

1. Clone the repository:

   ```bash
   git clone https://github.com/mythreyen/Musi.git
   cd Musi
   ```

2. Open `Musi.xcodeproj` in Xcode.
3. Select the **Musi** scheme and a macOS destination.
4. Configure your Apple development team under **Signing & Capabilities**.
5. Build and run with `⌘R`.

### First launch

1. Choose **Apple Music** or **Spotify** in Preferences.
2. Grant the requested automation permissions.
3. Use the default global shortcut, `Command` + `Shift` + `M`, to show or hide the player.
4. Open the context menu to change the layout, pin the player, lock its position, or open Preferences.

## Architecture

Musi is a native SwiftUI and AppKit menu-bar application.

```text
AppDelegate
├── MusicBarPanel              Main floating player window
├── MusicBarPanel              Independent lyrics window
├── MusicController             Playback, artwork, playlists, lyrics, preferences
├── PlayerView                  Standard / Mini / Compact layout router
├── HotKeyManager               Configurable Carbon global shortcut
└── MenuBarAnimator / Meter     Menu-bar status and playback feedback
```

The project combines:

- **SwiftUI** for the player, preferences, playlists, and lyrics interfaces.
- **AppKit** for borderless floating panels, menu-bar integration, window behavior, and global event monitoring.
- **AppleScript automation** for reading playback state and controlling Apple Music or Spotify.
- **LRC lyrics API integration** for synchronized lyric retrieval.

## Project structure

```text
Musi/
├── AppDelegate.swift
├── MusicController.swift
├── PlayerView.swift
├── PreferencesView.swift
├── MusicBarPanel.swift
├── HotKeyManager.swift
├── AlbumColorExtractor.swift
└── Assets.xcassets
MusiTests/
MusiUITests/
Musi.xcodeproj/
```

## Roadmap

- [ ] Add a polished release distribution flow
- [ ] Expand automated unit and UI coverage
- [ ] Improve onboarding and permission guidance
- [ ] Add more playback providers
- [ ] Document the public configuration and customization surface

## Contributing

Contributions, design feedback, and bug reports are welcome. Before opening a pull request:

1. Create a focused branch from `main`.
2. Keep changes scoped and use the existing SwiftUI/AppKit patterns.
3. Run the relevant Xcode tests.
4. Include screenshots or a short recording for visual changes.

For bugs and feature requests, please [open an issue](https://github.com/mythreyen/Musi/issues) with the macOS version, Xcode version, selected player, reproduction steps, and any relevant logs.

## License

Musi is distributed under the terms of the [MIT License](LICENSE).

## Credits

Built for the Mac community by [Mythreyen Sakthivel](https://github.com/mythreyen).
