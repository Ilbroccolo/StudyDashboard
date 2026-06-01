import SwiftUI

@main
struct StudyDashboardApp: App {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        // FIX CRITICO: Forza macOS a trattare il binario CLI come un'App regolare che riceve focus tastiera!
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandMenu("Dashboard") {
                Button("Genera Piano Studio") {
                    viewModel.showWellnessCheck = true
                }
                .keyboardShortcut("P", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Passa a Dark/Light Mode") {
                    themeManager.isDarkMode.toggle()
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])
            }
        }
    }
}
