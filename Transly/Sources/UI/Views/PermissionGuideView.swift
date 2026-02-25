import SwiftUI
import Cocoa
import CoreGraphics

struct PermissionGuideView: View {
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasScreenRecordingPermission: Bool = false
    
    private let selectionManager = SelectionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("权限设置指南")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Transly 需要以下权限才能正常工作：")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 20) {
                PermissionGuideItem(
                    title: "辅助功能权限",
                    description: "用于监听和获取选中的文本，实现划词翻译功能",
                    isGranted: $hasAccessibilityPermission,
                    onRequest: requestAccessibilityPermission,
                    onOpenSettings: openAccessibilitySettings
                )
                
                PermissionGuideItem(
                    title: "屏幕录制权限",
                    description: "用于 OCR 翻译功能，捕获屏幕上的文本",
                    isGranted: $hasScreenRecordingPermission,
                    onRequest: requestScreenRecordingPermission,
                    onOpenSettings: openScreenRecordingSettings
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
            
            Text("权限状态会实时更新，当您在系统偏好设置中修改权限时，此处会立即反映最新状态。")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("刷新权限状态") {
                    refreshPermissionStatus()
                }
                .buttonStyle(.bordered)
                
                Button("全部授予权限") {
                    requestAllPermissions()
                }
                .buttonStyle(.borderedProminent)
                
                Button("关闭") {
                    if let keyWindow = NSApplication.shared.keyWindow {
                        keyWindow.close()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(30)
        .frame(width: 450, height: 400)
        .onAppear {
            updatePermissionStatus()
            startPermissionMonitoring()
        }
    }
    
    private func updatePermissionStatus() {
        // 确保在主线程上更新权限状态
        DispatchQueue.main.async {
            let accessibilityStatus = self.checkAccessibilityPermission()
            let screenRecordingStatus = self.checkScreenRecordingPermission()
            
            print("权限状态更新：")
            print("辅助功能权限：\(accessibilityStatus)")
            print("屏幕录制权限：\(screenRecordingStatus)")
            
            self.hasAccessibilityPermission = accessibilityStatus
            self.hasScreenRecordingPermission = screenRecordingStatus
        }
    }
    
    private func startPermissionMonitoring() {
        // 初始检查一次权限状态
        updatePermissionStatus()
        
        // 不再使用定时检查，而是使用手动刷新按钮
    }
    
    private func refreshPermissionStatus() {
        updatePermissionStatus()
    }
    
    private func checkAccessibilityPermission() -> Bool {
        // 方法1：使用官方 API
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let apiResult = AXIsProcessTrustedWithOptions(options)
        
        // 方法2：尝试创建系统范围的 AXUIElement 并获取属性
        let systemWideElement = AXUIElementCreateSystemWide()
        var resultPtr: AnyObject?
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &resultPtr)
        let axElementResult = error == .success && resultPtr != nil
        
        print("辅助功能权限检测：")
        print("API 结果：\(apiResult)")
        print("AXUIElement 结果：\(axElementResult)")
        
        // 只使用官方 API 结果，因为 AXUIElement 方法可能在没有权限时也返回成功
        let finalResult = apiResult
        print("最终权限状态：\(finalResult)")
        
        return finalResult
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        // 使用官方 API 检测屏幕录制权限
        let apiResult = CGPreflightScreenCaptureAccess()
        
        print("屏幕录制权限检测：")
        print("CGPreflightScreenCaptureAccess 结果：\(apiResult)")
        print("最终权限状态：\(apiResult)")
        
        return apiResult
    }
    

    
    private func requestAllPermissions() {
        requestAccessibilityPermission()
        requestScreenRecordingPermission()
    }
    
    private func requestAccessibilityPermission() {
        if !checkAccessibilityPermission() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }
    
    private func requestScreenRecordingPermission() {
        if !checkScreenRecordingPermission() {
            _ = CGRequestScreenCaptureAccess()
        }
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}

struct PermissionGuideItem: View {
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isGranted ? .green : .red)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(isGranted ? "已授权" : "授予权限") {
                    if !isGranted {
                        onRequest()
                    }
                }
                .disabled(isGranted)
                
                Button("打开系统设置") {
                    onOpenSettings()
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    PermissionGuideView()
}
