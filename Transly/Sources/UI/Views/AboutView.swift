import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    private let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            
            Text("Transly")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 \(appVersion) (\(buildVersion))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("一款原生 macOS 菜单栏翻译应用")
                .font(.body)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Link(destination: URL(string: "https://github.com/icuxika/Transly")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub")
                    }
                }
                .buttonStyle(.link)
                
                Text("MIT License")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 320, height: 350)
    }
}

#Preview {
    AboutView()
}
