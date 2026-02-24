import SwiftUI

struct TranslationView: View {
    @State private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            serviceSelector
            
            languageSelector
            
            inputSection
            
            actionButtons
            
            TranslationResultView(
                text: viewModel.translatedText,
                isLoading: viewModel.isTranslating,
                error: viewModel.errorMessage,
                onCopy: { Task { await viewModel.copyResult() } }
            )
        }
        .padding()
    }
    
    private var serviceSelector: some View {
        HStack {
            Text("翻译服务")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Picker("", selection: $viewModel.translationServiceType) {
                ForEach(TranslationServiceType.availableServices) { service in
                    Text(service.displayName).tag(service)
                }
            }
            .pickerStyle(.segmented)
            .frame(minWidth: 200)
        }
    }
    
    private var languageSelector: some View {
        HStack(spacing: 12) {
            LanguagePicker(
                title: "源语言",
                selectedLanguage: $viewModel.sourceLanguage,
                languages: Language.sourceLanguages
            )
            
            Button(action: { viewModel.swapLanguages() }) {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.sourceLanguage == .auto)
            
            LanguagePicker(
                title: "目标语言",
                selectedLanguage: $viewModel.targetLanguage,
                languages: Language.targetLanguages
            )
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("输入文本")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $viewModel.inputText)
                .focused($isInputFocused)
                .frame(minHeight: 80, maxHeight: 150)
                .font(.body)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Group {
                        if viewModel.inputText.isEmpty {
                            Text("输入要翻译的文本...")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                )
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("粘贴") {
                Task { await viewModel.pasteFromClipboard() }
            }
            
            Button("清空") {
                viewModel.clearInput()
            }
            
            Spacer()
            
            Button("翻译") {
                Task { await viewModel.translate() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canTranslate)
        }
    }
}

#Preview {
    TranslationView()
        .frame(width: 450, height: 550)
}
