import AppKit
import Combine
import SwiftUI

enum PlayerStyle: Int, CaseIterable {
    case standard = 0
    case mini = 1
    case compact = 2
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .mini: return "Mini"
        case .compact: return "Compact"
        }
    }
    
    var iconName: String {
        switch self {
        case .standard: return "rectangle.portrait.fill"
        case .mini: return "rectangle.fill"
        case .compact: return "square.fill"
        }
    }
}

struct LyricLine: Identifiable, Hashable {
    let id = UUID()
    let time: Double
    let text: String
}

class MusicController: ObservableObject {
    // Playback state
    @Published var isPlaying      = false
    @Published var trackName      = "Not Playing"
    @Published var artistName     = ""
    @Published var albumName      = ""
    @Published var albumArt: NSImage? = nil
    @Published var duration: Double    = 1
    @Published var volume: Double      = 50
    @Published var isScrubbing    = false
    @Published var isMusicRunning = false
    @Published var playlists: [String] = []
    
    @Published var currentTime: Double = 0 {
        didSet { updateActiveLyric() }
    }
    
    // Shuffle & Repeat State
    @Published var isShuffleEnabled: Bool = false
    @Published var repeatMode: String = "off"
    
    // Live LRC Synced Lyrics State
    @Published var lyrics: [LyricLine]? = nil
    @Published var activeLyricIndex: Int? = nil
    @Published var isFetchingLyrics: Bool = false
    @Published var showLyrics: Bool = false {
        didSet {
            if showLyrics && lyrics == nil && !isFetchingLyrics && !trackName.isEmpty && trackName != "Not Playing" {
                fetchLyrics(track: trackName, artist: artistName, duration: duration)
            }
        }
    }
    
