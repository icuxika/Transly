import ServiceManagement
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
                
                Toggle("自动复制翻译结果", isOn: $viewModel.settings.autoCopy)
            }
            
            Section("通用") {
                Toggle("在菜单栏显示", isOn: $viewModel.settings.showInMenuBar)
                Toggle("开机自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        setLaunchAtLogin(launchAtLogin)
                    }
            }
            
            Section("快捷键") {
                HStack {
                    Text("翻译剪贴板")
                    Spacer()
                    Text("⌘⇧T")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("翻译服务")
                    Spacer()
                    Text("MyMemory API")
                        .foregroundStyle(.secondary)
                }
                
                Link("访问 GitHub", destination: URL(string: "https://github.com")!)
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
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 450, height: 500)
}
