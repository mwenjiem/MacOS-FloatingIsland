//
//  FloatingWindowController.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import Cocoa
import SwiftUI

class FloatingWindowController: NSWindowController {
    private var hostingView: NSHostingView<FloatingIsland>!
    
    convenience init() {
        // Start with zero rect
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .statusBar
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
        
        // Create the FloatingIsland view
        let floatingIsland = FloatingIsland()
        hostingView = NSHostingView(rootView: floatingIsland)
        
        // Get the fitting size from the hosting view
        let fittingSize = hostingView.fittingSize
        print("Fitting size: \(fittingSize)") // Debug print
        
        // Set the hosting view size
        hostingView.frame.size = fittingSize
        
        // Set the window's content view and size
        window.contentView = hostingView
        window.setContentSize(fittingSize)
        
        // Position the window
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width/2
            let y = screenFrame.maxY - windowFrame.height
            window.setFrameOrigin(NSPoint(x: x, y: y))
            
            // Debug print
            print("Window frame: \(windowFrame)")
            print("Screen frame: \(screenFrame)")
        }
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
}
