import SwiftUI

// MARK: - Main Editor View
struct PipelineEditorView: View {
    @EnvironmentObject var store: PipelineStore
    @Binding var isSheetPresented: Bool
    
    @StateObject private var viewModel: PipelineEditorViewModel
    @State private var selection: Int = 0
    
    init(isSheetPresented: Binding<Bool>, pipelineToEdit: Pipeline? = nil) {
        self._isSheetPresented = isSheetPresented
        self._viewModel = StateObject(wrappedValue: PipelineEditorViewModel(pipelineToEdit: pipelineToEdit))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.navigationTitle)
                .font(.title.bold())
                .padding()
            
            HStack(spacing: 0) {
                StepView(step: 0, title: "Basics", icon: "1.circle.fill", selection: $selection)
                StepConnector(isActive: selection >= 1)
                StepView(step: 1, title: "Valves", icon: "2.circle.fill", selection: $selection)
                StepConnector(isActive: selection >= 2)
                StepView(step: 2, title: "Finish", icon: "3.circle.fill", selection: $selection)
            }
            .padding(.horizontal)
            
            Group {
                switch selection {
                case 0: BasicsPageView(viewModel: viewModel)
                case 1: ValvesPageView(viewModel: viewModel)
                case 2: FinishPageView(viewModel: viewModel)
                default: Text("Error")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // --- FIX: Improved button layout and consistency ---
            HStack {
                Button("Cancel", role: .cancel) { isSheetPresented = false }
                
                Spacer()
                
                if selection > 0 {
                    Button("Back") { withAnimation { selection -= 1 } }
                }
                
                if selection < 2 {
                    Button("Next") { withAnimation { selection += 1 } }
                        .disabled(!isCurrentStepValid())
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Save Pipeline") {
                        if viewModel.save(to: store) { isSheetPresented = false }
                    }
                    .disabled(!isCurrentStepValid())
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .background(.bar) // Adaptive background for light/dark mode
        }
        .frame(width: 800, height: 600)
        .alert("Invalid Pipeline", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {}
        } message: { Text(viewModel.errorMessage) }
    }
    
    private func isCurrentStepValid() -> Bool {
        switch selection {
        case 0: return !viewModel.pipelineName.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.intakeURLs.isEmpty
        case 1: return !viewModel.valves.isEmpty && !viewModel.valves.flatMap(\.actions).isEmpty
        default: return true
        }
    }
}

// MARK: - Editor Pages

private struct BasicsPageView: View {
    @ObservedObject var viewModel: PipelineEditorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox("What is this pipeline called?") {
                    TextField("e.g., Sort Project Invoices", text: $viewModel.pipelineName)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                
                GroupBox("Which folders should be monitored? (Intake Pipes)") {
                    SourceCapsulesView(
                        urls: $viewModel.intakeURLs,
                        addAction: viewModel.addIntakePipe,
                        removeAction: viewModel.removeIntakePipe,
                        revealAction: viewModel.revealInFinder
                    )
                }
            }
            .padding(30)
        }
    }
}

private struct ValvesPageView: View {
    @ObservedObject var viewModel: PipelineEditorViewModel

    var body: some View {
        VStack {
            if viewModel.valves.isEmpty {
                 ContentUnavailableView {
                    Label("No Valves", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("Valves define the logic of your pipeline.\nAdd a valve to set conditions and actions.")
                } actions: {
                    Button("Add Your First Valve") { viewModel.addValve() }
                }
            } else {
                 ScrollView {
                    VStack(spacing: 16) {
                        ForEach($viewModel.valves) { $valve in
                            ValveView(valve: $valve) {
                                viewModel.valves.removeAll { $0.id == valve.id }
                            }
                        }
                    }.padding(.vertical, 30).padding(.horizontal, 20)
                }
            }
            Button(action: viewModel.addValve) {
                Label("Add Another Valve", systemImage: "plus")
            }
            .padding(.bottom, 20)
        }
    }
}

private struct FinishPageView: View {
    @ObservedObject var viewModel: PipelineEditorViewModel

