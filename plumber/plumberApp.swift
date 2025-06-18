// plumberApp.swift
import SwiftUI

@main
struct plumberApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}
