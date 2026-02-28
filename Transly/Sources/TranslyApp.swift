import AppKit
import SwiftUI
import Sparkle

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

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    
    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("检查更新", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

@main
struct TranslyApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) var appDelegate
    
    private let updaterController: SPUStandardUpdaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    
    var body: some Scene {
        MenuBarExtra("Transly", systemImage: "character.bubble") {
            MenuBarView(updaterController: updaterController)
        }
    }
}

struct MenuBarView: View {
    let updaterController: SPUStandardUpdaterController
    
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
            
            CheckForUpdatesView(updater: updaterController.updater)
            Button("设置") {
                WindowManager.shared.showSettings()
            }
            
            Divider()
            
            Button("关于") {
                WindowManager.shared.showAbout()
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
