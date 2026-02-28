import AppKit
import SwiftUI
import ScreenCaptureKit

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var mainWindow: NSWindow?
    private var inputTranslationWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var setupGuideWindow: NSWindow?
    
    private let accessibilitySelectionService = AccessibilitySelectionService()
    
    private init() {}
    
    func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if mainWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Transly"
            window.isReleasedWhenClosed = false
            mainWindow = window
        }
        
        if let window = mainWindow {
            window.contentView = NSHostingView(rootView: MainView())
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func showInputTranslation(initialText: String? = nil, isOCRMode: Bool = false, ocrError: Bool = false) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if inputTranslationWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "翻译"
            window.isReleasedWhenClosed = false
            inputTranslationWindow = window
        }
        
        if let window = inputTranslationWindow {
            window.contentView = NSHostingView(rootView: InputTranslationView(
                initialText: initialText ?? "",
                isOCRMode: isOCRMode,
                ocrError: ocrError
            ))
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func showSelectionTranslation() {
        if !accessibilitySelectionService.checkPermission() {
            accessibilitySelectionService.requestPermission()
            return
        }
        
        Task {
            let result = await accessibilitySelectionService.getSelectedTextWithFallback()
            switch result {
            case .success(let text, let source):
                await MainActor.run {
                    NSLog("划词翻译 获取文字成功，来源: \(source == .accessibilityAPI ? "Accessibility API" : "剪贴板回退")")
                    showInputTranslation(initialText: text)
                }
            case .noSelection, .permissionDenied:
                await MainActor.run {
                    showInputTranslation(initialText: nil)
                }
            }
        }
    }
    
    func showClipboardTranslation() {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        showInputTranslation(initialText: text)
    }
    
    func showOCRTranslation() async {
        let screenshotCapture = ScreenshotCapture.shared
        let hasPermission = await screenshotCapture.checkScreenRecordingPermission()
        
        if !hasPermission {
            showSetupGuide()
            return
        }
        
        mainWindow?.orderOut(nil)
        inputTranslationWindow?.orderOut(nil)
        settingsWindow?.orderOut(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showRegionSelectionForOCR()
        }
    }
    
    private func showRegionSelectionForOCR() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        
        let contentView = NSHostingView(rootView: RegionSelection(completion: { [weak self] rect in
            Task {
                await self?.performOCRTranslation(rect: rect)
            }
            window.close()
        }))
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
    }
    
    private func performOCRTranslation(rect: CGRect) async {
        NSApplication.shared.activate(ignoringOtherApps: true)
        showInputTranslation(initialText: "", isOCRMode: true)
        
        let viewModel = OCRViewModel()
        await viewModel.captureRegionAndRecognize(rect: rect)
        
        let recognizedText = viewModel.recognizedText
        
        if !recognizedText.isEmpty {
            if let window = inputTranslationWindow {
                window.contentView = NSHostingView(rootView: InputTranslationView(initialText: recognizedText))
            }
        } else {
            if let window = inputTranslationWindow {
                window.contentView = NSHostingView(rootView: InputTranslationView(initialText: "", ocrError: true))
            }
        }
    }
    
    func showSettings() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "设置"
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        
        if let window = settingsWindow {
            window.contentView = NSHostingView(rootView: SettingsWindowView())
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func showSetupGuide() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if setupGuideWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "引导设置"
            window.isReleasedWhenClosed = false
            setupGuideWindow = window
        }
        
        if let window = setupGuideWindow {
            window.contentView = NSHostingView(rootView: SetupGuideView(onComplete: {
                AppConfigService.shared.hasCompletedSetup = true
                window.close()
            }))
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private var aboutWindow: NSWindow?
    
    func showAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if aboutWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 350),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "关于 Transly"
            window.isReleasedWhenClosed = false
            aboutWindow = window
        }
        
        if let window = aboutWindow {
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}
