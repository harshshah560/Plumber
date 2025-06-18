import SwiftUI

/// An extension to add our custom .random() function to SwiftUI's Color.
extension Color {
    static func random() -> Color {
        return Color(red: Double.random(in: 0.3...0.9),
                     green: Double.random(in: 0.3...0.9),
                     blue: Double.random(in: 0.3...0.9))
    }
}
