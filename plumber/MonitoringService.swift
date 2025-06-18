//
//  MonitoringService.swift
//  plumber
//
//  Created by Harsh Shah on 6/17/25.
//


import Foundation
import Combine

@MainActor
class MonitoringService: ObservableObject {
    private var monitors: [String: DirectoryMonitor] = [:]
    private let engine = WorkflowEngine()
    private var workflowCancellable: AnyCancellable?
    
    func start(with workflowStore: WorkflowStore) {
        // Listen for any changes to the workflows (add, edit, delete, enable/disable)
        workflowCancellable = workflowStore.$workflows.sink { [weak self] workflows in
            self?.updateMonitors(for: workflows)
        }
    }
    
    private func updateMonitors(for workflows: [Workflow]) {
        // 1. Get a set of all unique, enabled source folder paths from all workflows
        let requiredPaths = Set(workflows.filter(\.isEnabled).flatMap(\.sourceFolderPaths))
        
        // 2. Stop any monitors for folders that are no longer needed
        for path in monitors.keys where !requiredPaths.contains(path) {
            monitors[path]?.stop()
            monitors.removeValue(forKey: path)
            print("⏹️ Stopped monitoring: \(path)")
        }
        
        // 3. Start new monitors for any new folders
        for path in requiredPaths where !monitors.keys.contains(path) {
            guard let url = URL(string: "file://\(path)") else { continue }
            let monitor = DirectoryMonitor(path: path) {
                print("Change detected in: \(path)")
                // When a change happens, run the engine on that specific folder
                self.engine.processFolder(at: url, with: workflows)
            }
            monitor.start()
            monitors[path] = monitor
            print("▶️ Started monitoring: \(path)")
        }
    }
}