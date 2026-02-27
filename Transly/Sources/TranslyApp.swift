import AppKit
import SwiftUI

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupHotkey()
            showInitialWindows()
        }
    }
    
    @MainActor
    private func setupHotkey() {
        HotkeyManager.shared.delegate = HotkeyHandler.shared
        _ = HotkeyManager.shared.registerHotkey()
    }
    
    @MainActor
    private func showInitialWindows() {
        WindowManager.shared.showMainWindow()
        
        if !AppConfigService.shared.hasCompletedSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                WindowManager.shared.showSetupGuide()
            }
        }
    }
}

@main
struct TranslyApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Transly", systemImage: "character.bubble") {
            MenuBarView()
        }
    }
}

struct MenuBarView: View {
    var body: some View {
        Group {
            Button("输入翻译 (⌥A)") {
                WindowManager.shared.showInputTranslation()
            }
            .keyboardShortcut("a", modifiers: .command)
            
            Button("划词翻译 (⌥D)") {
                WindowManager.shared.showSelectionTranslation()
            }
            .keyboardShortcut("d", modifiers: .command)
            
            Button("截图翻译 (⌥S)") {
                Task {
                    await WindowManager.shared.showOCRTranslation()
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("剪贴翻译 (⌥V)") {
                WindowManager.shared.showClipboardTranslation()
            }
            .keyboardShortcut("v", modifiers: .command)
            
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
            .keyboardShortcut("q", modifiers: .command)
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
