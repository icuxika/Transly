import SwiftUI

struct TranslationResultView: View {
    let text: String
    let isLoading: Bool
    let error: String?
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("翻译结果")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !text.isEmpty {
                    Button(action: onCopy) {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
            
            ScrollView {
                if isLoading {
                    ProgressView("翻译中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if text.isEmpty {
                    Text("翻译结果将显示在这里")
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text(text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minHeight: 100, maxHeight: 200)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    VStack {
        TranslationResultView(
            text: "你好世界",
            isLoading: false,
            error: nil,
            onCopy: {}
        )
        TranslationResultView(
            text: "",
            isLoading: true,
            error: nil,
            onCopy: {}
        )
    }
    .padding()
    .frame(width: 400)
}
