import Foundation
import SwiftUI

@MainActor
@Observable
final class HistoryViewModel {
    var historyItems: [TranslationHistory] = []
    
    private let storageService = StorageService.shared
    
    func loadHistory() async {
        historyItems = await storageService.loadHistory()
    }
    
    func deleteItem(_ item: TranslationHistory) async {
        await storageService.removeFromHistory(item.id)
        historyItems.removeAll { $0.id == item.id }
    }
    
    func clearAll() async {
        await storageService.clearHistory()
        historyItems = []
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
