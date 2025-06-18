// MonitoringService.swift
import Foundation
import Combine

@MainActor
class MonitoringService: ObservableObject {
    private var monitors: [String: DirectoryMonitor] = [:]
    private let engine = PipelineEngine()
    private var pipelineCancellable: AnyCancellable?
    
    func start(with pipelineStore: PipelineStore) {
        pipelineCancellable = pipelineStore.$pipelines.sink { [weak self] pipelines in
            self?.updateMonitors(for: pipelines)
        }
    }
    
    private func updateMonitors(for pipelines: [Pipeline]) {
        let requiredPaths = Set(pipelines.filter(\.isEnabled).flatMap(\.intakePaths))
        
        for path in monitors.keys where !requiredPaths.contains(path) {
            monitors[path]?.stop()
            monitors.removeValue(forKey: path)
            print("⏹️ Stopped monitoring: \(path)")
        }
        
        for path in requiredPaths where !monitors.keys.contains(path) {
            guard let url = URL(string: "file://\(path)") else { continue }
            
            let pipelinesForThisPath = pipelines.filter { $0.intakePaths.contains(path) }

            let monitor = DirectoryMonitor(path: path) {
                Task {
                    await self.engine.processFolder(at: url, with: pipelinesForThisPath)
                }
            }
            monitor.start()
            monitors[path] = monitor
            print("▶️ Started monitoring: \(path)")
            
            let pipelinesRequiringInitialScan = pipelinesForThisPath.filter { $0.isEnabled && $0.processingMode == .onAllExistingAndNewFiles }
            if !pipelinesRequiringInitialScan.isEmpty {
                print("🔍 Performing initial scan for \(path)...")
                Task {
                    await self.engine.processFolder(at: url, with: pipelinesRequiringInitialScan)
                }
            }
        }
    }
}
