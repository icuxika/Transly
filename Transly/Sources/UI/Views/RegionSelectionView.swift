import AppKit
import SwiftUI

class RegionSelectionWindow: NSWindow {
    private var startPoint: NSPoint = .zero
    private var currentPoint: NSPoint = .zero
    private var selectionRect: CGRect = .zero
    private var selectionView: SelectionView?
    private var completion: ((CGRect) -> Void)?
    private var eventMonitor: Any?
    
    init(completion: @escaping (CGRect) -> Void) {
        self.completion = completion
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        super.init(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        
        level = .screenSaver
        backgroundColor = NSColor.black.withAlphaComponent(0.3)
        isOpaque = false
        ignoresMouseEvents = false
        makeKeyAndOrderFront(nil)
        
        let contentView = NSView(frame: screenFrame)
        self.contentView = contentView
        
        selectionView = SelectionView(frame: screenFrame)
        contentView.addSubview(selectionView!)
        
        contentView.window?.contentView?.addTrackingArea(NSTrackingArea(
            rect: screenFrame,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        ))
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown, handler: { [weak self] event in
            self?.mouseDown(with: event)
            return event
        })
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged, handler: { [weak self] event in
            self?.mouseDragged(with: event)
            return event
        })
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp, handler: { [weak self] event in
            self?.mouseUp(with: event)
            return event
        })
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.cancel()
                return nil
            }
            return event
        }
    }
    
    private func cancel() {
        close()
    }
    
    override func close() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        super.close()
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        currentPoint = startPoint
        updateSelection()
    }
    
    override func mouseDragged(with event: NSEvent) {
        currentPoint = event.locationInWindow
        updateSelection()
    }
    
    override func mouseUp(with event: NSEvent) {
        currentPoint = event.locationInWindow
        updateSelection()
        
        let rect = selectionRect
        NSLog("区域选择完成：")
        NSLog("  选择区域：x=%f, y=%f, width=%f, height=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        NSLog("  屏幕尺寸：%@", String(describing: NSScreen.main?.frame))
        
        if rect.width > 10 && rect.height > 10 {
            completion?(rect)
        }
        
        close()
    }
    
    private func updateSelection() {
        let x = min(startPoint.x, currentPoint.x)
        let y = min(startPoint.y, currentPoint.y)
        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)
        
        selectionRect = CGRect(x: x, y: y, width: width, height: height)
        selectionView?.selectionRect = selectionRect
    }
}

class SelectionView: NSView {
    var selectionRect: CGRect = .zero {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if !selectionRect.isEmpty {
            let path = NSBezierPath(rect: selectionRect)
            NSColor.blue.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            NSColor.blue.withAlphaComponent(0.1).setFill()
            path.fill()
        }
    }
}

struct RegionSelection: NSViewRepresentable {
    let completion: (CGRect) -> Void
    
    func makeNSView(context: Context) -> NSView {
        return NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.window == nil {
            context.coordinator.createWindow(completion: completion)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var window: RegionSelectionWindow?
        
        func createWindow(completion: @escaping (CGRect) -> Void) {
            window = RegionSelectionWindow(completion: completion)
        }
    }
}
