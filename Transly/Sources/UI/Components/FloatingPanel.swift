import AppKit
import SwiftUI

class FloatingPanelWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.nonactivatingPanel, .hudWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = true
        backgroundColor = .clear
        hasShadow = true
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

struct FloatingPanelView: View {
    let selectedText: String
    let translatedText: String
    let isTranslating: Bool
    let sourceLanguage: Language
    let targetLanguage: Language
    let onCopy: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            Divider()
            
            if isTranslating {
                loadingView
            } else {
                contentView
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var header: some View {
        HStack {
            HStack(spacing: 4) {
                Text(sourceLanguage == .auto ? "自动" : sourceLanguage.displayName)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text(targetLanguage.displayName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                if !translatedText.isEmpty && !isTranslating {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("复制译文")
                }
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("关闭")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("翻译中...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 80)
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("原文")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text(selectedText)
                    .font(.body)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("译文")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text(translatedText)
                    .font(.body)
                    .foregroundStyle(.blue)
                    .lineLimit(5)
                    .textSelection(.enabled)
            }
        }
    }
}

#Preview {
    FloatingPanelView(
        selectedText: "Hello, World!",
        translatedText: "你好，世界！",
        isTranslating: false,
        sourceLanguage: .english,
        targetLanguage: .chinese,
        onCopy: {},
        onClose: {}
    )
    .frame(width: 320)
    .padding()
}
