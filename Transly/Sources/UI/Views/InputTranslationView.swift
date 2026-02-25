import AppKit
import SwiftUI

struct InputTranslationView: View {
    @State private var inputText: String
    @State private var multiResult: MultiTranslationResult?
    @State private var isTranslating: Bool = false
    @State private var sourceLanguage: Language = .auto
    @State private var targetLanguage: Language = .chinese
    @State private var expandedServices: Set<TranslationServiceType> = Set(TranslationServiceType.availableServices)
    @State private var isOCRMode: Bool
    @State private var ocrError: Bool
    @State private var pendingServices: Set<TranslationServiceType> = []
    @State private var debounceTask: Task<Void, Never>?
    @State private var isAlwaysOnTop: Bool = false
    
    private let translationService = TranslationService.shared
    private let clipboardService = ClipboardService.shared
    private let config = AppConfigService.shared
    
    private var enabledServices: [TranslationServiceType] {
        Array(config.enabledTranslationServices)
    }
    
    init(initialText: String = "", isOCRMode: Bool = false, ocrError: Bool = false) {
        self._inputText = State(initialValue: initialText)
        self._isOCRMode = State(initialValue: isOCRMode)
        self._ocrError = State(initialValue: ocrError)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            inputSection
            
            Divider()
                .padding(.horizontal, 16)
            
            languageSelectorSection
            
            Divider()
                .padding(.horizontal, 16)
            
            translationResultsSection
        }
        .frame(width: 420, height: 500)
        .onChange(of: inputText) { _, newValue in
            debounceTask?.cancel()
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                debounceTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if !Task.isCancelled {
                        await translateText()
                    }
                }
            } else {
                multiResult = nil
            }
        }
        .task {
            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await translateText()
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("输入文本")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    isAlwaysOnTop.toggle()
                    if let window = NSApplication.shared.keyWindow {
                        if isAlwaysOnTop {
                            window.level = .floating
                        } else {
                            window.level = .normal
                        }
                    }
                }) {
                    Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                        .font(.caption)
                        .foregroundStyle(isAlwaysOnTop ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help(isAlwaysOnTop ? "取消置顶" : "置顶窗口")
                
                Button("粘贴") {
                    if let pasteboardText = NSPasteboard.general.string(forType: .string) {
                        inputText = pasteboardText
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
                
                Button("清空") {
                    inputText = ""
                    multiResult = nil
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            TextEditor(text: $inputText)
                .frame(height: 80)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(16)
    }
    
    private var languageSelectorSection: some View {
        HStack(spacing: 8) {
            LanguagePicker(
                title: "源语言",
                selectedLanguage: $sourceLanguage,
                languages: Language.sourceLanguages
            )
            .frame(maxWidth: 120)
            
            Button(action: {
                swapLanguages()
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            
            LanguagePicker(
                title: "目标语言",
                selectedLanguage: $targetLanguage,
                languages: Language.targetLanguages
            )
            .frame(maxWidth: 120)
            
            Spacer()
            
            Button(action: {
                Task { await translateText() }
            }) {
                if isTranslating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTranslating)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var translationResultsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if isOCRMode {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("OCR识别中...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if !pendingServices.isEmpty || multiResult != nil {
                    ForEach(TranslationServiceType.availableServices, id: \.self) { service in
                        if let result = multiResult?.results.first(where: { $0.serviceType == service }) {
                            ServiceResultCard(
                                result: result,
                                isExpanded: expandedServices.contains(service),
                                onToggle: { toggleService(service) },
                                onCopy: { Task { await clipboardService.copy(result.translatedText) } }
                            )
                        } else if pendingServices.contains(service) {
                            PendingServiceCard(
                                serviceType: service,
                                isExpanded: expandedServices.contains(service),
                                onToggle: { toggleService(service) }
                            )
                        }
                    }
                } else if isTranslating {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("翻译中...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: ocrError ? "exclamationmark.triangle" : "textformat")
                            .font(.system(size: 36))
                            .foregroundStyle(ocrError ? .red : .secondary)
                        
                        Text(ocrError ? "OCR识别失败，请重试" : "输入文本开始翻译")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(16)
        }
    }
    
    private func swapLanguages() {
        if sourceLanguage != .auto {
            let temp = sourceLanguage
            sourceLanguage = targetLanguage
            targetLanguage = temp
        }
    }
    
    private func toggleService(_ service: TranslationServiceType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedServices.contains(service) {
                expandedServices.remove(service)
            } else {
                expandedServices.insert(service)
            }
        }
    }
    
    private func translateText() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isTranslating = true
        multiResult = MultiTranslationResult(sourceText: inputText, results: [])
        pendingServices = Set(enabledServices)
        
        let services = enabledServices
        
        let result = await translationService.translateWithProgress(
            text: inputText,
            from: sourceLanguage,
            to: targetLanguage,
            services: services
        ) { serviceResult in
            Task { @MainActor in
                if multiResult == nil {
                    multiResult = MultiTranslationResult(sourceText: inputText, results: [serviceResult])
                } else {
                    var currentResults = multiResult!.results
                    if let existingIndex = currentResults.firstIndex(where: { $0.serviceType == serviceResult.serviceType }) {
                        currentResults[existingIndex] = serviceResult
                    } else {
                        currentResults.append(serviceResult)
                    }
                    
                    let sortedResults = services.compactMap { service in
                        currentResults.first { $0.serviceType == service }
                    }
                    
                    multiResult = MultiTranslationResult(sourceText: inputText, results: sortedResults.isEmpty ? currentResults : sortedResults)
                    pendingServices.remove(serviceResult.serviceType)
                }
            }
        }
        
        multiResult = result
        isTranslating = false
    }
}

struct ServiceResultCard: View {
    let result: TranslationServiceResult
    let isExpanded: Bool
    let onToggle: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    Text(result.serviceType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if result.error != nil {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if !result.translatedText.isEmpty {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    
                    if isExpanded && result.error == nil && !result.translatedText.isEmpty {
                        Button(action: onCopy) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                
                if let error = result.error {
                    Text("翻译失败: \(error.localizedDescription)")
                        .font(.body)
                        .foregroundStyle(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if !result.translatedText.isEmpty {
                    Text(result.translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

#Preview {
    InputTranslationView()
}

struct PendingServiceCard: View {
    let serviceType: TranslationServiceType
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    Text(serviceType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)
                
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("翻译中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
