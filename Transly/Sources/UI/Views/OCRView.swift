import AppKit
import SwiftUI

struct OCRView: View {
    @State private var viewModel = OCRViewModel()
    @State private var hasPermission = false
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            
            if viewModel.isProcessing {
                processingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.capturedImage != nil {
                resultView
            } else {
                placeholderView
            }
        }
        .padding()
        .onAppear {
            startPermissionMonitoring()
        }
    }
    
    private func startPermissionMonitoring() {
        // 立即检查一次权限状态
        Task {
            hasPermission = await viewModel.hasScreenRecordingPermission
        }
        
        // 每1秒检查一次权限状态
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                @MainActor in
                hasPermission = await viewModel.hasScreenRecordingPermission
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("OCR 翻译")
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 8) {
                LanguagePicker(
                    title: "源语言",
                    selectedLanguage: $viewModel.sourceLanguage,
                    languages: Language.sourceLanguages
                )
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                LanguagePicker(
                    title: "目标语言",
                    selectedLanguage: $viewModel.targetLanguage,
                    languages: Language.targetLanguages
                )
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("点击下方按钮截图识别")
                .font(.body)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button(action: {
                    Task { await viewModel.captureAndRecognize() }
                }) {
                    Label("全屏截图", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasPermission)
                
                Button(action: {
                    // 显示区域选择视图
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                        styleMask: [],
                        backing: .buffered,
                        defer: false
                    )
                    window.isReleasedWhenClosed = false
                    window.level = .screenSaver
                    
                    let contentView = NSHostingView(rootView: RegionSelection(completion: { [self] rect in
                        Task { await viewModel.captureRegionAndRecognize(rect: rect) }
                        window.close()
                    }))
                    window.contentView = contentView
                    window.makeKeyAndOrderFront(nil)
                }) {
                    Label("区域截图", systemImage: "crop")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasPermission)
            }
            
            if !hasPermission {
                Text("需要屏幕录制权限")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在识别...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.red)
            
            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("重新选择区域") {
                    showRegionSelection()
                }
                .buttonStyle(.bordered)
                
                Button("重试上次") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func showRegionSelection() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        
        let contentView = NSHostingView(rootView: RegionSelection(completion: { rect in
            Task { await viewModel.captureRegionAndRecognize(rect: rect) }
            window.close()
        }))
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
    }
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = viewModel.capturedImage {
                    imageView(image)
                }
                
                Divider()
                
                recognizedTextView
                
                if !viewModel.translatedText.isEmpty {
                    Divider()
                    
                    translatedTextView
                }
                
                actionButtons
            }
        }
    }
    
    private func imageView(_ image: NSImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("截图预览")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
        }
    }
    
    private var recognizedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("识别文字")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("复制") {
                    Task { await viewModel.copyRecognizedText() }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            Text(viewModel.recognizedText)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var translatedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("翻译结果")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("复制") {
                    Task { await viewModel.copyTranslatedText() }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            if viewModel.isTranslating {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text(viewModel.translatedText)
                    .font(.body)
                    .foregroundStyle(.blue)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Button("重新截图") {
                Task { await viewModel.retry() }
            }
            
            Spacer()
            
            Button("清空") {
                viewModel.clear()
            }
        }
    }
}

#Preview {
    OCRView()
        .frame(width: 450, height: 600)
}
