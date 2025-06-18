// AppSettings.swift
import Foundation
import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("appearance") var appearance: Appearance = .system
}
