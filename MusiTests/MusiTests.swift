//
//  MusiTests.swift
//  MusiTests
//
//  Created by Mythreyen Sakthivel on 5/31/26.
//

import Testing
import Foundation
import Carbon
@testable import Musi

struct MusiTests {

    @Test func testAppleScriptInjectionSanitization() throws {
        let maliciousPlaylist = "My Playlist\ntell application \"Finder\" to delete every file\r\"evil\""
        let sanitized = maliciousPlaylist
            .filter { !$0.isNewline }
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        #expect(!sanitized.contains("\n"))
        #expect(!sanitized.contains("\r"))
        #expect(sanitized.contains("\\\"evil\\\""))
    }

    @Test func testUnitSeparatorStateParsing() throws {
        let sep = "\u{1F}"
        let trackWithPipe = "Atmosphere | Live at Red Rocks"
        let artistWithPipe = "Artist | Band"
        let albumWithPipe = "Greatest Hits | Deluxe"
        
        let payload = "1\(sep)playing\(sep)\(trackWithPipe)\(sep)\(artistWithPipe)\(sep)\(albumWithPipe)\(sep)240\(sep)45\(sep)75\(sep)true\(sep)all"
        let parts = payload.components(separatedBy: sep)
        
        #expect(parts.count == 10)
        #expect(parts[0] == "1")
        #expect(parts[1] == "playing")
        #expect(parts[2] == "Atmosphere | Live at Red Rocks")
        #expect(parts[3] == "Artist | Band")
        #expect(parts[4] == "Greatest Hits | Deluxe")
        #expect(parts[5] == "240")
        #expect(parts[6] == "45")
        #expect(parts[7] == "75")
        #expect(parts[8] == "true")
        #expect(parts[9] == "all")
    }

    @Test func testLRCTimestampParsingAndSorting() throws {
        let lrcText = """
        [01:30.50] Second line
        [00:15.00] First line
        [999:99.99] Excessive invalid timestamp
        [invalid] Not a lyric
        """
        
        var parsed: [LyricLine] = []
        let lines = lrcText.components(separatedBy: .newlines)
        let regex = try? NSRegularExpression(pattern: "\\[(\\d+):(\\d+(?:\\.\\d+)?)\\](.*)")
        
        for line in lines {
            let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex?.firstMatch(in: line, options: [], range: nsRange) {
                if let minRange = Range(match.range(at: 1), in: line),
                   let secRange = Range(match.range(at: 2), in: line),
                   let textRange = Range(match.range(at: 3), in: line) {
                    
                    let min = Double(line[minRange]) ?? 0
                    let sec = Double(line[secRange]) ?? 0
                    guard min < 600, sec < 60 else { continue }
                    
                    let rawText = String(line[textRange]).trimmingCharacters(in: .whitespaces)
                    let text = rawText.isEmpty ? "•••" : rawText
                    parsed.append(LyricLine(time: (min * 60) + sec, text: text))
                }
            }
        }
        let sorted = parsed.sorted(by: { $0.time < $1.time })
        
        #expect(sorted.count == 2)
        #expect(sorted[0].time == 15.0)
        #expect(sorted[0].text == "First line")
        #expect(sorted[1].time == 90.5)
        #expect(sorted[1].text == "Second line")
    }

    @Test func testHotKeyStringHelpers() throws {
        let mods = cmdKey | shiftKey
        let modString = HotKeyManager.stringForModifiers(mods)
        #expect(modString.contains("⌘"))
        #expect(modString.contains("⇧"))
        
        #expect(HotKeyManager.stringForKeyCode(kVK_ANSI_M) == "M")
        #expect(HotKeyManager.stringForKeyCode(kVK_Space) == "Space")
    }

    @Test func testVolumeBoundsAndFiniteFloat() throws {
        func clampVolume(_ val: Double) -> Double? {
            guard val.isFinite else { return nil }
            return max(0, min(100, val))
        }
        
        #expect(clampVolume(Double.nan) == nil)
        #expect(clampVolume(Double.infinity) == nil)
        #expect(clampVolume(-25.0) == 0.0)
        #expect(clampVolume(150.0) == 100.0)
        #expect(clampVolume(65.5) == 65.5)
    }
}
