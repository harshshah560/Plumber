//
//  DashboardView.swift
//  plumber
//
//  Created by Harsh Shah on 6/16/25.
//


import SwiftUI

struct DashboardView: View {
    // It must accept the viewModel to match the call site in ContentView
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        Text("Dashboard coming soon.")
            .navigationTitle("Dashboard")
    }
}