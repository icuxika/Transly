import AppKit
import SwiftUI

@main
struct TranslyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 450, height: 550)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        
        Settings {
            SettingsView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, HotkeyManagerDelegate {
    private var selectionManager = SelectionManager()
    private var floatingPanel: FloatingPanelWindow?
    private var statusItem: NSStatusItem?
    
    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupStatusItem()
            setupHotkey()
            checkPermissionAndStartMonitoring()
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "Transly")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "打开主窗口", action: #selector(showMainWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "翻译剪贴板内容", action: #selector(translateClipboard), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupHotkey() {
        HotkeyManager.shared.delegate = self
        _ = HotkeyManager.shared.registerHotkey()
    }
    
    private func checkPermissionAndStartMonitoring() {
        if selectionManager.hasAccessibilityPermission {
            selectionManager.startMonitoring()
        }
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissionStatus()
            }
        }
    }
    
    private func checkPermissionStatus() {
        if selectionManager.hasAccessibilityPermission {
            selectionManager.startMonitoring()
        }
    }
    
    nonisolated func hotkeyManagerDidActivate(_ manager: HotkeyManager) {
        Task { @MainActor in
            await showFloatingPanelForClipboard()
        }
    }
    
    private func showFloatingPanelForClipboard() async {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        selectionManager.selectedText = text
        selectionManager.selectionPosition = mouseLocation
        selectionManager.isShowingFloatingPanel = true
        await selectionManager.translateSelection()
        showFloatingPanel()
    }
    
    @objc private func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow == false }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func translateClipboard() {
        Task {
            await showFloatingPanelForClipboard()
        }
    }
    
    @objc private func openSettings() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func showFloatingPanel() {
        let panel = FloatingPanelWindow()
        
        let view = FloatingPanelView(
            selectedText: selectionManager.selectedText,
            translatedText: selectionManager.translatedText,
            isTranslating: selectionManager.isTranslating,
            sourceLanguage: selectionManager.sourceLanguage,
            targetLanguage: selectionManager.targetLanguage,
            onCopy: { Task { await self.selectionManager.copyTranslatedText() } },
            onClose: { [weak self] in
                Task { await self?.hideFloatingPanel() }
            }
        )
        
        panel.contentView = NSHostingView(rootView: view)
        
        let screenRect = NSScreen.screens.first?.frame ?? .zero
        var panelOrigin = selectionManager.selectionPosition
        
        panelOrigin.y = screenRect.height - panelOrigin.y - 220
        panelOrigin.x -= 160
        
        panelOrigin.x = max(10, min(panelOrigin.x, screenRect.width - 340))
        panelOrigin.y = max(10, min(panelOrigin.y, screenRect.height - 220))
        
        panel.setFrameOrigin(panelOrigin)
        panel.makeKeyAndOrderFront(nil)
        
        floatingPanel = panel
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            Task { await self?.hideFloatingPanel() }
        }
    }
    
    private func hideFloatingPanel() async {
        floatingPanel?.close()
        floatingPanel = nil
        await selectionManager.hideFloatingPanel()
    }
}
