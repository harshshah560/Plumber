import Foundation
import AppKit
import UniformTypeIdentifiers

struct PipelineEngine {
    
    private let logger = EventLogService.shared

    func processFolder(at folderURL: URL, with pipelines: [Pipeline]) async {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .totalFileSizeKey, .contentTypeKey]
        guard let files = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: resourceKeys, options: .skipsHiddenFiles) else { return }
        
        for fileURL in files where !fileURL.hasDirectoryPath {
            await logger.log(fileName: fileURL.lastPathComponent, message: "Detected in \(folderURL.lastPathComponent)", status: .info)
            
            let relevantPipelines = pipelines.filter { $0.isEnabled && $0.intakePaths.contains(folderURL.path) }

            for pipeline in relevantPipelines {
                if await execute(pipeline: pipeline, on: fileURL) {
                    await logger.log(fileName: fileURL.lastPathComponent, message: "Pipeline '\(pipeline.name)' completed.", status: .success)
                    break
                }
            }
        }
    }

    private func execute(pipeline: Pipeline, on fileURL: URL) async -> Bool {
        var fileWasProcessed = false
        var currentURL = fileURL
        
        let shouldStopAccessing = currentURL.startAccessingSecurityScopedResource()
        defer { if shouldStopAccessing { currentURL.stopAccessingSecurityScopedResource() } }
        
        await logger.log(fileName: fileURL.lastPathComponent, message: "Testing against pipeline '\(pipeline.name)'...", status: .info)

        for valve in pipeline.valves {
            if await fileMatchesCondition(currentURL, condition: valve.condition) {
                await logger.log(fileName: currentURL.lastPathComponent, message: "✅ Matched valve '\(valve.name)'", status: .success)
                
                if valve.actions.isEmpty {
                    fileWasProcessed = true
                    continue
                }

                for action in valve.actions {
                    let destinationPath = action.parameters["path"] ?? ""
                    let destinationURL = URL(fileURLWithPath: destinationPath)
                    
                    let shouldStopAccessingDestination = destinationURL.startAccessingSecurityScopedResource()
                    defer { if shouldStopAccessingDestination { destinationURL.stopAccessingSecurityScopedResource() } }
                    
                    if let newURL = await perform(action: action, on: currentURL) {
                        currentURL = newURL
                        fileWasProcessed = true
                    } else {
                        // If an action fails, we stop processing this pipeline for this file.
                        return fileWasProcessed
                    }
                }
            }
        }
        return fileWasProcessed
    }
    
    // --- (fileMatchesCondition function remains the same) ---
    private func fileMatchesCondition(_ fileURL: URL, condition: Condition) async -> Bool {
        let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey, .totalFileSizeKey, .contentTypeKey])
        
        switch condition {
        case .fileExtensionsMatch(let requiredExtensions):
            guard !requiredExtensions.isEmpty, let firstExt = requiredExtensions.first, !firstExt.isEmpty else { return false }
            let fileExtension = fileURL.pathExtension.lowercased()
            let result = requiredExtensions.contains { $0.lowercased().trimmingCharacters(in: .whitespaces) == fileExtension }
            if !result { await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Extension '\(fileExtension)' not in [\(requiredExtensions.joined(separator: ", "))].", status: .info) }
            return result
            
        case .nameContains(let keyword):
            guard !keyword.isEmpty else { return false }
            let result = fileURL.deletingPathExtension().lastPathComponent.localizedCaseInsensitiveContains(keyword)
            if !result { await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Name does not contain '\(keyword)'.", status: .info) }
            return result
            
        case .nameBeginsWith(let prefix):
            guard !prefix.isEmpty else { return false }
            let result = fileURL.deletingPathExtension().lastPathComponent.hasPrefix(prefix)
            if !result { await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Name does not begin with '\(prefix)'.", status: .info) }
            return result

        case .nameEndsWith(let suffix):
            guard !suffix.isEmpty else { return false }
            let result = fileURL.deletingPathExtension().lastPathComponent.hasSuffix(suffix)
            if !result { await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Name does not end with '\(suffix)'.", status: .info) }
            return result
            
        case .kindIs(let kind):
            if let fileType = resourceValues?.contentType, kind.conforms(to: fileType) {
                return true
            }
            let fileExtension = fileURL.pathExtension.lowercased()
            if kind.matches(extension: fileExtension) {
                await logger.log(fileName: fileURL.lastPathComponent, message: "Matched kind by extension fallback.", status: .info)
                return true
            }
            await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Kind is not '\(kind.rawValue)'.", status: .info)
            return false

        case .dateAdded(let days):
            guard let creationDate = resourceValues?.creationDate else {
                await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Could not read creation date.", status: .info); return false
            }
            let result = Calendar.current.isDateInLast(days, a: creationDate)
            if !result { await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Date added not within last \(days) days.", status: .info) }
            return result
            
        case .sizeIs(let sizeInMB, let comparison):
            guard let sizeInBytes = resourceValues?.totalFileSize else {
                await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Could not read file size.", status: .info); return false
            }
            let size = Double(sizeInBytes) / 1_000_000.0
            let result: Bool
            switch comparison {
            case .greaterThan: result = size > sizeInMB
            case .lessThan: result = size < sizeInMB
            }
            if !result { await logger.log(fileName: fileURL.lastPathComponent, message: "Condition failed: Size not \(comparison.rawValue) \(sizeInMB)MB.", status: .info) }
            return result
        }
    }
    
    // --- (perform function remains the same) ---
    private func perform(action: ActionStep, on fileURL: URL) async -> URL? {
        switch action.type {
        case .moveToFolder:
            guard let path = action.parameters["path"], !path.isEmpty, let destinationURL = URL(string: "file://\(path)") else { return nil }
            return await moveItem(from: fileURL, to: destinationURL)
        case .copyToFolder:
            guard let path = action.parameters["path"], !path.isEmpty, let destinationURL = URL(string: "file://\(path)") else { return nil }
            return await copyItem(from: fileURL, to: destinationURL)
        case .rename:
            guard let pattern = action.parameters["pattern"], !pattern.isEmpty else { return nil }
            let newName = expand(pattern: pattern, for: fileURL)
            return await renameItem(at: fileURL, to: newName)
        case .addTag:
            let tagNames = action.parameters["tags", default: ""].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return await addTags(to: fileURL, tags: tagNames)
        case .runShellScript:
            guard let script = action.parameters["script"], !script.isEmpty else { return nil }
            let fullScript = expand(pattern: script, for: fileURL)
            return await runScript(fullScript, on: fileURL)
        }
    }

    // --- (expand function remains the same) ---
    private func expand(pattern: String, for fileURL: URL) -> String {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        let parentPath = fileURL.deletingLastPathComponent().path
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        var result = pattern
        result = result.replacingOccurrences(of: "{filepath}", with: "'\(fileURL.path)'")
        result = result.replacingOccurrences(of: "{filename}", with: fileName)
        result = result.replacingOccurrences(of: "{ext}", with: fileExtension)
        result = result.replacingOccurrences(of: "{parent}", with: "'\(parentPath)'")
        result = result.replacingOccurrences(of: "{date}", with: dateString)
        return result
    }

    // --- NEW: A robust function to handle file name collisions ---
    private func getAvailableURL(for fileURL: URL, in destinationFolderURL: URL) -> URL {
        let fileManager = FileManager.default
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        
        var finalURL = destinationFolderURL.appendingPathComponent(fileURL.lastPathComponent)
        var counter = 1
        
        while fileManager.fileExists(atPath: finalURL.path) {
            let newName = "\(originalName) \(counter).\(fileExtension)"
            finalURL = destinationFolderURL.appendingPathComponent(newName)
            counter += 1
        }
        return finalURL
    }

    private func moveItem(from sourceURL: URL, to destinationFolderURL: URL) async -> URL? {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
            // --- FIX: Use our new function to prevent overwriting files ---
            let destinationURL = getAvailableURL(for: sourceURL, in: destinationFolderURL)
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Moved to \(destinationFolderURL.lastPathComponent) as \(destinationURL.lastPathComponent)", status: .success)
            return destinationURL
        } catch {
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Failed to move: \(error.localizedDescription)", status: .failure)
            return nil
        }
    }
    
    private func copyItem(from sourceURL: URL, to destinationFolderURL: URL) async -> URL? {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
            // --- FIX: Use our new function here as well ---
            let destinationURL = getAvailableURL(for: sourceURL, in: destinationFolderURL)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Copied to \(destinationFolderURL.lastPathComponent) as \(destinationURL.lastPathComponent)", status: .success)
            return sourceURL // Return the original URL as the file hasn't moved
        } catch {
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Failed to copy: \(error.localizedDescription)", status: .failure)
            return nil
        }
    }
    
    // --- (renameItem, addTags, runScript functions remain the same) ---
    private func renameItem(at sourceURL: URL, to newName: String) async -> URL? {
        let fileManager = FileManager.default
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Renamed to \(newName)", status: .success)
            return destinationURL
        } catch {
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Failed to rename: \(error.localizedDescription)", status: .failure)
            return nil
        }
    }
    
    private func addTags(to sourceURL: URL, tags: [String]) async -> URL? {
        do {
            let resourceValues = try sourceURL.resourceValues(forKeys: [.tagNamesKey])
            var existingTags = resourceValues.tagNames ?? []
            for tag in tags where !existingTags.contains(tag) { existingTags.append(tag) }
            try (sourceURL as NSURL).setResourceValue(existingTags, forKey: URLResourceKey.tagNamesKey)
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Tagged with: \(tags.joined(separator: ", "))", status: .success)
            return sourceURL
        } catch {
            await logger.log(fileName: sourceURL.lastPathComponent, message: "Failed to add tags: \(error.localizedDescription)", status: .failure)
            return nil
        }
    }

    private func runScript(_ script: String, on fileURL: URL) async -> URL? {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", script]
        
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                await logger.log(fileName: fileURL.lastPathComponent, message: "Shell script executed successfully.", status: .success)
                return fileURL
            } else {
                await logger.log(fileName: fileURL.lastPathComponent, message: "Shell script failed with exit code \(task.terminationStatus).", status: .failure)
                return nil
            }
        } catch {
            await logger.log(fileName: fileURL.lastPathComponent, message: "Failed to run shell script: \(error.localizedDescription)", status: .failure)
            return nil
        }
    }
}

extension Calendar {
    func isDateInLast(_ days: Int, a: Date, b: Date = Date()) -> Bool {
        guard days > 0,
              let bDate = self.ordinality(of: .day, in: .era, for: b),
              let aDate = self.ordinality(of: .day, in: .era, for: a) else { return false }
        return (bDate - aDate) < days
    }
}
