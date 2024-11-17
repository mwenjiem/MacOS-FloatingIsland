import SwiftUI

struct SettingsView: View {
    @AppStorage("requireClickToExpand") private var requireClickToExpand = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .padding(.bottom, 8)
            
            Toggle("Require click to expand FloatingIsland", isOn: $requireClickToExpand)
                .help("When enabled, FloatingIsland will only expand when clicked")
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 200)
    }
} 