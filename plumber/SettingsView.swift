// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

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
                .frame(width: 150)
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Notify on Success", isOn: .constant(true))
                Toggle("Notify on Failure", isOn: .constant(true))
            }
            
            Section(header: Text("Danger Zone")) {
                Button("Reset All Pipelines") {
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 500, alignment: .leading)
        .padding()
    }
}
