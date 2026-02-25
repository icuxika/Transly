import AppKit
import SwiftUI

@main
struct TranslyApp: App {
    init() {
        setupHotkey()
    }
    
    var body: some Scene {
        MenuBarExtra("Transly", systemImage: "character.bubble") {
            MenuBarView()
        }
        
        Settings {
            EmptyView()
        }
    }
    
    private func setupHotkey() {
        HotkeyManager.shared.delegate = HotkeyHandler.shared
        _ = HotkeyManager.shared.registerHotkey()
        
        WindowManager.shared.showMainWindow()
        
        if !AppConfigService.shared.hasCompletedSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                WindowManager.shared.showSetupGuide()
            }
        }
    }
}

struct MenuBarView: View {
    var body: some View {
        Group {
            Button("输入翻译 (⌥A)") {
                WindowManager.shared.showInputTranslation()
            }
            Button("划词翻译 (⌥D)") {
                WindowManager.shared.showSelectionTranslation()
            }
            Button("OCR翻译 (⌥S)") {
                Task {
                    await WindowManager.shared.showOCRTranslation()
                }
            }
            Button("剪贴翻译 (⌥V)") {
                WindowManager.shared.showClipboardTranslation()
            }
            
            Divider()
            
            Button("打开主窗口") {
                WindowManager.shared.showMainWindow()
            }
            Button("引导设置") {
                WindowManager.shared.showSetupGuide()
            }
            
            Divider()
            
            Button("设置") {
                WindowManager.shared.showSettings()
            }
            
            Divider()
            
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

@MainActor
class HotkeyHandler: HotkeyManagerDelegate {
    static let shared = HotkeyHandler()
    
    nonisolated func hotkeyManager(_ manager: HotkeyManager, didActivate action: HotkeyAction) {
        Task { @MainActor in
            switch action {
            case .inputTranslation:
                WindowManager.shared.showInputTranslation()
            case .selectionTranslation:
                WindowManager.shared.showSelectionTranslation()
            case .ocrTranslation:
                Task {
                    await WindowManager.shared.showOCRTranslation()
                }
            case .clipboardTranslation:
                WindowManager.shared.showClipboardTranslation()
            }
        }
    }
}
