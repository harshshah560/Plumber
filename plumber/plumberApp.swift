import SwiftUI

@main
struct plumberApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(mapAppearance(settings.appearance))
        }
        
        // This now works because SettingsView exists again.
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
    
    private func mapAppearance(_ appearance: Appearance) -> ColorScheme? {
        switch appearance {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
