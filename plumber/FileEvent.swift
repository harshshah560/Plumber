import Foundation
import SwiftUI

/// Represents a single file being processed by our engine for the dashboard UI.
struct FileEvent: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    
    // --- THIS IS THE FIX ---
    // The event is now associated with a Workflow, not a Rule.
    let workflowApplied: Pipeline?
    
    var status: Status = .pending
    
    // Equatable conformance for animations
    static func == (lhs: FileEvent, rhs: FileEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    enum Status {
        case pending, success, failure
    }
    
    /// Determines the color of the "pipe" or visual element for this event.
    var pipeColor: Color {
        guard let workflow = workflowApplied else { return .gray }
        return workflow.color.toColor
    }
}
