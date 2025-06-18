import SwiftUI

struct ContentView: View {
    @StateObject private var pipelineStore = PipelineStore()
    @StateObject private var monitoringService = MonitoringService()
    @StateObject private var eventLog = EventLogService.shared

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Dashboard", systemImage: "flowchart.fill")
                }
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.2.fill")
                }
            }
            .listStyle(.sidebar)
        } detail: {
            // --- FIX: More professional placeholder text ---
            Text("Select an item from the sidebar")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .environmentObject(pipelineStore)
        .environmentObject(eventLog)
        .onAppear {
            _ = FolderAccessManager.restoreAllAccess()
            monitoringService.start(with: pipelineStore)
        }
    }
}
