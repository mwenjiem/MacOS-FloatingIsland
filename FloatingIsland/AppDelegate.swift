//
//  AppDelegate.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var floatingWindowController: FloatingWindowController?
    var mouseTrackingTimer: Timer?
    let triggerHeight: CGFloat = 30
    var isWindowVisible = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🏝️"
            
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            statusItem.menu = menu
        }
        
        floatingWindowController = FloatingWindowController()
        NSApp.setActivationPolicy(.accessory)
        startMouseTracking()
    }
    
    private func startMouseTracking() {
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
    }
    
    private func checkMousePosition() {
        guard let controller = floatingWindowController,
              let window = controller.window,
              let screen = NSScreen.main else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame
        let distanceFromTop = screenFrame.maxY - mouseLocation.y
        
        let centerX = screenFrame.midX
        let tolerance = screenFrame.width * 0.3
        let isInMiddleZone = (mouseLocation.x > centerX - tolerance) && 
                            (mouseLocation.x < centerX + tolerance)
        
        let isInWindowFrame = window.frame.contains(mouseLocation)
        
        if (distanceFromTop <= triggerHeight && isInMiddleZone) || isInWindowFrame {
            if !isWindowVisible {
                isWindowVisible = true
                controller.showWindow(nil)
            }
        } else if !isInWindowFrame {
            if isWindowVisible {
                isWindowVisible = false
                controller.hideWindow()
            }
        }
    }
    
    deinit {
        mouseTrackingTimer?.invalidate()
    }
}
