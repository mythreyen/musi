import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Hide from Dock
let delegate = AppDelegate()
app.delegate = delegate

// Configure standard application menu for ⌘, (Settings) and ⌘Q (Quit)
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
let appMenu = NSMenu(title: "Musi")

let settingsItem = NSMenuItem(title: "Settings…", action: #selector(AppDelegate.openPreferencesAction), keyEquivalent: ",")
settingsItem.target = delegate
appMenu.addItem(settingsItem)

appMenu.addItem(NSMenuItem.separator())

let quitItem = NSMenuItem(title: "Quit Musi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenu.addItem(quitItem)

appMenuItem.submenu = appMenu
mainMenu.addItem(appMenuItem)
app.mainMenu = mainMenu

app.run()
