import AppKit
import Foundation
import ScreenCaptureKit

enum ScreenshotError: Error, LocalizedError {
    case noDisplay
    case captureFailed(Error)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noDisplay:
            return "没有可用的显示器"
        case .captureFailed(let error):
            return "截图失败: \(error.localizedDescription)"
        case .permissionDenied:
            return "需要屏幕录制权限"
        }
    }
}

actor ScreenshotCapture {
    static let shared = ScreenshotCapture()
    
    private init() {}
    
    func captureScreen() async throws -> NSImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        guard let display = content.displays.first else {
            throw ScreenshotError.noDisplay
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
    
    func captureRegion(rect: CGRect) async throws -> NSImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        guard let display = content.displays.first else {
            throw ScreenshotError.noDisplay
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = rect
        configuration.width = Int(rect.width)
        configuration.height = Int(rect.height)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
    
    func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }
}
