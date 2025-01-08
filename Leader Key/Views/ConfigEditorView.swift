import SwiftUI

let PADDING: CGFloat = 8

struct AddButtons: View {
  let onAddAction: () -> Void
  let onAddGroup: () -> Void

  var body: some View {
    HStack(spacing: PADDING) {
      Button(action: onAddAction) {
        Image(systemName: "rays")
        Text("Add action")
      }
      Button(action: onAddGroup) {
        Image(systemName: "folder")
        Text("Add group")
      }
      Spacer()
    }
  }
}

struct GroupContentView: View {
  @Binding var group: Group
  var isRoot: Bool = false

  var body: some View {
    VStack(spacing: PADDING) {
      ForEach(Array(group.actions.enumerated()), id: \.offset) {
        index, item in
        ActionOrGroupRow(
          item: binding(for: index),
          onDelete: { group.actions.remove(at: index) }
        )
      }

      VStack {
        AddButtons(
          onAddAction: {
            group.actions.append(
              .action(Action(key: "", type: .application, value: "")))
          },
          onAddGroup: {
            group.actions.append(.group(Group(key: "", actions: [])))
          }
        )
      }.padding(.top, PADDING * 0.5)
    }
  }

  private func binding(for index: Int) -> Binding<ActionOrGroup> {
    Binding(
      get: { group.actions[index] },
      set: { group.actions[index] = $0 }
    )
  }
}

struct ConfigEditorView: View {
  @Binding var group: Group
  var isRoot: Bool = true

  var body: some View {
    ScrollView {
      GroupContentView(group: $group, isRoot: isRoot)
        .padding(.init(top: PADDING, leading: PADDING, bottom: PADDING, trailing: 0))
    }
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
    HStack(spacing: PADDING) {
      TextField("Key", text: $action.key)
        .frame(width: 32)
        .textFieldStyle(.roundedBorder)

      Picker("Type", selection: $action.type) {
        Text("Application").tag(Type.application)
        Text("URL").tag(Type.url)
        Text("Command").tag(Type.command)
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

      Button(role: .destructive, action: onDelete) {
        Image(systemName: "trash")
      }
      .padding(.trailing, PADDING)
    }
  }
}

struct GroupRow: View {
  @Binding var group: Group
  @State private var isExpanded = true
  let onDelete: () -> Void

  var body: some View {
    VStack(spacing: PADDING) {
      HStack(spacing: PADDING) {
        TextField(
          "Group Key",
          text: Binding(
            get: { group.key ?? "" },
            set: { group.key = $0 }
          )
        )
        .frame(width: 32)
        .textFieldStyle(.roundedBorder)

        Image(systemName: "chevron.right")
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .onTapGesture {
            withAnimation(.easeOut(duration: 0.1)) {
              isExpanded.toggle()
            }
          }
          .padding(.leading, PADDING / 3)

        Spacer(minLength: 0)

        Button(role: .destructive, action: onDelete) {
          Image(systemName: "trash")
        }
        .padding(.trailing, PADDING)
      }

      if isExpanded {
        HStack(spacing: 0) {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1)
            .padding(.leading, PADDING)
            .padding(.trailing, PADDING / 3)

          GroupContentView(group: $group)
            .padding(.leading, PADDING)
        }
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
