import AppKit
import Foundation

actor ClipboardService {
    static let shared = ClipboardService()
    
    private init() {}
    
    func copy(_ text: String) {
        Task { @MainActor in
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }
    }
    
    func paste() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}