    // Independent Lyrics Window State
    @Published var isLyricsPinned: Bool = UserDefaults.standard.bool(forKey: "isLyricsPinned") {
        didSet { UserDefaults.standard.set(isLyricsPinned, forKey: "isLyricsPinned") }
    }
    @Published var isLyricsWindowLocked: Bool = UserDefaults.standard.bool(forKey: "isLyricsWindowLocked") {
        didSet { UserDefaults.standard.set(isLyricsWindowLocked, forKey: "isLyricsWindowLocked") }
    }
    @Published var isLyricsMagnetic: Bool = UserDefaults.standard.object(forKey: "isLyricsMagnetic") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isLyricsMagnetic, forKey: "isLyricsMagnetic") }
    }
    
    // Toasts and Animation State
    @Published var lastPlayedPlaylist: String? = nil
    @Published var playPlaylistFailed: Bool = false
    @Published var playbackToastMessage: String? = nil
    @Published var playbackToastIcon: String = ""
    @Published var trackToastMessage: String? = nil
    @Published var lastTrackName = ""
    
    @Published var playlistExpanded: Bool  = false
    @Published var isPinned: Bool = false
    @Published var dominantColor: NSColor = NSColor(hue: 0.72, saturation: 0.45, brightness: 0.45, alpha: 1)
    
    // Sleep Timer State
    @Published var sleepTimerRemaining: Int? = nil
    private var sleepTimer: Timer?
    
    // HUD & Throttle State
    @Published var showVolumeIndicator = false
    private var volumeHideWorkItem: DispatchWorkItem?
    private var lastVolumeSyncTime: Date = .distantPast
    private var pendingVolumeSync: DispatchWorkItem?
    private var playbackToastWorkItem: DispatchWorkItem?
    private var trackToastWorkItem: DispatchWorkItem?
    
    // 🔥 NEW: Haptic Engine State Tracker
    private var hasHitVolumeEdge = false
    
    // Form Factor, Lock State & Controls Visibility
    @Published var playerStyle: PlayerStyle = PlayerStyle(rawValue: UserDefaults.standard.integer(forKey: "playerStyle")) ?? .standard {
        didSet { UserDefaults.standard.set(playerStyle.rawValue, forKey: "playerStyle") }
    }
    
    @Published var isWindowLocked: Bool = UserDefaults.standard.bool(forKey: "isWindowLocked") {
        didSet { UserDefaults.standard.set(isWindowLocked, forKey: "isWindowLocked") }
    }
    
    @Published var showPlaybackControls: Bool = UserDefaults.standard.object(forKey: "showPlaybackControls") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showPlaybackControls, forKey: "showPlaybackControls") }
    }
    
    @Published var pinnedOpacity: Double = UserDefaults.standard.object(forKey: "pinnedOpacity") as? Double ?? 1.0 {
        didSet { UserDefaults.standard.set(pinnedOpacity, forKey: "pinnedOpacity") }
    }
    
    @Published var targetPlayer: String = UserDefaults.standard.string(forKey: "targetPlayer") ?? "Auto" {
        didSet {
            UserDefaults.standard.set(targetPlayer, forKey: "targetPlayer")
            lastTrackName = ""
            albumArt = nil
            lyrics = nil
            activeLyricIndex = nil
            pollState()
            refreshPlaylists()
        }
    }

    @Published var resolvedPlayer: String = "Spotify"
    private var lastActivePlayer: String = "Spotify"

    func determinePlayerToPoll() -> String {
        if targetPlayer == "Music" { return "Music" }
        if targetPlayer == "Spotify" { return "Spotify" }
        
        let spotRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty
        let musicRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
        
        if spotRunning && !musicRunning {
            return "Spotify"
        } else if musicRunning && !spotRunning {
            return "Music"
        } else if spotRunning && musicRunning {
            return lastActivePlayer
        } else {
            return lastActivePlayer
        }
    }

    private var scrubberTimer: Timer?
    private var syncTimer: Timer?
    private let queue = DispatchQueue(label: "com.musicbar.as", qos: .userInitiated)

    init() {
        setupObservers()
        startScrubberTimer()
        pollState()
        refreshPlaylists()
    }

    // MARK: – Event-Driven Engine
    
    private func setupObservers() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePlaybackChange),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePlaybackChange),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }
    
    @objc private func handlePlaybackChange(_ notification: Notification) {
        if notification.name.rawValue == "com.spotify.client.PlaybackStateChanged" {
            lastActivePlayer = "Spotify"
            if targetPlayer == "Auto" {
                DispatchQueue.main.async { [weak self] in
                    self?.resolvedPlayer = "Spotify"
                }
            }
        } else if notification.name.rawValue == "com.apple.Music.playerInfo" {
            lastActivePlayer = "Music"
            if targetPlayer == "Auto" {
                DispatchQueue.main.async { [weak self] in
                    self?.resolvedPlayer = "Music"
                }
            }
        }
        pollState()
    }
    
    private func startScrubberTimer() {
        scrubberTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPlaying && !self.isScrubbing {
                self.currentTime += 0.1
                if self.currentTime > self.duration {
                    self.currentTime = self.duration
                }
            }
        }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollState()
        }
        
        RunLoop.main.add(scrubberTimer!, forMode: .common)
        RunLoop.main.add(syncTimer!, forMode: .common)
    }

    private func pollState() {
        queue.async { [weak self] in
            guard let self else { return }
            
            let appName = self.determinePlayerToPoll()
            DispatchQueue.main.async { [weak self] in
                if self?.resolvedPlayer != appName {
                    self?.resolvedPlayer = appName
                }
            }

            let src: String
            if appName == "Spotify" {
                src = """
                if application "Spotify" is running then
                    tell application "Spotify"
                        set pState to player state as string
                        set vol    to (sound volume) as string
                        set shuf   to shuffling as string
                        if repeating then
                            set rep to "all"
                        else
                            set rep to "off"
                        end if
                        try
                            set tName   to name of current track
                            set tArtist to artist of current track
                            set tAlbum  to album of current track
                            set tDur    to (duration of current track) as string
                            set tPos    to (player position) as string
                            return "1|" & pState & "|" & tName & "|" & tArtist & "|" & tAlbum & "|" & tDur & "|" & tPos & "|" & vol & "|" & shuf & "|" & rep
                        on error
                            return "1|" & pState & "||||0|0|" & vol & "|" & shuf & "|" & rep
                        end try
                    end tell
                else
                    return "0|stopped||||0|0|50|false|off"
                end if
                """
            } else {
                src = """
                if application "Music" is running then
                    tell application "Music"
                        set pState to player state as string
                        set vol    to (sound volume) as string
                        set shuf   to shuffle enabled as string
                        set rep    to song repeat as string
                        try
                            set tName   to name of current track
                            set tArtist to artist of current track
                            set tAlbum  to album of current track
                            set tDur    to (duration of current track) as string
                            set tPos    to (player position) as string
                            return "1|" & pState & "|" & tName & "|" & tArtist & "|" & tAlbum & "|" & tDur & "|" & tPos & "|" & vol & "|" & shuf & "|" & rep
                        on error
                            return "1|" & pState & "||||0|0|" & vol & "|" & shuf & "|" & rep
                        end try
                    end tell
                else
                    return "0|stopped||||0|0|50|false|off"
                end if
                """
            }

            let raw = self.runString(src) ?? "0|stopped||||0|0|50|false|off"
            var parts = raw.components(separatedBy: "|")
            while parts.count > 10 { parts[2] += "|" + parts.remove(at: 3) }
            guard parts.count == 10 else { return }

            let running = parts[0] == "1"
            let playing = parts[1] == "playing"
            let name    = parts[2]
            let artist  = parts[3]
            let album   = parts[4]
            var dur     = Double(parts[5]) ?? 0
            let pos     = Double(parts[6]) ?? 0
            let vol     = Double(parts[7]) ?? 50
            let shuf    = parts[8] == "true"
            let rep     = parts[9]
            
            if appName == "Spotify" && dur > 500 {
                dur = dur / 1000.0
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.isMusicRunning   = running
                self.isPlaying        = playing
                self.trackName        = name.isEmpty ? "Not Playing" : name
                self.artistName       = artist
                self.albumName        = album
                self.duration         = dur > 0 ? dur : 1
                self.isShuffleEnabled = shuf
                self.repeatMode       = rep
                
                if !self.showVolumeIndicator { self.volume = vol }
                
                if !self.isScrubbing {
                    if abs(self.currentTime - pos) > 0.6 {
                        self.currentTime = pos
                    }
                }

                if name != self.lastTrackName {
                    let oldName = self.lastTrackName
                    self.lastTrackName = name
                    self.queue.async { [weak self] in self?.fetchArtwork() }
                    
                    self.fetchLyrics(track: name, artist: artist, duration: dur)
                    
                    if !oldName.isEmpty && !name.isEmpty && name != "Not Playing" {
                        self.showTrackToast(message: name)
                    }
                } else if self.albumArt == nil && playing && !name.isEmpty && name != "Not Playing" {
                    self.queue.async { [weak self] in self?.fetchArtwork() }
                }
            }
        }
    }

    // MARK: – LRC Live Lyrics Engine
    
    private func sanitizeTrackName(_ title: String) -> String {
        var cleaned = title
        cleaned = cleaned.replacingOccurrences(of: #"\s*[\(\[](feat\.|ft\.|with).*?[\)\]]"#, with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: #"\s*-\s*(remaster(ed)?(\s*\d+)?|live|radio edit|single version|deluxe edition|bonus track).*$"#, with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: #"\s*[\(\[](explicit|clean)[\)\]]"#, with: "", options: [.regularExpression, .caseInsensitive])
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func fetchLyrics(track: String, artist: String, duration: Double) {
        guard !track.isEmpty && track != "Not Playing" else {
            DispatchQueue.main.async {
                self.lyrics = nil
                self.activeLyricIndex = nil
                self.isFetchingLyrics = false
            }
            return
        }

        DispatchQueue.main.async {
            self.lyrics = nil
            self.activeLyricIndex = nil
            self.isFetchingLyrics = true
        }
        
        let rawTrack = track.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTrack = sanitizeTrackName(rawTrack)
        let dur = Int(duration)
        
        // Stage 1: Try exact /api/get with duration and original track name
        var comp1 = URLComponents(string: "https://lrclib.net/api/get")
        var items1 = [
            URLQueryItem(name: "track_name", value: rawTrack),
            URLQueryItem(name: "artist_name", value: rawArtist)
        ]
        if dur > 0 {
            items1.append(URLQueryItem(name: "duration", value: "\(dur)"))
        }
        comp1?.queryItems = items1
        
        guard let url1 = comp1?.url else {
            DispatchQueue.main.async { self.isFetchingLyrics = false }
            return
        }
        
        URLSession.shared.dataTask(with: url1) { [weak self] data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["statusCode"] as? Int != 404 {
                if self?.applyLyricsJSON(json) == true {
                    return
                }
            }
            
            // Stage 2: Try /api/get with sanitized track name
            var comp2 = URLComponents(string: "https://lrclib.net/api/get")
            var items2 = [
                URLQueryItem(name: "track_name", value: cleanTrack),
                URLQueryItem(name: "artist_name", value: rawArtist)
            ]
            if dur > 0 {
                items2.append(URLQueryItem(name: "duration", value: "\(dur)"))
            }
            comp2?.queryItems = items2
            
            guard let url2 = comp2?.url else {
                self?.performLyricsSearch(track: cleanTrack, artist: rawArtist)
                return
            }
            
            URLSession.shared.dataTask(with: url2) { [weak self] data2, response2, error2 in
                if let data2 = data2,
                   let json2 = try? JSONSerialization.jsonObject(with: data2) as? [String: Any],
                   json2["statusCode"] as? Int != 404 {
                    if self?.applyLyricsJSON(json2) == true {
                        return
                    }
                }
                
                // Stage 3: Try /api/search with sanitized track name & artist
                self?.performLyricsSearch(track: cleanTrack, artist: rawArtist)
            }.resume()
        }.resume()
    }
    
    private func performLyricsSearch(track: String, artist: String) {
        var comp = URLComponents(string: "https://lrclib.net/api/search")
        comp?.queryItems = [
            URLQueryItem(name: "track_name", value: track),
            URLQueryItem(name: "artist_name", value: artist)
        ]
        
        guard let url = comp?.url else {
            DispatchQueue.main.async { self.isFetchingLyrics = false }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil,
                  let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !results.isEmpty else {
                self?.performGenericLyricsSearch(query: "\(artist) \(track)")
                return
            }
            
            // Prefer a result with syncedLyrics
            if let syncedResult = results.first(where: {
                if let s = $0["syncedLyrics"] as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
                return false
            }) {
                if self?.applyLyricsJSON(syncedResult) == true { return }
            }
            
            // Fallback to first result with plainLyrics
            if let plainResult = results.first(where: {
                if let p = $0["plainLyrics"] as? String, !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
                return false
            }) {
                if self?.applyLyricsJSON(plainResult) == true { return }
            }
            
            self?.performGenericLyricsSearch(query: "\(artist) \(track)")
        }.resume()
    }

    private func performGenericLyricsSearch(query: String) {
        var comp = URLComponents(string: "https://lrclib.net/api/search")
        comp?.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        guard let url = comp?.url else {
            DispatchQueue.main.async { self.isFetchingLyrics = false }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            defer { DispatchQueue.main.async { self?.isFetchingLyrics = false } }
            guard let data = data,
                  let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !results.isEmpty else {
                return
            }
            
            if let syncedResult = results.first(where: {
                if let s = $0["syncedLyrics"] as? String, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
                return false
            }) {
                _ = self?.applyLyricsJSON(syncedResult)
                return
            }
            
            if let plainResult = results.first(where: {
                if let p = $0["plainLyrics"] as? String, !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
                return false
            }) {
                _ = self?.applyLyricsJSON(plainResult)
                return
            }
        }.resume()
    }

    @discardableResult
    private func applyLyricsJSON(_ json: [String: Any]) -> Bool {
        if let syncedLyrics = json["syncedLyrics"] as? String, !syncedLyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let parsed = self.parseLRC(syncedLyrics)
            if !parsed.isEmpty {
                DispatchQueue.main.async {
                    self.lyrics = parsed
                    self.isFetchingLyrics = false
                }
                return true
            }
        }
        
        if let plainLyrics = json["plainLyrics"] as? String, !plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanPlain = plainLyrics.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            let lines = cleanPlain.components(separatedBy: "\n").map { LyricLine(time: -1, text: $0) }
            DispatchQueue.main.async {
                self.lyrics = lines
                self.isFetchingLyrics = false
            }
            return true
        }
        
        return false
    }
    
    private func parseLRC(_ lrc: String) -> [LyricLine] {
        var parsed: [LyricLine] = []
        let lines = lrc.components(separatedBy: .newlines)
        let regex = try? NSRegularExpression(pattern: "\\[(\\d+):(\\d+(?:\\.\\d+)?)\\](.*)")
        
        for line in lines {
            let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex?.firstMatch(in: line, options: [], range: nsRange) {
                if let minRange = Range(match.range(at: 1), in: line),
                   let secRange = Range(match.range(at: 2), in: line),
                   let textRange = Range(match.range(at: 3), in: line) {
                    
                    let min = Double(line[minRange]) ?? 0
                    let sec = Double(line[secRange]) ?? 0
                    let rawText = String(line[textRange]).trimmingCharacters(in: .whitespaces)
                    
                    let text = rawText.isEmpty ? "•••" : rawText
                    parsed.append(LyricLine(time: (min * 60) + sec, text: text))
                }
            }
        }
        return parsed
    }
    
    private func updateActiveLyric() {
        guard let lyrics = lyrics else { return }
        
        let offsetTime = currentTime + 0.35
        
        if let index = lyrics.lastIndex(where: { $0.time != -1 && $0.time <= offsetTime }) {
            if activeLyricIndex != index {
                activeLyricIndex = index
            }
        } else if lyrics.first?.time == -1 {
            activeLyricIndex = nil
        } else {
            activeLyricIndex = -1
        }
    }

    // MARK: – Artwork & Memory Optimization
    
    private func compressImage(_ image: NSImage) -> NSImage {
        let maxSize: CGFloat = 600
        let size = image.size
        let ratio = max(size.width, size.height) / maxSize
        if ratio <= 1.0 { return image }
        
        let newSize = NSSize(width: size.width / ratio, height: size.height / ratio)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
    private func fetchFallbackArtwork(track: String, artist: String) {
        let cleanTrack = sanitizeTrackName(track)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanTrack.isEmpty else {
            DispatchQueue.main.async { [weak self] in self?.albumArt = nil }
            return
        }
        
        var comp = URLComponents(string: "https://itunes.apple.com/search")
        comp?.queryItems = [
            URLQueryItem(name: "term", value: "\(cleanArtist) \(cleanTrack)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "5")
        ]
        
        guard let url = comp?.url else {
            DispatchQueue.main.async { [weak self] in self?.albumArt = nil }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { [weak self] in self?.albumArt = nil }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]], !results.isEmpty {
                
                var bestMatchUrl: String? = nil
                let cleanTargetTrack = cleanTrack.lowercased()
                let cleanTargetArtist = cleanArtist.lowercased()
                
                for result in results {
                    let resultTrack = (result["trackName"] as? String ?? "").lowercased()
                    let resultArtist = (result["artistName"] as? String ?? "").lowercased()
                    
                    let trackMatches = resultTrack.contains(cleanTargetTrack) || cleanTargetTrack.contains(resultTrack)
                    let artistMatches = resultArtist.contains(cleanTargetArtist) || cleanTargetArtist.contains(resultArtist)
                    
                    if trackMatches && artistMatches {
                        bestMatchUrl = result["artworkUrl100"] as? String
                        break
                    }
                }
                
                let artworkUrl = bestMatchUrl ?? (results.first?["artworkUrl100"] as? String)
                
                guard let finalUrl = artworkUrl else {
                    DispatchQueue.main.async { [weak self] in self?.albumArt = nil }
                    return
                }
                
                let hdUrlString = finalUrl.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                guard let hdUrl = URL(string: hdUrlString) else { return }
                
                URLSession.shared.dataTask(with: hdUrl) { [weak self] imgData, _, _ in
                    guard let imgData = imgData, let image = NSImage(data: imgData) else {
                        DispatchQueue.main.async { [weak self] in self?.albumArt = nil }
                        return
                    }
                    
                    let compressed = self?.compressImage(image) ?? image
                    let color = AlbumColorExtractor.extract(from: compressed)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.albumArt = compressed
                        self?.dominantColor = color
                    }
                }.resume()
            } else {
                DispatchQueue.main.async { [weak self] in self?.albumArt = nil }
            }
        }.resume()
    }
    
    func fetchArtwork() {
        let appName = self.resolvedPlayer
        let currentTrack = self.trackName
        let currentArtist = self.artistName
        
        guard !currentTrack.isEmpty && currentTrack != "Not Playing" else {
            DispatchQueue.main.async { [weak self] in
                self?.albumArt = nil
                self?.dominantColor = NSColor(hue: 0.72, saturation: 0.45, brightness: 0.45, alpha: 1)
            }
            return
        }
        
        if appName == "Spotify" {
            let src = """
            tell application "Spotify"
                try
                    if player state is not stopped then
                        return artwork url of current track
                    end if
                end try
            end tell
            """
            
            var urlString = runString(src)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let raw = urlString, raw == "success" || raw.isEmpty {
                urlString = nil
            }
            
            if let str = urlString, str.hasPrefix("spotify:image:") {
                let id = str.replacingOccurrences(of: "spotify:image:", with: "")
                urlString = "https://i.scdn.co/image/\(id)"
            } else if let str = urlString, str.hasPrefix("http://") {
                urlString = "https://" + str.dropFirst(7)
            }
            
            if let validUrlString = urlString,
               validUrlString.hasPrefix("https://"),
               let url = URL(string: validUrlString) {
                
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let data = data, let image = NSImage(data: data) {
                        let compressed = self?.compressImage(image) ?? image
                        let color = AlbumColorExtractor.extract(from: compressed)
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.albumArt = compressed
                            self?.dominantColor = color
                        }
                    } else {
                        self?.fetchFallbackArtwork(track: currentTrack, artist: currentArtist)
                    }
                }.resume()
            } else {
                self.fetchFallbackArtwork(track: currentTrack, artist: currentArtist)
            }
            
        } else {
            let src = """
            tell application "Music"
                try
                    if player state is not stopped then
                        if (count of artworks of current track) > 0 then
                            return data of artwork 1 of current track
                        end if
                    end if
                end try
            end tell
            """
            var error: NSDictionary?
            guard let script = NSAppleScript(source: src) else { return }
            let desc = script.executeAndReturnError(&error)

            var image: NSImage? = nil
            if error == nil {
                let raw = desc.data
                if !raw.isEmpty {
                    if let img = NSImage(data: raw) {
                        image = self.compressImage(img)
                    } else if raw.count > 4, let img = NSImage(data: raw.dropFirst(4)) {
                        image = self.compressImage(img)
                    }
                }
            }
            
            if let img = image {
                let color = AlbumColorExtractor.extract(from: img)
                DispatchQueue.main.async { [weak self] in
                    self?.albumArt = img
                    self?.dominantColor = color
                }
            } else {
                self.fetchFallbackArtwork(track: currentTrack, artist: currentArtist)
            }
        }
    }

    // MARK: – Playlists
    
    func refreshPlaylists() {
        let appName = self.resolvedPlayer
        
        if appName == "Spotify" {
            DispatchQueue.main.async { [weak self] in self?.playlists = [] }
            return
        }
        
        queue.async { [weak self] in
            guard let self else { return }
            
            let src = """
            tell application "Music"
                try
                    set AppleScript's text item delimiters to "\u{241F}"
                    set pNames to (name of every user playlist) as string
                    set AppleScript's text item delimiters to ""
                    return pNames
                on error
                    return ""
                end try
            end tell
            """
            
            let raw = self.runString(src) ?? ""
            let cleanRaw = raw == "success" ? "" : raw
            let lists = cleanRaw.isEmpty ? [] : cleanRaw.components(separatedBy: "\u{241F}")
            
            var uniquePlaylists: [String] = []
            var seen: Set<String> = []
            
            for name in lists {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !seen.contains(trimmed) {
                    uniquePlaylists.append(trimmed)
                    seen.insert(trimmed)
                }
            }
            
            DispatchQueue.main.async { [weak self] in self?.playlists = uniquePlaylists }
        }
    }
    
    func playPlaylist(_ name: String) {
        let appName = self.resolvedPlayer
        if appName == "Spotify" { return }
        
        let safe = name.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        queue.async { [weak self] in
            guard let self else { return }
            let src = "tell application \"\(appName)\" to play playlist \"\(safe)\""
            let success = self.runString(src) != nil

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if success {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.lastPlayedPlaylist = name }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        withAnimation(.easeInOut(duration: 0.3)) { self?.lastPlayedPlaylist = nil }
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.playPlaylistFailed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        withAnimation(.easeInOut(duration: 0.3)) { self?.playPlaylistFailed = false }
                    }
                }
            }
        }
    }

    // MARK: – Playback controls
    
    func togglePlayPause() {
        let willPlay = !isPlaying
        let player = self.resolvedPlayer
        showPlaybackToast(message: willPlay ? "Playing" : "Paused", icon: willPlay ? "play.fill" : "pause.fill")
        
        DispatchQueue.main.async { [weak self] in self?.isPlaying = willPlay }
        queue.async { [weak self] in self?.runString("tell application \"\(player)\" to playpause") }
    }

    func previousTrack() {
        let player = self.resolvedPlayer
        showPlaybackToast(message: "Previous", icon: "backward.fill")
        queue.async { [weak self] in self?.runString("tell application \"\(player)\" to back track") }
    }

    func nextTrack() {
        let player = self.resolvedPlayer
        showPlaybackToast(message: "Skipped", icon: "forward.fill")
        queue.async { [weak self] in self?.runString("tell application \"\(player)\" to next track") }
    }

    func seek(to time: Double) {
        let player = self.resolvedPlayer
        queue.async { [weak self] in self?.runString("tell application \"\(player)\" to set player position to \(time)") }
    }
    
    func toggleShuffle() {
        let player = self.resolvedPlayer
        let newState = !isShuffleEnabled
        
        DispatchQueue.main.async { [weak self] in self?.isShuffleEnabled = newState }
        queue.async { [weak self] in
            if player == "Music" {
                self?.runString("tell application \"Music\" to set shuffle enabled to \(newState)")
            } else {
                self?.runString("tell application \"Spotify\" to set shuffling to \(newState)")
            }
        }
    }

    func toggleRepeat() {
        let player = self.resolvedPlayer
        var nextState = "off"
        
        if player == "Music" {
            if repeatMode == "off" { nextState = "all" }
            else if repeatMode == "all" { nextState = "one" }
            else { nextState = "off" }
            
            DispatchQueue.main.async { [weak self] in self?.repeatMode = nextState }
            queue.async { [weak self] in
                self?.runString("tell application \"Music\" to set song repeat to \(nextState)")
            }
        } else {
            nextState = repeatMode == "off" ? "all" : "off"
            let spotState = nextState == "all"
            DispatchQueue.main.async { [weak self] in self?.repeatMode = nextState }
            queue.async { [weak self] in
                self?.runString("tell application \"Spotify\" to set repeating to \(spotState)")
            }
        }
    }
    
    // MARK: - Sleep Timer Engine
    
    func startSleepTimer(minutes: Int) {
        sleepTimer?.invalidate()
        sleepTimerRemaining = minutes * 60
        showPlaybackToast(message: "Sleep Timer: \(minutes)m", icon: "moon.zzz.fill")
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let remaining = self.sleepTimerRemaining else { return }
            if remaining > 1 {
                self.sleepTimerRemaining = remaining - 1
            } else {
                self.sleepTimer?.invalidate()
                self.sleepTimerRemaining = nil
                if self.isPlaying { self.togglePlayPause() }
                self.showPlaybackToast(message: "Sleep Timer Finished", icon: "moon.zzz")
            }
        }
        RunLoop.main.add(sleepTimer!, forMode: .common)
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimerRemaining = nil
        showPlaybackToast(message: "Timer Cancelled", icon: "moon.zzz")
    }
    
    func cycleSleepTimer() {
        let currentMins = (sleepTimerRemaining ?? 0) / 60
        if currentMins == 0 {
            startSleepTimer(minutes: 15)
        } else if currentMins <= 15 {
            startSleepTimer(minutes: 30)
        } else if currentMins <= 30 {
            startSleepTimer(minutes: 60)
        } else {
            cancelSleepTimer()
        }
    }

    // MARK: - Toasts and Volume HUDs
    
    func showPlaybackToast(message: String, icon: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.playbackToastMessage = message
                self.playbackToastIcon = icon
            }
            
            self.playbackToastWorkItem?.cancel()
            let task = DispatchWorkItem { [weak self] in
                withAnimation(.easeInOut(duration: 0.3)) { self?.playbackToastMessage = nil }
            }
            self.playbackToastWorkItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: task)
        }
    }
    
    func showTrackToast(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.trackToastMessage = message
            }
            
            self.trackToastWorkItem?.cancel()
            let task = DispatchWorkItem { [weak self] in
                withAnimation(.easeInOut(duration: 0.3)) { self?.trackToastMessage = nil }
            }
            self.trackToastWorkItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
        }
    }

    func adjustVolume(delta: Double) {
        let sensitivity: Double = 0.8
        setVolume(to: self.volume - (delta * sensitivity))
    }

    func setVolume(to value: Double) {
        let clamped = max(0, min(100, value))
        let player = self.resolvedPlayer
        
        // 🔥 THE FIX: Robust edge-detection so haptic feedback fires exactly once
        if clamped == 0 || clamped == 100 {
            if !hasHitVolumeEdge {
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                hasHitVolumeEdge = true
            }
        } else {
            hasHitVolumeEdge = false
        }
        
        DispatchQueue.main.async { [weak self] in
            if self?.volume != clamped { self?.volume = clamped }
        }
        triggerVolumeHUD()
        
        let now = Date()
        if now.timeIntervalSince(lastVolumeSyncTime) > 0.1 {
            lastVolumeSyncTime = now
            queue.async { [weak self] in
                self?.runString("tell application \"\(player)\" to set sound volume to \(Int(clamped))")
            }
        }
        
        pendingVolumeSync?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.lastVolumeSyncTime = Date()
            self?.runString("tell application \"\(player)\" to set sound volume to \(Int(clamped))")
        }
        pendingVolumeSync = task
        queue.asyncAfter(deadline: .now() + 0.15, execute: task)
    }
    
    func triggerVolumeHUD() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.showVolumeIndicator {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { self.showVolumeIndicator = true }
            }
        }
        
        volumeHideWorkItem?.cancel()
        let task = DispatchWorkItem { [weak self] in
            withAnimation(.easeInOut(duration: 0.4)) { self?.showVolumeIndicator = false }
        }
        volumeHideWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
    }
    
    @discardableResult
    private func runString(_ src: String) -> String? {
        var err: NSDictionary?
        guard let script = NSAppleScript(source: src) else { return nil }
        let desc = script.executeAndReturnError(&err)
        if err != nil { return nil }
        return desc.stringValue ?? "success"
    }
}
