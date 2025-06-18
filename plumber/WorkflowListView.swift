import SwiftUI

struct WorkflowListView: View {
    @EnvironmentObject var store: WorkflowStore
    @State private var selection: Set<Workflow.ID> = []
    
    @State private var isEditing: Bool = false
    
    @State private var showingEditorSheet = false
    @State private var workflowToEdit: Workflow?
    
    @State private var searchText: String = ""

    var body: some View {
        List(selection: $selection) {
            ForEach($store.workflows.filter {
                $searchText.wrappedValue.isEmpty ? true : $0.wrappedValue.name.localizedCaseInsensitiveContains($searchText.wrappedValue)
            }) { $workflow in
                // --- THIS IS THE FIX ---
                // We now check if the selection set contains this workflow's ID
                // and pass that simple true/false value to the row.
                WorkflowRowView(
                    workflow: $workflow,
                    isEditing: self.isEditing,
                    isSelected: self.selection.contains(workflow.id)
                )
                .tag(workflow.id)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .background(.clear)
                        .foregroundStyle(selection.contains(workflow.id) ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                        .padding(.vertical, 3)
                )
                .padding(.horizontal, 8)
            }
            .onMove(perform: { store.moveWorkflow(from: $0, to: $1) })
            .moveDisabled(!isEditing)
        }
        .listStyle(.plain)
        .navigationTitle("Workflows")
        .searchable(text: $searchText, prompt: "Search Workflows")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    self.workflowToEdit = nil
                    self.showingEditorSheet = true
                }) {
                    Image(systemName: "plus")
                }
                
                Button(action: { store.removeWorkflows(withIDs: selection) }) {
                    Image(systemName: "minus")
                }.disabled(selection.isEmpty)

                Button(action: editSelected) {
                    Image(systemName: "pencil")
                }.disabled(selection.count != 1)

                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditorSheet) {
            RuleEditorView(isSheetPresented: $showingEditorSheet, workflowToEdit: workflowToEdit)
                .environmentObject(store)
        }
    }
    
    private func editSelected() {
        if let selectedID = selection.first {
            self.workflowToEdit = store.workflows.first { $0.id == selectedID }
            self.showingEditorSheet = true
        }
    }
}


// --- THIS IS THE OTHER PART OF THE FIX ---
// The row view no longer uses the broken Environment key.
// It simply accepts a boolean value from its parent.
struct WorkflowRowView: View {
    @Binding var workflow: Workflow
    var isEditing: Bool
    var isSelected: Bool

    var body: some View {
        HStack {
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "arrow.right.square.fill")
                .font(.title2)
                .foregroundColor(workflow.color.toColor)
            
            Text(workflow.name)
                .fontWeight(.semibold)
            
            Spacer()
            
            Toggle("Enabled", isOn: $workflow.isEnabled)
                .labelsHidden()
        }
        // This logic now works because `isSelected` is a simple Bool.
        // Text becomes primary (readable) if the workflow is enabled OR if the row is selected.
        .foregroundStyle((workflow.isEnabled || isSelected) ? .primary : .secondary)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }
}
