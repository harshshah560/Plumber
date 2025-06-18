// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var pipelineStore: PipelineStore // Changed from @StateObject
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
            // --- FIX: A more welcoming and useful placeholder view ---
            WelcomeView()
        }
        .environmentObject(pipelineStore)
        .environmentObject(eventLog)
        .onAppear {
            _ = FolderAccessManager.restoreAllAccess()
            monitoringService.start(with: pipelineStore)
        }
    }
}

// --- NEW: A beautiful and informative view for new users ---
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pipe.and.drop.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Welcome to Plumber")
                .font(.largeTitle.bold())
            
            Text("Your personal automation tool for file organization.\nSelect 'Dashboard' to build your first pipeline, or 'Settings' to configure the app.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 450)
        }
        .padding()
    }
}
