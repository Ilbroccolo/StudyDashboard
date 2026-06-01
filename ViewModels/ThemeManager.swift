import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @Published var hasStarted: Bool = false
    
    static let shared = ThemeManager()
}
