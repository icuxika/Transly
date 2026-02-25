import Foundation

actor StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let historyKey = "translationHistory"
    private let maxHistoryCount = 100
    
    private init() {}
    
    func loadHistory() -> [TranslationHistory] {
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([TranslationHistory].self, from: data) else {
            return []
        }
        return history
    }
    
    func saveHistory(_ history: [TranslationHistory]) {
        let trimmedHistory = Array(history.prefix(maxHistoryCount))
        guard let data = try? JSONEncoder().encode(trimmedHistory) else { return }
        defaults.set(data, forKey: historyKey)
    }
    
    func addToHistory(_ item: TranslationHistory) {
        var history = loadHistory()
        history.insert(item, at: 0)
        saveHistory(history)
    }
    
    func removeFromHistory(_ id: UUID) {
        var history = loadHistory()
        history.removeAll { $0.id == id }
        saveHistory(history)
    }
    
    func clearHistory() {
        defaults.removeObject(forKey: historyKey)
    }
}
