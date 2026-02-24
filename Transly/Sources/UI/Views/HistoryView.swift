import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    
    var body: some View {
        Group {
            if viewModel.historyItems.isEmpty {
                emptyView
            } else {
                historyList
            }
        }
        .task {
            await viewModel.loadHistory()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("暂无翻译历史")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List {
            ForEach(viewModel.historyItems) { item in
                HistoryItemView(item: item, formatDate: viewModel.formatDate)
                    .contextMenu {
                        Button("复制原文") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.sourceText, forType: .string)
                        }
                        Button("复制译文") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.translatedText, forType: .string)
                        }
                        Divider()
                        Button("删除", role: .destructive) {
                            Task { await viewModel.deleteItem(item) }
                        }
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    Task { await viewModel.deleteItem(viewModel.historyItems[index]) }
                }
            }
        }
        .listStyle(.inset)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("清空历史") {
                    Task { await viewModel.clearAll() }
                }
            }
        }
    }
}

struct HistoryItemView: View {
    let item: TranslationHistory
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.sourceLanguage.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text(item.targetLanguage.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatDate(item.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Text(item.sourceText)
                .font(.body)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            Text(item.translatedText)
                .font(.body)
                .lineLimit(2)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .frame(width: 450, height: 500)
}
