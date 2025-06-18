// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: PipelineStore // Get the store from the environment
    @State private var showingResetAlert = false

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $settings.appearance) {
                    Label("System", systemImage: "gearshape").tag(Appearance.system)
                    Label("Light", systemImage: "sun.max.fill").tag(Appearance.light)
                    Label("Dark", systemImage: "moon.fill").tag(Appearance.dark)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }
            
            Section(header: Text("Danger Zone")) {
                Button("Reset All Pipelines") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 500, alignment: .leading)
        .padding()
        .alert("Are you sure?", isPresented: $showingResetAlert) {
            Button("Reset All Pipelines", role: .destructive) {
                store.pipelines.removeAll()
                // Optionally add a confirmation log event
                EventLogService.shared.log(fileName: "Application", message: "All pipelines have been reset.", status: .info)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all of your pipelines. This action cannot be undone.")
        }
    }
}
