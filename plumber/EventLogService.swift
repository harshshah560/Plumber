import Foundation
import SwiftUI

/// A struct representing a single event in the activity log.
struct LogEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let fileName: String
    let message: String
    let status: LogStatus
}

/// An enum representing the status of a log event.
enum LogStatus {
    case info
    case success
    case failure
    
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .failure: return .red
        }
    }
}

/// An ObservableObject that manages and publishes a log of file events.
@MainActor
class EventLogService: ObservableObject {
    @Published private(set) var events: [LogEvent] = []
    
    static let shared = EventLogService()
    
    private init() {}
    
    func log(fileName: String, message: String, status: LogStatus) {
        let newEvent = LogEvent(timestamp: Date(), fileName: fileName, message: message, status: status)
        events.insert(newEvent, at: 0)
        if events.count > 100 {
            events.removeLast()
        }
    }
}
