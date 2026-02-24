import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section("翻译设置") {
                Picker("默认源语言", selection: $viewModel.settings.sourceLanguage) {
                    ForEach(Language.sourceLanguages) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                
                Picker("默认目标语言", selection: $viewModel.settings.targetLanguage) {
                    ForEach(Language.targetLanguages) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }
            
            Section("通用") {
                Toggle("自动复制翻译结果", isOn: $viewModel.settings.autoCopy)
                Toggle("在菜单栏显示", isOn: $viewModel.settings.showInMenuBar)
                Toggle("开机自动启动", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .task {
            await viewModel.loadSettings()
        }
        .onChange(of: viewModel.settings) {
            Task { await viewModel.saveSettings() }
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 450, height: 400)
}
