import SwiftUI

struct SetupGuideView: View {
    let onComplete: () -> Void
    
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasScreenRecordingPermission: Bool = false
    
    private let selectionManager = SelectionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("引导设置")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Transly 需要以下权限才能正常工作：")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 20) {
                PermissionItem(
                    title: "辅助功能权限",
                    description: "用于监听和获取选中的文本，实现划词翻译功能",
                    isGranted: $hasAccessibilityPermission,
                    onRequest: requestAccessibilityPermission,
                    onOpenSettings: openAccessibilitySettings
                )
                
                PermissionItem(
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
            
            Text("权限状态会实时更新，当您在系统设置中修改权限时，此处会立即反映最新状态。")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("刷新权限状态") {
                    refreshPermissionStatus()
                }
                .buttonStyle(.bordered)
                
                Button("完成设置") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 500, height: 450)
        .onAppear {
            updatePermissionStatus()
            startPermissionMonitoring()
        }
    }
    
    private func updatePermissionStatus() {
        hasAccessibilityPermission = selectionManager.hasAccessibilityPermission
        
        Task {
            let screenshotCapture = ScreenshotCapture.shared
            let screenPermission = await screenshotCapture.checkScreenRecordingPermission()
            await MainActor.run {
                hasScreenRecordingPermission = screenPermission
            }
        }
    }
    
    private func startPermissionMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                updatePermissionStatus()
            }
        }
    }
    
    private func refreshPermissionStatus() {
        updatePermissionStatus()
    }
    
    private func requestAccessibilityPermission() {
        if !checkAccessibilityPermission() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }
    
    private func requestScreenRecordingPermission() {
        Task {
            let screenshotCapture = ScreenshotCapture.shared
            _ = await screenshotCapture.requestScreenRecordingPermission()
        }
    }
    
    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
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

struct PermissionItem: View {
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isGranted ? .green : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    Button(isGranted ? "已授权" : "授予权限") {
                        if !isGranted {
                            onRequest()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isGranted)
                    
                    Button("打开系统设置") {
                        onOpenSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

#Preview {
    SetupGuideView(onComplete: {})
}
