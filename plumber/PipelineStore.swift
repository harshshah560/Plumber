// PipelineStore.swift (was WorkflowStore.swift)
import Foundation
import Combine

class PipelineStore: ObservableObject {
    @Published var pipelines: [Pipeline] = []
    private var autosave: AnyCancellable?

    init() {
        loadPipelines()
        autosave = $pipelines.debounce(for: .seconds(0.5), scheduler: RunLoop.main).sink { _ in self.savePipelines() }
    }
    
    func movePipeline(from source: IndexSet, to destination: Int) { pipelines.move(fromOffsets: source, toOffset: destination) }
    func addPipeline(_ pipeline: Pipeline) { pipelines.append(pipeline) }
    func removePipelines(withIDs ids: Set<Pipeline.ID>) { pipelines.removeAll { ids.contains($0.id) } }
    func updatePipeline(_ pipeline: Pipeline) {
        if let index = pipelines.firstIndex(where: { $0.id == pipeline.id }) {
            pipelines[index] = pipeline
        }
    }

    private static func getFileURL() throws -> URL {
        let supportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDirectoryURL = supportURL.appendingPathComponent("Plumber")
        try FileManager.default.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        return appDirectoryURL.appendingPathComponent("pipelines.json")
    }

    private func savePipelines() {
        do {
            let url = try Self.getFileURL()
            let data = try JSONEncoder().encode(pipelines)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ Failed to save pipelines: \(error.localizedDescription)")
        }
    }
    
    private func loadPipelines() {
        do {
            let url = try Self.getFileURL()
            let data = try Data(contentsOf: url)
            pipelines = try JSONDecoder().decode([Pipeline].self, from: data)
        } catch {
            print("⚠️ Could not load pipelines, starting fresh.")
            pipelines = []
        }
    }
}
