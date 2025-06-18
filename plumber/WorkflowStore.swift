import Foundation
import Combine
import SwiftUI

class WorkflowStore: ObservableObject {
    @Published var workflows: [Workflow] = []
    private var autosave: AnyCancellable?

    init() {
        loadWorkflows()
        autosave = $workflows.debounce(for: .seconds(0.5), scheduler: RunLoop.main).sink { _ in self.saveWorkflows() }
    }
    
    func moveWorkflow(from source: IndexSet, to destination: Int) { workflows.move(fromOffsets: source, toOffset: destination) }
    func addWorkflow(_ workflow: Workflow) { workflows.append(workflow) }
    func removeWorkflows(withIDs ids: Set<Workflow.ID>) { workflows.removeAll { ids.contains($0.id) } }
    func updateWorkflow(_ workflow: Workflow) {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
        }
    }

    private static func getFileURL() throws -> URL {
        let supportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDirectoryURL = supportURL.appendingPathComponent("Plumber")
        try FileManager.default.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        return appDirectoryURL.appendingPathComponent("workflows.json")
    }

    private func saveWorkflows() {
        do {
            let url = try Self.getFileURL()
            let data = try JSONEncoder().encode(workflows)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ Failed to save workflows: \(error.localizedDescription)")
        }
    }
    
    private func loadWorkflows() {
        do {
            let url = try Self.getFileURL()
            let data = try Data(contentsOf: url)
            workflows = try JSONDecoder().decode([Workflow].self, from: data)
        } catch {
            print("⚠️ Could not load workflows, starting fresh.")
            workflows = [] // Start with an empty list if loading fails
        }
    }
}
