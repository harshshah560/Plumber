import Foundation
import SwiftUI

struct Workflow: Codable, Identifiable, Hashable {
    var id = UUID()
    var sourceFolderPaths: [String] = []
    
    var name: String
    var condition: RuleCondition
    var actions: [ActionStep]
    var isEnabled: Bool = true
    var color: CodableColor = .init(color: .blue)

    // Manual initializer updated with the new property
    init(id: UUID = UUID(), sourceFolderPaths: [String] = [], name: String, condition: RuleCondition, actions: [ActionStep], isEnabled: Bool = true, color: CodableColor = .init(color: .blue)) {
        self.id = id
        self.sourceFolderPaths = sourceFolderPaths
        self.name = name
        self.condition = condition
        self.actions = actions
        self.isEnabled = isEnabled
        self.color = color
    }
}

// A single step in a Workflow
struct ActionStep: Codable, Identifiable, Hashable {
    var id = UUID()
    var type: ActionType
    var parameters: [String: String] = [:]
}

// An enum of all possible actions
enum ActionType: String, Codable, CaseIterable, Hashable {
    case moveToFolder = "Move to Folder"
    // Future actions will be added here
}

// All supporting enums and structs
enum RuleCondition: Codable, Hashable {
    case fileExtensionsMatch([String])
    case nameContains(String)
    case nameBeginsWith(String)
    case nameEndsWith(String)
    case kindIs(Kind)
}

enum Kind: String, Codable, CaseIterable, Hashable {
    case image, video, audio, pdf, archive, folder
}

// This helper enum is used by the editor UI
extension RuleCondition {
    enum ConditionType: String, CaseIterable, Identifiable {
        case fileExtension = "Extension is one of"
        case nameContains = "Name contains"
        case nameBeginsWith = "Name begins with"
        case nameEndsWith = "Name ends with"
        case kindIs = "Kind is"
        var id: Self { self }
        var name: String { self.rawValue }
    }
}

// The corrected, Codable version of Color
struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(color: Color) {
        let nsColor = NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.opacity = Double(a)
    }
    
    var toColor: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity) }
}

extension RuleCondition.ConditionType {
    var placeholder: String {
        switch self {
        case .fileExtension: return "e.g., jpg, png, gif"
        case .nameContains: return "e.g., invoice, receipt"
        case .nameBeginsWith: return "e.g., IMG_, DSC_"
        case .nameEndsWith: return "e.g., _final, _backup"
        case .kindIs: return "" // Not used for this type
        }
    }
}
