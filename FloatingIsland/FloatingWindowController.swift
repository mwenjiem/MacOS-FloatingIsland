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
            updateFloatingIslandView()
        }
    }
    @Published var isExpanded: Bool = false {
        didSet {
            updateFloatingIslandView()
            updateWindowSize()
        }
    }
    
    convenience init() {
        let window = FloatingWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .statusBar
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = false  // Disable window dragging
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.acceptsMouseMovedEvents = true
        
        self.init(window: window)
        
        updateFloatingIslandView()
        updateWindowSize()
        positionWindow()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateWindowSize),
            name: NSView.frameDidChangeNotification,
            object: hostingView
        )
        
        // Add observer for screen changes to keep window centered
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenParametersDidChange() {
        positionWindow()
    }
    
    private func positionWindow() {
        guard let window = self.window, let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let windowFrame = window.frame
        let x = screenFrame.midX - windowFrame.width/2
        let y = screenFrame.maxY - windowFrame.height // Add offset to account for padding
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc private func updateWindowSize() {
        let fittingSize = hostingView.fittingSize
        // Add animation for window resizing
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window?.animator().setContentSize(fittingSize)
            hostingView.animator().frame.size = fittingSize
        }
        positionWindow()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        isExpanded = true
        updateWindowSize()
    }
    
    func hideWindow() {
        isExpanded = false
        updateWindowSize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var shouldAutoHide: Bool {
        return !isPinned
    }
    
    private func updateFloatingIslandView() {
        let floatingIsland = FloatingIsland(
            isPinned: Binding(
                get: { [weak self] in self?.isPinned ?? false },
                set: { [weak self] in self?.isPinned = $0 }
            ),
            isExpanded: Binding(
                get: { [weak self] in self?.isExpanded ?? false },
                set: { [weak self] in self?.isExpanded = $0 }
            ),
            mediaController: MediaController(),
            calendarController: CalendarController()
        )
        
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
