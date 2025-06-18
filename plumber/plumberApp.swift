// plumberApp.swift
import SwiftUI

@main
struct plumberApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var pipelineStore = PipelineStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(pipelineStore) // Inject the pipeline store
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(pipelineStore) // Also inject it here
        }
    }
}
