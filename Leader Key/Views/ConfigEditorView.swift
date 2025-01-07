import SwiftUI

struct AddButtons: View {
  let onAddAction: () -> Void
  let onAddGroup: () -> Void

  var body: some View {
    HStack(spacing: 8) {
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
        ForEach(Array(group.actions.enumerated()), id: \.offset) {
          index, item in
          ActionOrGroupRow(
            item: binding(for: index),
            onDelete: { group.actions.remove(at: index) }
          )
        }

        if isRoot {
          Divider()

          AddButtons(
            onAddAction: {
              group.actions.append(
                .action(Action(key: "", type: .application, value: "")))
            },
            onAddGroup: {
              group.actions.append(.group(Group(key: "", actions: [])))
            }
          )
        }
      }
    }
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
  let onDelete: () -> Void

  var body: some View {
    switch item {
    case .action(_):
      ActionRow(action: actionBinding(), onDelete: onDelete)
    case .group(_):
      GroupRow(group: groupBinding(), onDelete: onDelete)
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
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      TextField("Key", text: $action.key)
        .frame(width: 32)
        .textFieldStyle(.roundedBorder)

      Picker("Type", selection: $action.type) {
        Text("Application").tag(Type.application)
        Text("URL").tag(Type.url)
      }
      .frame(width: 110)
      .labelsHidden()

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

      TextField("Value", text: $action.value)

      Spacer(minLength: 0)

      Button(action: onDelete) {
        Image(systemName: "trash")
          .foregroundColor(.red)
      }
      .controlSize(.small)
        .buttonStyle(.borderless)
    }
  }
}

struct GroupRow: View {
  @Binding var group: Group
  @State private var isExpanded = true
  let onDelete: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        TextField(
          "Group Key",
          text: Binding(
            get: { group.key ?? "" },
            set: { group.key = $0 }
          )
        )
        .frame(width: 32)
        .textFieldStyle(.roundedBorder)

        Picker("Type", selection: $group.type) {
          Text("Group").tag(Type.group)
        }
        .frame(width: 110)
        .labelsHidden()
        .disabled(true)
        
        Spacer(minLength: 2)

        Image(systemName: "chevron.right")
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .onTapGesture {
            withAnimation(.easeOut(duration: 0.1)) {
              isExpanded.toggle()
            }
          }
        Spacer(minLength: 2)

        AddButtons(
          onAddAction: {
            group.actions.append(
              .action(Action(key: "", type: .application, value: "")))
          },
          onAddGroup: {
            group.actions.append(.group(Group(key: "", actions: [])))
          }
        )

        Spacer(minLength: 0)

        Button(action: onDelete) {
          Image(systemName: "trash")
            .foregroundColor(.red)
        }
        .controlSize(.small)
          .buttonStyle(.borderless)
      }

      if isExpanded {
        ConfigEditorView(group: $group, isRoot: false)
          .padding(.leading, 23)
      }
    }
    .padding(.horizontal, 0)
  }
}

#Preview {
  let group = Group(actions: [
    // Level 1 actions
    .action(
      Action(key: "t", type: .application, value: "/Applications/WezTerm.app")),
    .action(
      Action(key: "f", type: .application, value: "/Applications/Firefox.app")),

    // Level 1 group with actions
    .group(
      Group(
        key: "b",
        actions: [
          .action(
            Action(
              key: "c", type: .application,
              value: "/Applications/Google Chrome.app")),
          .action(
            Action(
              key: "s", type: .application, value: "/Applications/Safari.app")),
        ])),

    // Level 1 group with subgroups
    .group(
      Group(
        key: "r",
        actions: [
          .action(
            Action(
              key: "e", type: .url,
              value:
                "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"
            )),
          .group(
            Group(
              key: "w",
              actions: [
                .action(
                  Action(
                    key: "f", type: .url,
                    value: "raycast://window-management/maximize")),
                .action(
                  Action(
                    key: "h", type: .url,
                    value: "raycast://window-management/left-half")),
              ])),
        ])),
  ])

  return ConfigEditorView(group: .constant(group))
    .frame(width: 600, height: 500)
}
