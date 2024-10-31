//
//  FloatingWindowController.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import Cocoa
import SwiftUI

// Custom window class that can become key
class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class FloatingWindowController: NSWindowController {
    private var hostingView: NSHostingView<FloatingIsland>!
    @Published var isPinned: Bool = false {
        didSet {
            print("Controller pin state changed to: \(isPinned)")
            // Create a new view instance with updated binding
            updateFloatingIslandView()
        }
    }
    
    convenience init() {
        // Use our custom window class
        let window = FloatingWindow(
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
        window.acceptsMouseMovedEvents = true  // Enable mouse move events
        
        self.init(window: window)
        
        // Create initial view
        updateFloatingIslandView()
        
        // Set initial size
        updateWindowSize()
        
        // Position window at the absolute top
        positionWindow()
        
        // Observe size changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateWindowSize),
            name: NSView.frameDidChangeNotification,
            object: hostingView
        )
    }
    
    private func positionWindow() {
        guard let window = self.window, let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let windowFrame = window.frame
        let x = screenFrame.midX - windowFrame.width/2
        let y = screenFrame.maxY - windowFrame.height + 40 // Add offset to account for padding
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc private func updateWindowSize() {
        let fittingSize = hostingView.fittingSize
        window?.setContentSize(fittingSize)
        hostingView.frame.size = fittingSize
        positionWindow()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        updateWindowSize()
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var shouldAutoHide: Bool {
        return !isPinned
    }
    
    private func updateFloatingIslandView() {
        let floatingIsland = FloatingIsland(isPinned: Binding(
            get: { [weak self] in
                return self?.isPinned ?? false
            },
            set: { [weak self] newValue in
                self?.isPinned = newValue
                print("Setting pin state to: \(newValue)")
            }
        ))
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: floatingIsland)
            hostingView.autoresizingMask = [.width, .height]
            hostingView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            hostingView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            hostingView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            hostingView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            window?.contentView = hostingView
        } else {
            hostingView.rootView = floatingIsland
        }
    }
}
