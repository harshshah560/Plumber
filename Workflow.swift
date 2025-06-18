//
//  Workflow.swift
//  plumber
//
//  Created by Harsh Shah on 6/16/25.
//


//
//  Workflow.swift
//  plumber
//
//  Created by Harsh Shah on 6/16/25.
//


import Foundation
import SwiftUI

// The top-level Workflow, replacing the old "Rule"
struct Workflow: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String // e.g., "Sort Incoming Invoices"
    var condition: RuleCondition // The trigger
    var actions: [ActionStep] // An array of actions to perform in order
    var isEnabled: Bool = true
    var color: CodableColor = .init(color: .blue)
}

// A single step in a Workflow
struct ActionStep: Codable, Identifiable, Hashable {
    var id = UUID()
    var type: ActionType
    // We will use this later to store settings like a rename pattern or destination path
    var parameters: [String: String] = [:]
}

// An enum of all possible actions our app can perform
enum ActionType: String, Codable, CaseIterable {
    case moveToFolder = "Move to Folder"
    case copyToFolder = "Copy to Folder"
    case rename = "Rename"
    case moveToTrash = "Move to Trash"
    case addTags = "Add Tags"
    // We can add more here later, like "Run Shell Script", "Create Archive", etc.
}


// --- These are our previous supporting types, now part of the new model ---

enum RuleCondition: Codable, Hashable {
    case fileExtensionsMatch([String])
    case nameContains(String)
    case kindIs(Kind)
    // ... other conditions ...
}

enum Kind: String, Codable, CaseIterable, Hashable {
    case image, video, audio, pdf, archive, folder
}

struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(color: Color) {
        let nsColor = NSColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nsColor.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    var toColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
