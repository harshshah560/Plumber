import SwiftUI

struct RuleEditorView: View {
    @EnvironmentObject var store: WorkflowStore
    @Binding var isSheetPresented: Bool
    @StateObject private var viewModel: RuleEditorViewModel

    init(isSheetPresented: Binding<Bool>, workflowToEdit: Workflow? = nil) {
        self._isSheetPresented = isSheetPresented
        self._viewModel = StateObject(wrappedValue: RuleEditorViewModel(workflowToEdit: workflowToEdit))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Header
            HStack {
                Spacer()
                Text(viewModel.navigationTitle)
                    .font(.title3).fontWeight(.semibold)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button(action: { isSheetPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
            .padding()

            Divider()
            
            // MARK: - Main Content
            ScrollView {
                Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 24) {
                    GridRow(alignment: .center) {
                        Text("Name").gridColumnAlignment(.trailing)
                        TextField("e.g., Sort Vacation Photos", text: $viewModel.workflowName)
                            .textFieldStyle(CapsuleTextFieldStyle())
                    }

                    GridRow(alignment: .top) {
                        Text("Source(s)").gridColumnAlignment(.trailing)
                        // --- THIS IS THE FIX ---
                        // The incorrect '$' has been removed from addSourceFolders
                        SourceCapsulesView(
                            urls: $viewModel.sourceFolderURLs,
                            addAction: viewModel.addSourceFolder,
                            removeAction: viewModel.removeSource,
                            revealAction: viewModel.revealInFinder
                        )
                    }
                    
                    GridRow(alignment: .center) {
                        Text("Condition").gridColumnAlignment(.trailing)
                        Picker("", selection: $viewModel.conditionType) {
                            ForEach(RuleCondition.ConditionType.allCases) { type in Text(type.name).tag(type) }
                        }.pickerStyle(.menu)
                    }

                    GridRow(alignment: .center) {
                        Text(viewModel.conditionType.name).gridColumnAlignment(.trailing)
                        conditionInputView
                    }
                    
                    GridRow(alignment: .center) {
                        Text("Destination").gridColumnAlignment(.trailing)
                        DestinationCapsuleView(
                            url: viewModel.destinationURL,
                            chooseAction: viewModel.selectDestinationFolder,
                            revealAction: viewModel.revealInFinder
                        )
                    }
                }
                .padding(EdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20))
            }
            
            Divider()
            
            // MARK: - Footer
            HStack {
                Button("Save Workflow") {
                    if viewModel.save(to: store) {
                        isSheetPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.workflowName.isEmpty || viewModel.sourceFolderURLs.isEmpty)
            }
            .padding()
        }
        .frame(width: 550, height: 500)
        .background(.regularMaterial)
        .alert("Invalid Workflow", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {}
        } message: { Text(viewModel.errorMessage) }
    }
    
    @ViewBuilder
    private var conditionInputView: some View {
        switch viewModel.conditionType {
        case .kindIs:
            Picker("", selection: $viewModel.kindInputValue) {
                ForEach(Kind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }.pickerStyle(.menu).labelsHidden()
        default:
            TextField(viewModel.conditionType.placeholder, text: $viewModel.textInputValue)
                .textFieldStyle(CapsuleTextFieldStyle())
        }
    }
}


// MARK: - Helper Subviews

struct SourceCapsulesView: View {
    @Binding var urls: [URL]
    let addAction: () -> Void
    let removeAction: (URL) -> Void
    let revealAction: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(urls, id: \.self) { url in
                        DeletableCapsuleView(url: url, revealAction: revealAction, removeAction: removeAction)
                    }
                }
            }
            Button(action: addAction) {
                Label("Add Source Folder...", systemImage: "plus")
            }
        }
    }
}

struct DeletableCapsuleView: View {
    let url: URL
    let revealAction: (URL) -> Void
    let removeAction: (URL) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: { revealAction(url) }) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                    Text(url.lastPathComponent).truncationMode(.middle)
                }
            }
            .buttonStyle(.plain)
            
            Button(action: { removeAction(url) }) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(CircleButtonStyle())
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}

struct DestinationCapsuleView: View {
    let url: URL?
    let chooseAction: () -> Void
    let revealAction: (URL) -> Void
    
    var body: some View {
        Button(action: {
            if let url = url { revealAction(url) }
            else { chooseAction() }
        }) {
            HStack {
                Image(systemName: "folder.fill")
                Text(url?.lastPathComponent ?? "Choose Destination...").truncationMode(.middle)
                Spacer()
            }
        }
        .buttonStyle(CapsuleButtonStyle(isPlaceholder: url == nil))
    }
}

// MARK: - Helper Styles

struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background(Color.secondary.opacity(configuration.isPressed ? 0.3 : 0.15), in: Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct CapsuleButtonStyle: ButtonStyle {
    var isPlaceholder: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(.background)
            .foregroundStyle(isPlaceholder ? .secondary : .primary)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CapsuleTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(.background)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}
