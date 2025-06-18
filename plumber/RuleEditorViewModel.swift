import Foundation
import SwiftUI
import AppKit

@MainActor
class RuleEditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var workflowName: String
    @Published var sourceFolderURLs: [URL] = []
    
    @Published var conditionType: RuleCondition.ConditionType
    @Published var textInputValue: String
    @Published var kindInputValue: Kind
    
    @Published var destinationURL: URL?
    
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    // MARK: - Properties
    
    var editingWorkflowID: Workflow.ID?
    var navigationTitle: String

    // MARK: - Initializer

    init(workflowToEdit: Workflow? = nil) {
        if let workflow = workflowToEdit {
            self.editingWorkflowID = workflow.id
            self.navigationTitle = "Edit Workflow"
            self.workflowName = workflow.name
            self.sourceFolderURLs = workflow.sourceFolderPaths.map { URL(fileURLWithPath: $0) }
            
            if let moveAction = workflow.actions.first(where: { $0.type == .moveToFolder }), let path = moveAction.parameters["path"] {
                self.destinationURL = URL(fileURLWithPath: path)
            } else {
                self.destinationURL = nil
            }
            
            switch workflow.condition {
            case .fileExtensionsMatch(let extensions):
                self.conditionType = .fileExtension
                self.textInputValue = extensions.joined(separator: ", ")
                self.kindInputValue = .image
            case .nameContains(let text):
                self.conditionType = .nameContains
                self.textInputValue = text
                self.kindInputValue = .image
            case .nameBeginsWith(let text):
                self.conditionType = .nameBeginsWith
                self.textInputValue = text
                self.kindInputValue = .image
            case .nameEndsWith(let text):
                self.conditionType = .nameEndsWith
                self.textInputValue = text
                self.kindInputValue = .image
            case .kindIs(let kind):
                self.conditionType = .kindIs
                self.kindInputValue = kind
                self.textInputValue = ""
            }
        } else {
            self.editingWorkflowID = nil
            self.navigationTitle = "New Workflow"
            self.workflowName = ""
            self.sourceFolderURLs = []
            self.conditionType = .fileExtension
            self.textInputValue = ""
            self.kindInputValue = .image
            self.destinationURL = nil
        }
    }
    
    // MARK: - Functions
    
    func addSourceFolder() {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select Source Folder(s)"
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseFiles = false
        
        if openPanel.runModal() == .OK {
            for url in openPanel.urls {
                if !self.sourceFolderURLs.contains(url) {
                    self.sourceFolderURLs.append(url)
                }
            }
        }
    }

    func removeSource(url: URL) {
        sourceFolderURLs.removeAll { $0 == url }
    }

    func selectDestinationFolder() {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Choose Destination Folder"
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = false
        if openPanel.runModal() == .OK {
            self.destinationURL = openPanel.url
        }
    }
    
    func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func save(to store: WorkflowStore) -> Bool {
        guard !workflowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.errorMessage = "Please enter a name for the workflow."
            self.showErrorAlert = true
            return false
        }
        guard !sourceFolderURLs.isEmpty else {
            self.errorMessage = "Please add at least one source folder to monitor."
            self.showErrorAlert = true
            return false
        }
        guard let destinationURL = destinationURL else {
            self.errorMessage = "Please select a destination folder."
            self.showErrorAlert = true
            return false
        }

        let finalCondition: RuleCondition
        
        switch conditionType {
        case .fileExtension:
            let extensions = textInputValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
            guard !extensions.isEmpty else { self.errorMessage = "Please enter at least one file extension."; self.showErrorAlert = true; return false }
            finalCondition = .fileExtensionsMatch(extensions)
        
        case .nameContains:
            guard !textInputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { self.errorMessage = "Please enter a value for 'Name contains'."; self.showErrorAlert = true; return false }
            finalCondition = .nameContains(textInputValue)
        case .nameBeginsWith:
            guard !textInputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { self.errorMessage = "Please enter a value for 'Name begins with'."; self.showErrorAlert = true; return false }
            finalCondition = .nameBeginsWith(textInputValue)
        case .nameEndsWith:
            guard !textInputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { self.errorMessage = "Please enter a value for 'Name ends with'."; self.showErrorAlert = true; return false }
            finalCondition = .nameEndsWith(textInputValue)
        case .kindIs:
            finalCondition = .kindIs(kindInputValue)
        }

        let action = ActionStep(type: .moveToFolder, parameters: ["path": destinationURL.path])
        let sourcePaths = sourceFolderURLs.map { $0.path }
        
        if let id = editingWorkflowID {
            let originalWorkflow = store.workflows.first { $0.id == id }
            let color = originalWorkflow?.color ?? .init(color: .random())
            let isEnabled = originalWorkflow?.isEnabled ?? true
            let updatedWorkflow = Workflow(id: id, sourceFolderPaths: sourcePaths, name: workflowName, condition: finalCondition, actions: [action], isEnabled: isEnabled, color: color)
            store.updateWorkflow(updatedWorkflow)
        } else {
            let newWorkflow = Workflow(sourceFolderPaths: sourcePaths, name: workflowName, condition: finalCondition, actions: [action], color: .init(color: .random()))
            store.addWorkflow(newWorkflow)
        }
        
        return true
    }
}
