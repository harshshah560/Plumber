// PipelineEditorViewModel.swift (was RuleEditorViewModel.swift)
import Foundation
import SwiftUI
import AppKit

@MainActor
class PipelineEditorViewModel: ObservableObject {
    @Published var pipelineName: String
    @Published var intakeURLs: [URL] = []
    @Published var valves: [Valve] = []
    @Published var processingMode: ProcessingMode

    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    var editingPipelineID: Pipeline.ID?
    var navigationTitle: String

    init(pipelineToEdit: Pipeline? = nil) {
        if let pipeline = pipelineToEdit {
            self.editingPipelineID = pipeline.id
            self.navigationTitle = "Edit Pipeline"
            self.pipelineName = pipeline.name
            self.intakeURLs = pipeline.intakePaths.map { URL(fileURLWithPath: $0) }
            self.valves = pipeline.valves
            self.processingMode = pipeline.processingMode
        } else {
            self.editingPipelineID = nil
            self.navigationTitle = "New Pipeline"
            self.pipelineName = ""
            self.intakeURLs = []
            self.valves = [Valve(id: UUID(), name: "New Valve", condition: .fileExtensionsMatch(["pdf"]), actions: [ActionStep(type: .moveToFolder)])]
            self.processingMode = .onNewFilesOnly
        }
    }
    
    func addValve() {
        let newValve = Valve(id: UUID(), name: "Another Valve", condition: .nameContains(""), actions: [ActionStep(type: .moveToFolder)])
        valves.append(newValve)
    }

    func addIntakePipe() {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select Intake Pipe(s)"
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseFiles = false
        
        if openPanel.runModal() == .OK {
            for url in openPanel.urls {
                if !self.intakeURLs.contains(url) {
                    self.intakeURLs.append(url)
                    FolderAccessManager.saveBookmark(for: url)
                }
            }
        }
    }

    func removeIntakePipe(url: URL) {
        intakeURLs.removeAll { $0 == url }
        FolderAccessManager.removeBookmark(for: url)
    }
    
    func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func save(to store: PipelineStore) -> Bool {
        guard !pipelineName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a name for the pipeline."
            showErrorAlert = true
            return false
        }
        guard !valves.isEmpty else {
            errorMessage = "A pipeline must have at least one valve."
            showErrorAlert = true
            return false
        }
        guard !valves.flatMap(\.actions).isEmpty else {
            errorMessage = "A valve must have at least one action."
            showErrorAlert = true
            return false
        }

        let intakePaths = intakeURLs.map { $0.path }
        
        if let id = editingPipelineID {
            let originalPipeline = store.pipelines.first { $0.id == id }
            let color = originalPipeline?.color ?? .init(color: .random())
            let isEnabled = originalPipeline?.isEnabled ?? true
            var updatedPipeline = Pipeline(id: id, name: pipelineName, intakePaths: intakePaths, valves: self.valves, isEnabled: isEnabled, color: color)
            updatedPipeline.processingMode = self.processingMode
            store.updatePipeline(updatedPipeline)
        } else {
            var newPipeline = Pipeline(name: pipelineName, intakePaths: intakePaths, valves: self.valves, color: .init(color: .random()))
            newPipeline.processingMode = self.processingMode
            store.addPipeline(newPipeline)
        }
        
        return true
    }
}
