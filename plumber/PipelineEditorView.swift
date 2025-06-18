// PipelineEditorView.swift (was RuleEditorView.swift)
import SwiftUI

struct PipelineEditorView: View {
    @EnvironmentObject var store: PipelineStore
    @Binding var isSheetPresented: Bool
    @StateObject private var viewModel: PipelineEditorViewModel

    init(isSheetPresented: Binding<Bool>, pipelineToEdit: Pipeline? = nil) {
        self._isSheetPresented = isSheetPresented
        self._viewModel = StateObject(wrappedValue: PipelineEditorViewModel(pipelineToEdit: pipelineToEdit))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { isSheetPresented = false }.keyboardShortcut(.cancelAction)
                Spacer()
                Text(viewModel.navigationTitle).font(.headline)
                Spacer()
                Button("Save") {
                    if viewModel.save(to: store) { isSheetPresented = false }
                }.keyboardShortcut(.defaultAction).disabled(viewModel.pipelineName.isEmpty)
            }.padding()

            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox("Pipeline Name") { TextField("e.g., Sort Project Files", text: $viewModel.pipelineName).textFieldStyle(.plain).labelsHidden() }
                    GroupBox("Intake Pipe(s)") { SourceCapsulesView(urls: $viewModel.intakeURLs, addAction: viewModel.addIntakePipe, removeAction: viewModel.removeIntakePipe, revealAction: viewModel.revealInFinder) }

                    GroupBox("Processing") {
                        Picker("Processing Mode", selection: $viewModel.processingMode) {
                            ForEach(ProcessingMode.allCases, id: \.self) { mode in Text(mode.rawValue).tag(mode) }
                        }.pickerStyle(.segmented).labelsHidden()
                        Text(viewModel.processingMode == .onNewFilesOnly ? "Only processes files added after this pipeline is enabled." : "Processes all existing files once, then monitors for new files.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
                    }

                    GroupBox("Valves (processed in order)") {
                        VStack(spacing: 16) {
                            ForEach($viewModel.valves) { $valve in
                                ValveView(valve: $valve) { viewModel.valves.removeAll { $0.id == valve.id } }
                            }
                        }
                        Button(action: viewModel.addValve) { Label("Add Valve", systemImage: "plus") }.frame(maxWidth: .infinity).padding(.top, 16)
                    }
                }.padding()
            }
        }
        .frame(width: 900, height: 600)
        .background(.regularMaterial)
        .alert("Invalid Pipeline", isPresented: $viewModel.showErrorAlert) { Button("OK") {} } message: { Text(viewModel.errorMessage) }
    }
}

struct ValveView: View {
    @Binding var valve: Valve
    var onDelete: () -> Void

    private var conditionTypeBinding: Binding<Condition.ConditionType> {
        Binding(
            get: { valve.condition.conditionType },
            set: { newType in
                switch newType {
                case .fileExtension: valve.condition = .fileExtensionsMatch([])
                case .nameContains: valve.condition = .nameContains("")
                case .nameBeginsWith: valve.condition = .nameBeginsWith("")
                case .nameEndsWith: valve.condition = .nameEndsWith("")
                case .kindIs: valve.condition = .kindIs(.image)
                case .dateAdded: valve.condition = .dateAdded(7)
                case .sizeIs: valve.condition = .sizeIs(5, .greaterThan)
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Valve Name", text: $valve.name).textFieldStyle(.plain).font(.headline)
                Spacer()
                Button(action: onDelete) { Image(systemName: "trash").foregroundColor(.secondary) }.buttonStyle(.plain)
            }
            Divider()
            Text("Condition").font(.subheadline).foregroundStyle(.secondary)
            Picker("Condition", selection: conditionTypeBinding) {
                ForEach(Condition.ConditionType.allCases) { type in Text(type.rawValue).tag(type) }
            }.pickerStyle(.segmented)
            ConditionInputView(condition: $valve.condition)
            Text("Actions").font(.subheadline).foregroundStyle(.secondary).padding(.top, 8)
            VStack {
                if valve.actions.isEmpty {
                    Text("No actions defined.").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 40)
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
                } label: { Label("Add Action", systemImage: "plus.circle.fill") }.frame(maxWidth: .infinity)
            }
        }
        .padding().background(Color(NSColor.controlBackgroundColor).opacity(0.5)).cornerRadius(10)
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
