import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: PipelineStore
    @EnvironmentObject var eventLog: EventLogService
    @State private var selection: Pipeline.ID?
    @State private var showingEditorSheet = false
    @State private var pipelineToEdit: Pipeline?
    
    var body: some View {
        // --- FIX: Replaced HSplitView with a robust HStack and Divider ---
        HStack(spacing: 0) {
            pipelineList
                .frame(maxWidth: .infinity)
            
            Divider()
            
            liveActivityFeed
                .frame(maxWidth: .infinity)
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { pipelineToEdit = nil; showingEditorSheet = true }) {
                    Label("Build Pipeline", systemImage: "plus")
                }
                Button(action: {
                    if let selectedID = selection {
                        store.removePipelines(withIDs: [selectedID]); selection = nil
                    }
                }) {
                    Label("Delete Pipeline", systemImage: "trash")
                }.disabled(selection == nil)
            }
        }
        .sheet(isPresented: $showingEditorSheet) {
            PipelineEditorView(isSheetPresented: $showingEditorSheet, pipelineToEdit: pipelineToEdit)
                .environmentObject(store)
        }
    }

    private var pipelineList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pipelines")
                .font(.title2).bold()
                .padding([.leading, .top])
                .padding(.bottom, 8)
            
            Divider()

            Group {
                if store.pipelines.isEmpty {
                    // --- FIX: This view is now correctly centered ---
                    VStack {
                        Spacer()
                        ContentUnavailableView("No Pipelines", systemImage: "pipe.and.drop", description: Text("Tap '+' to build a new pipeline."))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach($store.pipelines) { $pipeline in
                                PipelineRowView(pipeline: $pipeline, isSelected: selection == pipeline.id)
                                    .onTapGesture { selection = (selection == pipeline.id) ? nil : pipeline.id }
                                    .contextMenu {
                                        Button("Edit Pipeline") { pipelineToEdit = pipeline; showingEditorSheet = true }
                                        Button("Delete Pipeline", role: .destructive) {
                                            store.removePipelines(withIDs: [pipeline.id]); selection = nil
                                        }
                                    }
                            }
                        }.padding()
                    }
                }
            }
        }
    }

    private var liveActivityFeed: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Live Activity").font(.title2).bold().padding()
            Divider()
            List {
                if eventLog.events.isEmpty {
                    Text("No file events yet. Add a file to a monitored Intake Pipe to see activity here.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(eventLog.events) { event in
                        HStack(alignment: .top) {
                            Image(systemName: event.status.iconName)
                                .foregroundColor(event.status.color)
                                .font(.body.weight(.medium))
                                .padding(.top, 2)
                            VStack(alignment: .leading) {
                                Text(event.fileName).fontWeight(.bold)
                                Text(event.message).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(event.timestamp, style: .time).font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                }
            }.listStyle(.plain)
        }
    }
}

struct PipelineRowView: View {
    @Binding var pipeline: Pipeline
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(pipeline.name).font(.headline).fontWeight(.bold)
                    Text("Monitors \(pipeline.intakePaths.count) intake pipe(s)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $pipeline.isEnabled).labelsHidden()
            }
            
            HStack(spacing: 0) {
                PipelineComponent(title: "Intake", icon: "folder.fill")
                PipelineConnector(color: pipeline.color.toColor)
                PipelineComponent(title: "Valves", icon: "wrench.and.screwdriver.fill")
                PipelineConnector(color: pipeline.color.toColor)
                let destinationName = destinationName(for: pipeline)
                PipelineComponent(title: destinationName, icon: "archivebox.fill")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
    }
    
    private func destinationName(for pipeline: Pipeline) -> String {
        guard let firstValve = pipeline.valves.first,
              let moveAction = firstValve.actions.first(where: { $0.type == .moveToFolder }),
              let path = moveAction.parameters["path"], !path.isEmpty else {
            return "Outflow"
        }
        return URL(fileURLWithPath: path).lastPathComponent
    }
}

struct PipelineComponent: View {
    let title: String, icon: String, value: String? = nil
    var body: some View {
        VStack {
            Image(systemName: icon).font(.title2).foregroundStyle(.secondary).frame(height: 25)
            Text(title).font(.caption).lineLimit(1).truncationMode(.middle)
            if let value = value { Text(value).font(.caption2).fontWeight(.bold).foregroundStyle(.secondary) }
        }.frame(width: 80)
    }
}

struct PipelineConnector: View {
    let color: Color
    var body: some View {
        Rectangle().frame(height: 4).foregroundStyle(color.opacity(0.5))
    }
}
