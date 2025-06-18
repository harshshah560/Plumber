import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ProcessingMode: String, Codable, CaseIterable, Hashable {
    case onNewFilesOnly = "On New Files"
    case onAllExistingAndNewFiles = "On All Files"
}

struct Valve: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var condition: Condition
    var actions: [ActionStep]
}

struct Pipeline: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var intakePaths: [String] = []
    var valves: [Valve] = []
    var isEnabled: Bool = true
    var color: CodableColor = .init(color: .blue)
    var processingMode: ProcessingMode = .onNewFilesOnly
}

struct ActionStep: Codable, Identifiable, Hashable {
    var id = UUID()
    var type: ActionType
    var parameters: [String: String] = [:]
}

enum ActionType: String, Codable, CaseIterable, Hashable {
    case moveToFolder = "Move to Folder"
    case copyToFolder = "Copy to Folder"
    case rename = "Rename with Pattern"
    case addTag = "Add Tags"
    case runShellScript = "Run Shell Script"
}

enum Condition: Codable, Hashable {
    case fileExtensionsMatch([String])
    case nameContains(String)
    case nameBeginsWith(String)
    case nameEndsWith(String)
    case kindIs(Kind)
    case dateAdded(Int)
    case sizeIs(Double, Comparison)
    
    enum Comparison: String, Codable, CaseIterable, Hashable {
        case greaterThan = "is greater than"
        case lessThan = "is less than"
    }

    var conditionType: Condition.ConditionType {
        switch self {
        case .fileExtensionsMatch: .fileExtension
        case .nameContains: .nameContains
        case .nameBeginsWith: .nameBeginsWith
        case .nameEndsWith: .nameEndsWith
        case .kindIs: .kindIs
        case .dateAdded: .dateAdded
        case .sizeIs: .sizeIs
        }
    }
}

enum Kind: String, Codable, CaseIterable, Hashable {
    case image, video, audio, pdf, archive, folder

    func conforms(to contentType: UTType) -> Bool {
        switch self {
        case .image:   return contentType.conforms(to: .image)
        case .video:   return contentType.conforms(to: .movie)
        case .audio:   return contentType.conforms(to: .audio)
        case .pdf:     return contentType.conforms(to: .pdf)
        case .archive: return contentType.conforms(to: .archive)
        case .folder:  return contentType.conforms(to: .folder)
        }
    }

    func matches(extension ext: String) -> Bool {
        let extensions: Set<String>
        switch self {
        case .image:   extensions = ["jpg", "jpeg", "png", "gif", "heic", "tiff", "webp", "svg", "bmp"]
        case .video:   extensions = ["mov", "mp4", "m4v", "mkv", "avi", "webm", "flv"]
        case .audio:   extensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]
        case .pdf:     extensions = ["pdf"]
        case .archive: extensions = ["zip", "rar", "7z", "tar", "gz"]
        case .folder:  return false
        }
        return extensions.contains(ext)
    }
}

struct CodableColor: Codable, Hashable {
    var red: Double, green: Double, blue: Double, opacity: Double
    init(color: Color) {
        let nsColor = NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.opacity = Double(a)
    }
    var toColor: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity) }
}

extension Condition {
    enum ConditionType: String, CaseIterable, Identifiable {
        case fileExtension = "Extension is"
        case nameContains = "Name contains"
        case nameBeginsWith = "Name begins with"
        case nameEndsWith = "Name ends with"
        case kindIs = "Kind is"
        case dateAdded = "Date Added"
        case sizeIs = "Size"
        var id: Self { self }
    }
}
