import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var recentEvents: [FileEvent] = []

    // This function now correctly accepts a Workflow object
    func logEvent(fileName: String, workflow: Workflow) {
        if recentEvents.count > 10 {
            recentEvents.removeFirst()
        }
        
        // This now uses the correct parameter name `workflowApplied`
        let event = FileEvent(fileName: fileName, workflowApplied: workflow, status: .success)
        
        recentEvents.append(event)
    }
}
