import SwiftUI

// MARK: - Main Dashboard View
struct DashboardView: View {
    @EnvironmentObject var store: PipelineStore
    @EnvironmentObject var eventLog: EventLogService
    
    @State private var showingEditorSheet = false
    @State private var pipelineToEdit: Pipeline?
    @State private var searchText = ""
    @State private var showActivityLog = false
    @State private var hoveredPipelineID: Pipeline.ID?

    private var filteredPipelines: [Pipeline] {
        if searchText.isEmpty {
            return store.pipelines
        } else {
            return store.pipelines.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mainContent
            LiveActivityDrawerView(showActivityLog: $showActivityLog)
                .ignoresSafeArea()
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    pipelineToEdit = nil
                    showingEditorSheet = true
                }) {
                    Label("Build Pipeline", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEditorSheet) {
            PipelineEditorView(isSheetPresented: $showingEditorSheet, pipelineToEdit: pipelineToEdit)
                .environmentObject(store)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        let columns = [GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 15)]

        if store.pipelines.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(filteredPipelines) { pipeline in
                        if let index = store.pipelines.firstIndex(where: { $0.id == pipeline.id }) {
                            PipelineCardView(pipeline: $store.pipelines[index], isHovered: hoveredPipelineID == pipeline.id)
                                .onHover { hovering in
                                    withAnimation(.spring()) {
                                        hoveredPipelineID = hovering ? pipeline.id : nil
                                    }
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        pipelineToEdit = pipeline
                                        showingEditorSheet = true
                                    }
                                    Button("Delete", role: .destructive) {
                                        store.removePipelines(withIDs: [pipeline.id])
                                    }
                                }
                        }
                    }
                }
                .padding(30)
            }
            .searchable(text: $searchText, prompt: "Search Pipelines")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "pipe.and.drop")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Welcome to Plumber")
                .font(.largeTitle.bold())
            Text("Click the '+' button to build your first automation pipeline.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button(action: { showingEditorSheet = true }) {
                Label("Build Your First Pipeline", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top)
            Spacer()
        }
    }
}


// MARK: - Live Activity Drawer
struct LiveActivityDrawerView: View {
    @EnvironmentObject var eventLog: EventLogService
    @Binding var showActivityLog: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            
            if showActivityLog {
                content
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: showActivityLog ? 200 : 40)
        .background(.ultraThinMaterial)
        // --- FIX: Replaced the faulty UIKit code with the modern, correct SwiftUI modifier ---
        .clipShape(
            .rect(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16
            )
        )
        .shadow(radius: 10)
        .transition(.move(edge: .bottom))
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    private var header: some View {
        HStack {
            HStack {
                Image(systemName: "terminal.fill")
                Text("Live Activity")
                    .fontWeight(.bold)
            }
            Spacer()
            Image(systemName: "chevron.up")
                .rotationEffect(.degrees(showActivityLog ? 180 : 0))
        }
        .padding(.horizontal)
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showActivityLog.toggle()
            }
        }
    }
    
    private var content: some View {
        Group {
            Divider()
            if eventLog.events.isEmpty {
                ContentUnavailableView("No Recent Activity", systemImage: "clock.badge.xmark")
            } else {
                List(eventLog.events) { event in
                    LogEventRowView(event: event)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}


// MARK: - Redesigned Pipeline Card
struct PipelineCardView: View {
    @Binding var pipeline: Pipeline
    var isHovered: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(pipeline.name).font(.title3).fontWeight(.bold).lineLimit(1)
                    Text("Monitors \(pipeline.intakePaths.count) intake(s)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $pipeline.isEnabled).toggleStyle(.switch)
            }
            
            HStack {
                Image(systemName: "folder.fill.badge.plus")
                PipelineConnector(color: pipeline.color.toColor.opacity(pipeline.isEnabled ? 1 : 0.4))
                VStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("\(pipeline.valves.count) Valve(s)").font(.caption2)
                }
                PipelineConnector(color: pipeline.color.toColor.opacity(pipeline.isEnabled ? 1 : 0.4))
                Image(systemName: "archivebox.fill")
            }
            .font(.title2)
            .foregroundColor(pipeline.isEnabled ? .primary.opacity(0.8) : .secondary.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background.opacity(0.5))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isHovered ? 2 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}


// MARK: - Helper Views
struct LogEventRowView: View {
    let event: LogEvent
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: event.status.iconName).font(.body).foregroundColor(event.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.fileName).fontWeight(.bold).lineLimit(1)
                Text(event.message).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(event.timestamp, style: .time).font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
    }
}

struct PipelineConnector: View {
    let color: Color
    var body: some View {
        Rectangle()
            .frame(height: 4)
            .foregroundStyle(
                color.gradient.shadow(.inner(color: .black.opacity(0.3), radius: 1, y: 1))
            )
            .cornerRadius(2)
    }
}

// --- FIX: Removed the faulty UIKit-based RoundedCorner shape and View extension ---

