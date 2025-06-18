import SwiftUI

struct ContentView: View {
    @StateObject private var workflowStore = WorkflowStore()
    @StateObject private var monitoringService = MonitoringService()
    @StateObject private var settings = AppSettings()

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: WorkflowListView()) {
                    Label("Workflows", systemImage: "arrow.right.square")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .listStyle(.sidebar)
        } detail: {
            Text("Welcome to Plumber. Select 'Workflows' to begin.")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
        .environmentObject(workflowStore)
        .environmentObject(settings)
        .onAppear {
            // Tell the monitoring service to start observing our workflows
            monitoringService.start(with: workflowStore)
        }
    }
}
