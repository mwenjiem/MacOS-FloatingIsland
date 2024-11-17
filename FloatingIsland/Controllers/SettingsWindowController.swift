import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "FloatingIsland Settings"
        window.center()
        
        let settingsView = SettingsView()
        window.contentView = NSHostingView(rootView: settingsView)
        
        self.init(window: window)
    }
} 