    var body: some View {
        VStack(spacing: 30) {
            GroupBox("How should this pipeline process files?") {
                Picker("Processing Mode", selection: $viewModel.processingMode) {
                    ForEach(ProcessingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(viewModel.processingMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            
            GroupBox("Summary") {
                VStack(alignment: .leading, spacing: 12) {
                    SummaryRow(label: "Pipeline Name", value: viewModel.pipelineName)
                    SummaryRow(label: "Intake Pipes", value: "\(viewModel.intakeURLs.count) folder(s)")
                    SummaryRow(label: "Valves", value: "\(viewModel.valves.count) valve(s)")
                    let actionCount = viewModel.valves.flatMap { $0.actions }.count
                    SummaryRow(label: "Actions", value: "\(actionCount) action(s)")
                }
            }
        }
        .padding(30)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Core Components (Included from original file)

// --- FIX: Included ValveView and all its dependencies ---
struct ValveView: View {
    @Binding var valve: Valve
    var onDelete: () -> Void

    private var conditionTypeBinding: Binding<Condition.ConditionType> {
        Binding(
            get: { valve.condition.conditionType },
            set: { newType in
                // When condition type changes, reset to a default state for that type
                switch newType {
                case .fileExtension: valve.condition = .fileExtensionsMatch([])
                case .nameContains: valve.condition = .nameContains("")
                case .nameBeginsWith: valve.condition = .nameBeginsWith("Screenshot ") // Smart default
                case .nameEndsWith: valve.condition = .nameEndsWith("")
                case .kindIs: valve.condition = .kindIs(.image)
                case .dateAdded: valve.condition = .dateAdded(7)
                case .sizeIs: valve.condition = .sizeIs(5, .greaterThan)
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("Valve Name", text: $valve.name)
                    .textFieldStyle(.plain)
                    .font(.headline)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }
            
            // "IF" Condition Block
            VStack(alignment: .leading, spacing: 8) {
                Text("IF").font(.headline).foregroundColor(.accentColor)
                Picker("Condition", selection: conditionTypeBinding) {
                    ForEach(Condition.ConditionType.allCases) { type in Text(type.rawValue).tag(type) }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)
                
                ConditionInputView(condition: $valve.condition)
            }
            .padding()
            .background(Color.accentColor.opacity(0.05))
            .cornerRadius(8)

            // "THEN" Actions Block
            VStack(alignment: .leading, spacing: 8) {
                Text("THEN").font(.headline).foregroundColor(.green)
                if valve.actions.isEmpty {
                    Text("No actions defined. Click '+' to add one.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .center)
                } else {
                    ForEach($valve.actions) { $action in
                        ActionRowView(action: $action) { valve.actions.removeAll { $0.id == action.id } }
                        if action.id != valve.actions.last?.id { Divider() }
                    }
                }
                
                Menu {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Button(type.rawValue) { valve.actions.append(ActionStep(type: type)) }
                    }
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ConditionInputView: View {
    @Binding var condition: Condition
    var body: some View {
        switch condition {
        case .fileExtensionsMatch(let extensions):
            TextField("e.g., jpg, png", text: Binding(get: { extensions.joined(separator: ", ") }, set: { condition = .fileExtensionsMatch($0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }) })).textFieldStyle(RoundedBorderTextFieldStyle())
        case .nameContains(let text):
            TextField("e.g., invoice", text: Binding(get: { text }, set: { condition = .nameContains($0) })).textFieldStyle(RoundedBorderTextFieldStyle())
        case .nameBeginsWith(let text):
            TextField("e.g., IMG_", text: Binding(get: { text }, set: { condition = .nameBeginsWith($0) })).textFieldStyle(RoundedBorderTextFieldStyle())
        case .nameEndsWith(let text):
            TextField("e.g., _final", text: Binding(get: { text }, set: { condition = .nameEndsWith($0) })).textFieldStyle(RoundedBorderTextFieldStyle())
        case .kindIs(let kind):
            Picker("Kind is", selection: Binding(get: { kind }, set: { condition = .kindIs($0) })) {
                ForEach(Kind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }.labelsHidden()
        case .dateAdded(let days):
            HStack { Text("In the last"); TextField("7", value: Binding(get: { days }, set: { condition = .dateAdded($0) }), formatter: NumberFormatter()).frame(width: 50); Text("days") }
        case .sizeIs(let size, let comparison):
            HStack {
                Picker("Comparison", selection: Binding(get: { comparison }, set: { condition = .sizeIs(size, $0) })) {
                    ForEach(Condition.Comparison.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.labelsHidden()
                TextField("5", value: Binding(get: { size }, set: { condition = .sizeIs($0, comparison) }), formatter: NumberFormatter()); Text("MB")
            }
        }
    }
}

struct ActionRowView: View {
    @Binding var action: ActionStep
    var onDelete: () -> Void
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(action.type.rawValue).fontWeight(.semibold)
                switch action.type {
                case .moveToFolder, .copyToFolder:
                    DestinationPicker(path: Binding(get: { action.parameters["path", default: ""] }, set: { action.parameters["path"] = $0 }))
                case .rename:
                    TextField("e.g., Photo-{date}.{ext}", text: Binding(get: { action.parameters["pattern", default: ""] }, set: { action.parameters["pattern"] = $0 })).textFieldStyle(RoundedBorderTextFieldStyle())
                case .addTag:
                    TextField("e.g., Important, Vacation", text: Binding(get: { action.parameters["tags", default: ""] }, set: { action.parameters["tags"] = $0 })).textFieldStyle(RoundedBorderTextFieldStyle())
                case .runShellScript:
                    TextEditor(text: Binding(get: { action.parameters["script", default: ""] }, set: { action.parameters["script"] = $0 })).font(.system(.body, design: .monospaced)).frame(height: 80).border(Color(NSColor.separatorColor), width: 1).padding(.top, 4)
                    Text("Use {filepath}, {filename}, {ext}, {parent}, {date}").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: onDelete) { Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(.gray.opacity(0.8)) }.buttonStyle(.plain)
        }.padding(.vertical, 4)
    }
}


// MARK: - UI Helpers

// --- FIX: Included SourceCapsulesView and all its dependencies ---
struct DestinationPicker: View {
    @Binding var path: String
    var body: some View {
        Button(action: {
            let openPanel = NSOpenPanel(); openPanel.prompt = "Choose Outflow Pipe"; openPanel.canChooseDirectories = true; openPanel.canCreateDirectories = true; openPanel.allowsMultipleSelection = false; openPanel.canChooseFiles = false
            if openPanel.runModal() == .OK, let url = openPanel.url {
                self.path = url.path
                FolderAccessManager.saveBookmark(for: url)
            }
        }) {
            HStack {
                Image(systemName: "folder.fill")
                Text(path.isEmpty ? "Choose Outflow Pipe..." : URL(fileURLWithPath: path).lastPathComponent)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold))
            }
            .foregroundColor(path.isEmpty ? .secondary : .primary).padding(.horizontal, 10).padding(.vertical, 8).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

struct SourceCapsulesView: View {
    @Binding var urls: [URL]
    let addAction: () -> Void, removeAction: (URL) -> Void, revealAction: (URL) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if urls.isEmpty {
                Text("No intake pipes selected.").foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(urls, id: \.self) { url in DeletableCapsuleView(url: url, revealAction: revealAction, removeAction: removeAction) } }
                }
            }
            Divider().padding(.vertical, 4)
            Button(action: addAction) { Label("Add Intake Pipe...", systemImage: "plus") }.frame(maxWidth: .infinity)
        }
    }
}

struct DeletableCapsuleView: View {
    let url: URL, revealAction: (URL) -> Void, removeAction: (URL) -> Void
    var body: some View {
        HStack(spacing: 4) {
            Button(action: { revealAction(url) }) {
                HStack(spacing: 4) { Image(systemName: "folder.fill"); Text(url.lastPathComponent).lineLimit(1).truncationMode(.middle) }
            }.buttonStyle(.plain)
            Button(action: { removeAction(url) }) {
                Image(systemName: "xmark").font(.caption.weight(.bold)).padding(4).background(Color.secondary.opacity(0.15), in: Circle())
            }.buttonStyle(.plain).contentShape(Circle())
        }
        .padding(.leading, 8).padding(.trailing, 4).padding(.vertical, 5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}

private struct StepView: View {
    let step: Int
    let title: String
    let icon: String
    @Binding var selection: Int
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(selection >= step ? .accentColor : .secondary)
                .symbolEffect(.bounce.down, value: selection == step)
            Text(title)
                .font(.headline)
                .foregroundColor(selection >= step ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StepConnector: View {
    let isActive: Bool
    var body: some View {
        Rectangle()
            .frame(height: 4)
            .cornerRadius(2)
            .foregroundColor(isActive ? .accentColor : Color(NSColor.separatorColor))
            .padding(.bottom)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}

private struct TopBorder: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// Extend ProcessingMode to have user-friendly descriptions
extension ProcessingMode {
    var description: String {
        switch self {
        case .onNewFilesOnly:
            return "Only processes files added to an intake folder after this pipeline is enabled."
        case .onAllExistingAndNewFiles:
            return "Processes all existing files once, then continues to monitor for new files."
        }
    }
}
