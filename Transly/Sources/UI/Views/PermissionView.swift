import AppKit
import SwiftUI

struct PermissionView: View {
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("需要辅助功能权限")
                .font(.headline)
            
            Text("Transly 需要辅助功能权限才能监听您的文本选择。\n请在系统设置中授予权限。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("打开系统设置") {
                onOpenSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: 300)
    }
}

#Preview {
    PermissionView(onOpenSettings: {})
}
