//
//  AppDelegate.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindowController: FloatingWindowController?
    var settingsWindowController: SettingsWindowController?
    var mouseTrackingTimer: Timer?
    let triggerHeight: CGFloat = 30
    var isWindowVisible = false
    var statusItem: NSStatusItem?
    var mouseMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        
        floatingWindowController = FloatingWindowController()
        NSApp.setActivationPolicy(.accessory)
        
        // Show window initially in minimized state
        floatingWindowController?.window?.orderFront(nil)
        floatingWindowController?.isExpanded = false
        
        // Observe expansion state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(expansionStateChanged),
            name: NSNotification.Name("ExpansionStateChanged"),
            object: nil
        )
        
        // Observe settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func settingsChanged() {
        let requireClickToExpand = UserDefaults.standard.bool(forKey: "requireClickToExpand")
        if !requireClickToExpand {
            // If not in click mode, always enable mouse tracking
            startMouseTracking()
        } else {
            // In click mode, stop tracking until view is expanded
            stopMouseTracking()
        }
    }
    
    @objc private func expansionStateChanged(_ notification: Notification) {
        if let isExpanded = notification.object as? Bool {
            let requireClickToExpand = UserDefaults.standard.bool(forKey: "requireClickToExpand")
            
            if requireClickToExpand {
                // In click mode, only track mouse when expanded
                if isExpanded {
                    startMouseTracking()
                } else {
                    stopMouseTracking()
                }
            }
            // In hover mode, tracking is always on (managed by settingsChanged)
        }
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "menubar.dock.rectangle", accessibilityDescription: "FloatingIsland") {
                image.isTemplate = true
                button.image = image
            }
            
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings", 
                                  action: #selector(openSettings), 
                                  keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit FloatingIsland", 
                                  action: #selector(NSApplication.terminate(_:)), 
                                  keyEquivalent: "q"))
            
            statusItem?.menu = menu
        }
    }
    
    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func stopMouseTracking() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
    }
    
    private func startMouseTracking() {
        stopMouseTracking() // Clean up any existing timer
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
    }
    
    private func checkMousePosition() {
        guard let controller = floatingWindowController,
              let window = controller.window else { return }
        
        if controller.isPinned {
            controller.isExpanded = true
            return
        }
        
        let mouseLocation = NSEvent.mouseLocation
        let isInWindowFrame = window.frame.contains(mouseLocation)
        let requireClickToExpand = UserDefaults.standard.bool(forKey: "requireClickToExpand")
        
        if requireClickToExpand {
            // In click mode, only handle collapse
            if !isInWindowFrame && controller.isExpanded {
                controller.isExpanded = false
            }
        } else {
            // In hover mode, handle both expand and collapse
            controller.isExpanded = isInWindowFrame
        }
    }
    
    deinit {
        mouseTrackingTimer?.invalidate()
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
