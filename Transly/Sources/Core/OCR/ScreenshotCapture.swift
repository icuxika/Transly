import AppKit
import Foundation
import ScreenCaptureKit
import CoreGraphics

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
        NSLog("开始全屏截图")
        
        let content = try await getShareableContent()
        
        NSLog("获取到屏幕内容，显示器数量：%d", content.displays.count)
        
        guard let display = content.displays.first else {
            NSLog("没有可用的显示器")
            throw ScreenshotError.noDisplay
        }
        
        NSLog("使用显示器：%@, 尺寸：%dx%d", String(describing: display), display.width, display.height)
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        
        NSLog("开始捕获图像，配置：宽度=%d, 高度=%d", configuration.width, configuration.height)
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        NSLog("截图成功，图像尺寸：%dx%d", image.width, image.height)
        
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        NSLog("转换为NSImage成功：%@", nsImage.description)
        
        return nsImage
    }
    
    func captureRegion(rect: CGRect) async throws -> NSImage {
        NSLog("开始区域截图，原始区域（AppKit坐标）：x=%f, y=%f, width=%f, height=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
        
        let content = try await getShareableContent()
        
        NSLog("获取到屏幕内容，显示器数量：%d", content.displays.count)
        
        guard let display = content.displays.first else {
            NSLog("没有可用的显示器")
            throw ScreenshotError.noDisplay
        }
        
        NSLog("使用显示器：%@, 尺寸：%dx%d", String(describing: display), display.width, display.height)
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let screenHeight = Double(display.height)
        let convertedY = screenHeight - rect.origin.y - rect.size.height
        let convertedRect = CGRect(
            x: rect.origin.x,
            y: convertedY,
            width: rect.size.width,
            height: rect.size.height
        )
        
        NSLog("坐标转换：")
        NSLog("  屏幕高度：%f", screenHeight)
        NSLog("  原始Y：%f", rect.origin.y)
        NSLog("  转换后Y：%f", convertedY)
        NSLog("  转换后区域：x=%f, y=%f, width=%f, height=%f", convertedRect.origin.x, convertedRect.origin.y, convertedRect.size.width, convertedRect.size.height)
        
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = convertedRect
        configuration.width = Int(rect.width)
        configuration.height = Int(rect.height)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        
        NSLog("截图配置：")
        NSLog("  sourceRect: x=%f, y=%f, width=%f, height=%f", configuration.sourceRect.origin.x, configuration.sourceRect.origin.y, configuration.sourceRect.size.width, configuration.sourceRect.size.height)
        NSLog("  输出尺寸: %dx%d", configuration.width, configuration.height)
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        NSLog("截图成功，图像尺寸：%dx%d", image.width, image.height)
        
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        NSLog("转换为NSImage成功：%@", nsImage.description)
        
        return nsImage
    }
    
    private func getShareableContent() async throws -> SCShareableContent {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            return content
        } catch {
            NSLog("获取屏幕内容失败：%@", error.localizedDescription)
            throw error
        }
    }
    
    func checkScreenRecordingPermission() async -> Bool {
        let hasPermission = CGPreflightScreenCaptureAccess()
        NSLog("ScreenCaptureKit权限检查：%@", hasPermission ? "有权限" : "无权限")
        return hasPermission
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            
            if content.displays.isEmpty {
                NSLog("请求屏幕录制权限：无显示器")
                return false
            }
            
            guard let display = content.displays.first else {
                NSLog("请求屏幕录制权限：无显示器")
                return false
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.width = 1
            configuration.height = 1
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            
            NSLog("尝试实际截图以激活权限...")
            _ = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            NSLog("权限请求成功")
            return true
        } catch {
            NSLog("权限请求失败：%@", error.localizedDescription)
            return false
        }
    }
}
