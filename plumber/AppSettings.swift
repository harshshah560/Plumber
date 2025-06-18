//
//  Appearance.swift
//  plumber
//
//  Created by Harsh Shah on 6/16/25.
//


import Foundation
import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }
}

class AppSettings: ObservableObject {
    @Published var appearance: Appearance = .system
}