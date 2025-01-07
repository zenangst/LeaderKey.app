import SwiftUI

struct AddButtons: View {
    let onAddAction: () -> Void
    let onAddGroup: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
          Button("Add Action", action: onAddAction)
            Button("Add Group", action: onAddGroup)
            Spacer()
        }
    }
}

struct ConfigEditorView: View {
    @Binding var group: Group
    var isRoot: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(group.actions.enumerated()), id: \.offset) { index, item in
                    ActionOrGroupRow(item: binding(for: index))
                }
                
                if isRoot {
                    Divider()
                        .padding(.vertical, 4)
                    
                    AddButtons(
                        onAddAction: { group.actions.append(.action(Action(key: "", type: .application, value: ""))) },
                        onAddGroup: { group.actions.append(.group(Group(key: "", actions: []))) }
                    )
                }
            }
            .padding(8)
        }
        .background(Color(.controlBackgroundColor))
    }
    
    private func binding(for index: Int) -> Binding<ActionOrGroup> {
        Binding(
            get: { group.actions[index] },
            set: { group.actions[index] = $0 }
        )
    }
}

struct ActionOrGroupRow: View {
    @Binding var item: ActionOrGroup
    
    var body: some View {
        switch item {
        case .action(_):
            ActionRow(action: actionBinding())
        case .group(_):
            GroupRow(group: groupBinding())
        }
    }
    
    private func actionBinding() -> Binding<Action> {
        Binding(
            get: {
                if case .action(let action) = item { return action }
                return Action(key: "", type: .application, value: "")
            },
            set: { item = .action($0) }
        )
    }
    
    private func groupBinding() -> Binding<Group> {
        Binding(
            get: {
                if case .group(let group) = item { return group }
                return Group(actions: [])
            },
            set: { item = .group($0) }
        )
    }
}

struct ActionRow: View {
    @Binding var action: Action
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Key", text: $action.key)
                .frame(width: 40)
                .textFieldStyle(.roundedBorder)
            
            Picker("Type", selection: $action.type) {
                Text("Application").tag(Type.application)
                Text("URL").tag(Type.url)
            }
            .frame(width: 110)
            .labelsHidden()
            
            TextField("Value", text: $action.value)
                .textFieldStyle(.roundedBorder)
            
            if action.type == .application {
                Button("Choose...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [.application]
                    
                    if panel.runModal() == .OK {
                        action.value = panel.url?.path ?? ""
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct GroupRow: View {
    @Binding var group: Group
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                
                TextField("Group Key", text: Binding(
                    get: { group.key ?? "" },
                    set: { group.key = $0 }
                ))
                .frame(width: 40)
                .textFieldStyle(.roundedBorder)
                
                AddButtons(
                    onAddAction: { group.actions.append(.action(Action(key: "", type: .application, value: ""))) },
                    onAddGroup: { group.actions.append(.group(Group(key: "", actions: []))) }
                )
            }
            
            if isExpanded {
                ConfigEditorView(group: $group, isRoot: false)
                    .padding(.leading, 20)
            }
        }
    }
}

#Preview {
    let group = Group(actions: [
        // Level 1 actions
        .action(Action(key: "t", type: .application, value: "/Applications/WezTerm.app")),
        .action(Action(key: "f", type: .application, value: "/Applications/Firefox.app")),
        
        // Level 1 group with actions
        .group(Group(key: "b", actions: [
            .action(Action(key: "c", type: .application, value: "/Applications/Google Chrome.app")),
            .action(Action(key: "s", type: .application, value: "/Applications/Safari.app"))
        ])),
        
        // Level 1 group with subgroups
        .group(Group(key: "r", actions: [
            .action(Action(key: "e", type: .url, value: "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols")),
            .group(Group(key: "w", actions: [
                .action(Action(key: "f", type: .url, value: "raycast://window-management/maximize")),
                .action(Action(key: "h", type: .url, value: "raycast://window-management/left-half"))
            ]))
        ]))
    ])
    
    return ConfigEditorView(group: .constant(group))
        .frame(width: 600, height: 500)
}
