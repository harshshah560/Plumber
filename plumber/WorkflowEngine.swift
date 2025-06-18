import Foundation
import AppKit
import UniformTypeIdentifiers

struct WorkflowEngine {
    
    func processFolder(at folderURL: URL, with workflows: [Workflow]) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) else { return }
        
        for fileURL in files {
            if let workflow = workflows.first(where: { $0.isEnabled && fileMatchesCondition(fileURL, condition: $0.condition) }) {
                print("✅ Workflow '\(workflow.name)' matched file: \(fileURL.lastPathComponent)")
                execute(workflow: workflow, on: fileURL)
            }
        }
    }

    private func execute(workflow: Workflow, on fileURL: URL) {
        var currentURL = fileURL
        for action in workflow.actions {
            if let newURL = perform(action: action, on: currentURL) {
                currentURL = newURL
            } else {
                print("❌ Action failed, stopping workflow for this file.")
                break
            }
        }
    }

    private func perform(action: ActionStep, on fileURL: URL) -> URL? {
        switch action.type {
        case .moveToFolder:
            guard let path = action.parameters["path"], let destinationURL = URL(string: "file://\(path)") else { return nil }
            return moveItem(from: fileURL, to: destinationURL)
        default:
            print("Action type \(action.type.rawValue) not implemented yet.")
            return fileURL
        }
    }
    
    // --- THIS FUNCTION IS NOW COMPLETE ---
    private func fileMatchesCondition(_ fileURL: URL, condition: RuleCondition) -> Bool {
        let whitespace = CharacterSet.whitespacesAndNewlines

        switch condition {
        case .fileExtensionsMatch(let requiredExtensions):
            let fileExtension = fileURL.pathExtension.lowercased()
            return requiredExtensions.contains { $0.lowercased().trimmingCharacters(in: whitespace) == fileExtension }

        case .nameContains(let keyword):
            let fileName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            return fileName.contains(keyword.lowercased().trimmingCharacters(in: whitespace))

        // --- MISSING CASES ADDED ---
        case .nameBeginsWith(let prefix):
            let fileName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            return fileName.hasPrefix(prefix.lowercased().trimmingCharacters(in: whitespace))

        case .nameEndsWith(let suffix):
            let fileName = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            return fileName.hasSuffix(suffix.lowercased().trimmingCharacters(in: whitespace))

        case .kindIs(let kind):
            guard let fileType = try? fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false }
            switch kind {
            case .image:   return fileType.conforms(to: .image)
            case .video:   return fileType.conforms(to: .movie)
            case .audio:   return fileType.conforms(to: .audio)
            case .pdf:     return fileType.conforms(to: .pdf)
            case .archive: return fileType.conforms(to: .archive)
            case .folder:  return fileType.conforms(to: .folder)
            }
        }
    }
    
    private func moveItem(from sourceURL: URL, to destinationFolderURL: URL) -> URL? {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
            let destinationURL = destinationFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            print("➡️ Moved file to: \(destinationURL.path)")
            return destinationURL
        } catch {
            print("❌ Error moving file: \(error.localizedDescription)")
            return nil
        }
    }
}
