import AppKit
import SwiftUI
import ScreenCaptureKit

@main
struct TranslyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, HotkeyManagerDelegate {
    private var selectionManager = SelectionManager()
    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?
    private var inputTranslationWindow: NSWindow?
    private var settingsWindow: NSWindow?
    
    private let config = AppConfigService.shared
    
    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupStatusItem()
            setupHotkey()
            showMainWindow()
            
            if !AppConfigService.shared.hasCompletedSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.showSetupGuide()
                }
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "Transly")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "输入翻译 (⌥A)", action: #selector(showInputTranslation), keyEquivalent: "a"))
        menu.addItem(NSMenuItem(title: "划词翻译 (⌥D)", action: #selector(showSelectionTranslation), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "OCR翻译 (⌥S)", action: #selector(showOCRTranslation), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "剪贴翻译 (⌥V)", action: #selector(showClipboardTranslation), keyEquivalent: "v"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "打开主窗口", action: #selector(showMainWindow), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "引导设置", action: #selector(showSetupGuide), keyEquivalent: "p"))
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
    
    nonisolated func hotkeyManager(_ manager: HotkeyManager, didActivate action: HotkeyAction) {
        Task { @MainActor in
            switch action {
            case .inputTranslation:
                showInputTranslation()
            case .selectionTranslation:
                showSelectionTranslation()
            case .ocrTranslation:
                showOCRTranslation()
            case .clipboardTranslation:
                showClipboardTranslation()
            }
        }
    }
    
    @objc private func showMainWindow() {
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
    
    @objc private func showInputTranslation() {
        showInputTranslationWindow(with: nil)
    }
    
    @objc private func showSelectionTranslation() {
        if !selectionManager.hasAccessibilityPermission {
            selectionManager.requestPermission()
            return
        }
        
        let result = selectionManager.getSelectedTextNow()
        switch result {
        case .success(let text):
            showInputTranslationWindow(with: text)
        case .noSelection:
            showInputTranslationWindow(with: nil)
        }
    }
    
    @objc private func showClipboardTranslation() {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        showInputTranslationWindow(with: text)
    }
    
    private func showInputTranslationWindow(with initialText: String?, isOCRMode: Bool = false, ocrError: Bool = false) {
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
    
    @objc private func showOCRTranslation() {
        Task {
            let screenshotCapture = ScreenshotCapture.shared
            let hasPermission = await screenshotCapture.checkScreenRecordingPermission()
            
            if !hasPermission {
                await MainActor.run {
                    showSetupGuide()
                }
                return
            }
            
            await MainActor.run {
                mainWindow?.orderOut(nil)
                inputTranslationWindow?.orderOut(nil)
                settingsWindow?.orderOut(nil)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.showRegionSelectionForOCR()
            }
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
        await MainActor.run {
            NSApplication.shared.activate(ignoringOtherApps: true)
            showInputTranslationWindow(with: "", isOCRMode: true)
        }
        
        let viewModel = OCRViewModel()
        await viewModel.captureRegionAndRecognize(rect: rect)
        
        let recognizedText = viewModel.recognizedText
        
        if !recognizedText.isEmpty {
            await MainActor.run {
                if let window = inputTranslationWindow {
                    window.contentView = NSHostingView(rootView: InputTranslationView(initialText: recognizedText))
                }
            }
        } else {
            await MainActor.run {
                if let window = inputTranslationWindow {
                    window.contentView = NSHostingView(rootView: InputTranslationView(initialText: "", ocrError: true))
                }
            }
        }
    }
    
    @objc private func openSettings() {
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
    
    @objc private func showSetupGuide() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "引导设置"
        window.contentView = NSHostingView(rootView: SetupGuideView(onComplete: {
            AppConfigService.shared.hasCompletedSetup = true
            window.close()
        }))
        window.center()
        
        window.isReleasedWhenClosed = false
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

struct SettingsWindowView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
                .tag(0)
            
            TranslationServicesSettingsView()
                .tabItem {
                    Label("翻译服务", systemImage: "globe")
                }
                .tag(1)
        }
        .frame(minWidth: 450, minHeight: 400)
    }
}

struct GeneralSettingsView: View {
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section("快捷键") {
                HStack {
                    Text("输入翻译")
                    Spacer()
                    Text("⌥A")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("划词翻译")
                    Spacer()
                    Text("⌥D")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("OCR翻译")
                    Spacer()
                    Text("⌥S")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                HStack {
                    Text("剪贴翻译")
                    Spacer()
                    Text("⌥V")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            Section("翻译设置") {
                Picker("默认源语言", selection: $viewModel.sourceLanguage) {
                    ForEach(Language.sourceLanguages) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                
                Picker("默认目标语言", selection: $viewModel.targetLanguage) {
                    ForEach(Language.targetLanguages) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                
                Toggle("自动复制翻译结果", isOn: $viewModel.autoCopy)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct TranslationServicesSettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var selectedService: TranslationServiceType?
    
    var body: some View {
        HSplitView {
            serviceListView
                .frame(minWidth: 180, maxWidth: 220)
            
            serviceConfigurationView
                .frame(minWidth: 280, maxWidth: .infinity)
        }
        .task {
            if selectedService == nil {
                selectedService = TranslationServiceType.availableServices.first
            }
        }
    }
    
    private var serviceListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("翻译服务")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
            
            List(TranslationServiceType.availableServices, selection: $selectedService) { service in
                ServiceListRow(
                    service: service,
                    isEnabled: viewModel.isServiceEnabled(service),
                    isSelected: selectedService == service
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedService = service
                }
            }
            .listStyle(.inset)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var serviceConfigurationView: some View {
        ScrollView {
            if let service = selectedService {
                VStack(alignment: .leading, spacing: 20) {
                    serviceHeaderSection(for: service)
                    
                    Divider()
                    
                    serviceConfigurationSection(for: service)
                }
                .padding(20)
            } else {
                VStack {
                    Spacer()
                    Text("请选择一个翻译服务")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func serviceHeaderSection(for service: TranslationServiceType) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(service.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("启用", isOn: Binding(
                get: { viewModel.isServiceEnabled(service) },
                set: { _ in viewModel.toggleService(service) }
            ))
            .toggleStyle(.switch)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func serviceConfigurationSection(for service: TranslationServiceType) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("配置")
                .font(.headline)
            
            switch service {
            case .google:
                googleConfigurationSection
            case .apple:
                appleConfigurationSection
            case .deepseek:
                deepseekConfigurationSection
            case .openai:
                openaiConfigurationSection
            case .ollama:
                ollamaConfigurationSection
            }
        }
    }
    
    private var googleConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("无需配置，开箱即用")
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("特点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("免费使用", systemImage: "gift")
                    Label("无需 API Key", systemImage: "key.slash")
                    Label("支持多种语言", systemImage: "globe")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var appleConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(macOS 15.0, *) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("系统原生翻译，已就绪")
                        .font(.subheadline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("特点")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("离线可用", systemImage: "wifi.slash")
                        Label("隐私保护", systemImage: "lock.shield")
                        Label("系统级集成", systemImage: "app.badge.checkmark")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("需要 macOS 15.0 或更高版本")
                            .font(.subheadline)
                    }
                    
                    Text("当前系统版本不支持 Apple 翻译功能")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var deepseekConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField("输入 DeepSeek API Key", text: $viewModel.deepSeekAPIKey)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Link("获取 DeepSeek API Key", destination: URL(string: "https://platform.deepseek.com/")!)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("特点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("高质量翻译", systemImage: "sparkles")
                    Label("支持上下文理解", systemImage: "text.bubble")
                    Label("性价比高", systemImage: "dollarsign.circle")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var openaiConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField("输入 OpenAI API Key", text: Binding(
                    get: { AppConfigService.shared.openAIAPIKey },
                    set: { AppConfigService.shared.openAIAPIKey = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Link("获取 OpenAI API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("API 端点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("输入 API 端点", text: Binding(
                    get: { AppConfigService.shared.openAIEndpoint },
                    set: { AppConfigService.shared.openAIEndpoint = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
                Text("默认: \(TranslationServiceType.openai.defaultEndpoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("可修改为兼容 OpenAI 接口的第三方服务地址")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("模型名称")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("输入模型名称", text: Binding(
                    get: { AppConfigService.shared.openAIModel },
                    set: { AppConfigService.shared.openAIModel = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
                Text("默认: \(TranslationServiceType.openai.defaultModel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("特点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("强大的语言理解能力", systemImage: "brain")
                    Label("支持自定义端点", systemImage: "network")
                    Label("支持多种模型", systemImage: "cpu")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var ollamaConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API 端点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("输入 Ollama 端点", text: Binding(
                    get: { AppConfigService.shared.ollamaEndpoint },
                    set: { AppConfigService.shared.ollamaEndpoint = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
                Text("默认: \(TranslationServiceType.ollama.defaultEndpoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("模型名称")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("输入模型名称", text: Binding(
                    get: { AppConfigService.shared.ollamaModel },
                    set: { AppConfigService.shared.ollamaModel = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
                Text("默认: \(TranslationServiceType.ollama.defaultModel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    
                    Text("确保 Ollama 服务正在运行")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Link("访问 Ollama 官网", destination: URL(string: "https://ollama.ai/")!)
                    .font(.caption)
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("特点")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("完全本地运行", systemImage: "house")
                    Label("隐私安全", systemImage: "lock.shield")
                    Label("无需网络", systemImage: "wifi.slash")
                    Label("支持多种开源模型", systemImage: "cube.box")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ServiceListRow: View {
    let service: TranslationServiceType
    let isEnabled: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(service.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    if isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                
                Text(service.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
