import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var settings: AppSettings = .default
    
    private let storageService = StorageService.shared
    
    func loadSettings() async {
        settings = await storageService.loadSettings()
    }
    
    func saveSettings() async {
        await storageService.saveSettings(settings)
    }
}
