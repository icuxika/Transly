import SwiftUI

struct SetupGuideView: View {
    let onComplete: () -> Void
    
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasScreenRecordingPermission: Bool = false
    
    private let accessibilityService = AccessibilitySelectionService.shared
    
    var body: some View {
        VStack(spacing: 24) {
            headerSection
            
            permissionsSection
            
            actionButtonsSection
        }
        .padding(30)
        .frame(width: 480, height: 380)
        .onAppear {
            updatePermissionStatus()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            
            Text("引导设置")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Transly 需要以下权限才能正常工作")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var permissionsSection: some View {
        VStack(spacing: 16) {
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
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button("刷新状态") {
                refreshPermissionStatus()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("完成设置") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func updatePermissionStatus() {
        hasAccessibilityPermission = accessibilityService.checkPermission()
        
        Task {
            let screenshotCapture = ScreenshotCapture.shared
            let screenPermission = await screenshotCapture.checkScreenRecordingPermission()
            await MainActor.run {
                hasScreenRecordingPermission = screenPermission
            }
        }
    }
    
    private func refreshPermissionStatus() {
        updatePermissionStatus()
    }
    
    private func requestAccessibilityPermission() {
        accessibilityService.requestPermission()
    }
    
    private func requestScreenRecordingPermission() {
        Task {
            let screenshotCapture = ScreenshotCapture.shared
            _ = await screenshotCapture.requestScreenRecordingPermission()
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

struct PermissionItem: View {
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let onRequest: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title2)
                .foregroundStyle(isGranted ? .green : .orange)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(isGranted ? "已授权" : "授权") {
                    if !isGranted {
                        onRequest()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isGranted)
                .controlSize(.small)
                
                Button("设置") {
                    onOpenSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SetupGuideView(onComplete: {})
}
