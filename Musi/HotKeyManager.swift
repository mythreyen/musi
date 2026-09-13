import AppKit
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    
    var action: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init() {
        setupEventHandler()
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            DispatchQueue.main.async {
                manager.action?()
            }
            return noErr
        }, 1, &eventType, pointer, &eventHandlerRef)
    }

    func registerSavedHotKey() {
        // Unregister the previous hotkey if one exists
        unregisterCurrentHotKey()

        let defaults = UserDefaults.standard
        
        // Default combo if none is saved: Command (cmdKey = 256) + Shift (shiftKey = 512) + M (46)
        let keyCode = defaults.object(forKey: "hotkeyCode") != nil ? UInt32(defaults.integer(forKey: "hotkeyCode")) : UInt32(kVK_ANSI_M)
        let modifiers = defaults.object(forKey: "hotkeyModifiers") != nil ? UInt32(defaults.integer(forKey: "hotkeyModifiers")) : UInt32(cmdKey | shiftKey)

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4D426172)
        hotKeyID.id = 1

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregisterCurrentHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    // Helper utility to turn carbon modifiers into readable string characters
    static func stringForModifiers(_ modifiers: Int) -> String {
        var str = ""
        if (modifiers & cmdKey) != 0 { str += "⌘" }
        if (modifiers & shiftKey) != 0 { str += "⇧" }
        if (modifiers & optionKey) != 0 { str += "⌥" }
        if (modifiers & controlKey) != 0 { str += "⌃" }
        return str
    }

    // Helper utility to convert a hardware virtual key code into a human-readable glyph string
    static func stringForKeyCode(_ keyCode: Int) -> String {
        switch keyCode {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Escape: return "⎋"
        default: return "Key \(keyCode)"
        }
    }
}
