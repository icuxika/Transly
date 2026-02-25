import SwiftUI

struct TranslationServicesSettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var selectedService: TranslationServiceType?
    @State private var appleSourceLanguage: Language = .english
    @State private var appleTargetLanguage: Language = .chinese
    @State private var appleLanguageStatus: String = ""
    @State private var isCheckingAppleLanguage = false
    
    var body: some View {
        HSplitView {
            serviceListView
                .frame(minWidth: 180, maxWidth: 220)
            
            serviceConfigurationView
                .frame(minWidth: 320, maxWidth: .infinity)
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
                VStack(alignment: .leading, spacing: 24) {
                    serviceHeaderSection(for: service)
                    serviceConfigurationSection(for: service)
                }
                .padding(24)
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
            VStack(alignment: .leading, spacing: 6) {
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
    }
    
    @ViewBuilder
    private func serviceConfigurationSection(for service: TranslationServiceType) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            switch service {
            case .google:
                GoogleServiceConfigView()
            case .apple:
                AppleServiceConfigView(
                    sourceLanguage: $appleSourceLanguage,
                    targetLanguage: $appleTargetLanguage,
                    languageStatus: $appleLanguageStatus,
                    isChecking: $isCheckingAppleLanguage
                )
            case .deepseek:
                DeepSeekServiceConfigView(apiKey: $viewModel.deepSeekAPIKey)
            case .openai:
                OpenAIServiceConfigView()
            case .ollama:
                OllamaServiceConfigView()
            }
        }
    }
}

struct GoogleServiceConfigView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigCard {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("无需配置")
                            .font(.headline)
                        Text("开箱即用，无需 API Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            FeaturesSection(features: [
                ("gift", "免费使用"),
                ("key.slash", "无需 API Key"),
                ("globe", "支持多种语言")
            ])
        }
    }
}

struct AppleServiceConfigView: View {
    @Binding var sourceLanguage: Language
    @Binding var targetLanguage: Language
    @Binding var languageStatus: String
    @Binding var isChecking: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if #available(macOS 15.0, *) {
                ConfigCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("系统原生翻译")
                                .font(.headline)
                            Text("已就绪，无需额外配置")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                ConfigCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("语言包检测")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("源语言")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Picker("", selection: $sourceLanguage) {
                                    ForEach(Language.targetLanguages) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 100)
                            }
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("目标语言")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Picker("", selection: $targetLanguage) {
                                    ForEach(Language.targetLanguages) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 100)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            if !languageStatus.isEmpty {
                                StatusBadge(status: languageStatus)
                            }
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await checkLanguageStatus()
                                }
                            } label: {
                                if isChecking {
                                    ProgressView()
                                        .controlSize(.small)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Text("检测")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isChecking)
                            
                            if languageStatus == "支持" {
                                Button("下载") {
                                    openLanguageSettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                FeaturesSection(features: [
                    ("wifi.slash", "离线可用"),
                    ("lock.shield", "隐私保护"),
                    ("app.badge.checkmark", "系统级集成")
                ])
            } else {
                ConfigCard {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("系统版本不满足")
                                .font(.headline)
                            Text("需要 macOS 15.0 或更高版本")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func checkLanguageStatus() async {
        guard #available(macOS 15.0, *) else { return }
        
        isChecking = true
        languageStatus = ""
        defer { isChecking = false }
        
        let manager = AppleTranslationManager.shared
        let status = await manager.checkLanguageAvailability(
            from: sourceLanguage.rawValue,
            to: targetLanguage.rawValue
        )
        
        switch status {
        case .installed:
            languageStatus = "已安装"
        case .supported:
            languageStatus = "支持"
        case .unsupported:
            languageStatus = "不支持"
        @unknown default:
            languageStatus = "未知"
        }
    }
    
    private func openLanguageSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Localization") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct DeepSeekServiceConfigView: View {
    @Binding var apiKey: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("输入 DeepSeek API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Link("获取 DeepSeek API Key", destination: URL(string: "https://platform.deepseek.com/")!)
                            .font(.caption)
                    }
                }
            }
            
            FeaturesSection(features: [
                ("sparkles", "高质量翻译"),
                ("text.bubble", "支持上下文理解"),
                ("dollarsign.circle", "性价比高")
            ])
        }
    }
}

struct OpenAIServiceConfigView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigCard {
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
                        
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Link("获取 OpenAI API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                                .font(.caption)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API 端点")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("默认值可用")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        TextField("输入 API 端点", text: Binding(
                            get: { AppConfigService.shared.openAIEndpoint },
                            set: { AppConfigService.shared.openAIEndpoint = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("模型名称")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("默认: \(TranslationServiceType.openai.defaultModel)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        TextField("输入模型名称", text: Binding(
                            get: { AppConfigService.shared.openAIModel },
                            set: { AppConfigService.shared.openAIModel = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            FeaturesSection(features: [
                ("brain", "强大的语言理解能力"),
                ("network", "支持自定义端点"),
                ("cpu", "支持多种模型")
            ])
        }
    }
}

struct OllamaServiceConfigView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfigCard {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API 端点")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("默认值可用")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        TextField("输入 Ollama 端点", text: Binding(
                            get: { AppConfigService.shared.ollamaEndpoint },
                            set: { AppConfigService.shared.ollamaEndpoint = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("模型名称")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("默认: \(TranslationServiceType.ollama.defaultModel)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        TextField("输入模型名称", text: Binding(
                            get: { AppConfigService.shared.ollamaModel },
                            set: { AppConfigService.shared.ollamaModel = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("确保 Ollama 服务正在运行")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Link("Ollama 官网", destination: URL(string: "https://ollama.ai/")!)
                            .font(.caption)
                    }
                }
            }
            
            FeaturesSection(features: [
                ("house", "完全本地运行"),
                ("lock.shield", "隐私安全"),
                ("wifi.slash", "无需网络"),
                ("cube.box", "支持多种开源模型")
            ])
        }
    }
}
