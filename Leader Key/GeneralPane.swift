import KeyboardShortcuts
import LaunchAtLogin
import Settings
import SwiftUI

struct GeneralPane: View {
  private let contentWidth = 600.0
  @EnvironmentObject private var config: UserConfig

  var body: some View {
    Settings.Container(contentWidth: contentWidth) {
      Settings.Section(title: "Config", bottomDivider: true, verticalAlignment: .top) {
        VStack(alignment: .leading) {
          ConfigEditorView(group: $config.root)
            .frame(height: 400)

          HStack {
            Button("Save") {
              config.saveConfig()
            }

            Button("Reveal in Finder") {
              NSWorkspace.shared.activateFileViewerSelecting([config.fileURL()])
            }
          }
        }
      }
      
      Settings.Section(title: "Shortcut") {
        KeyboardShortcuts.Recorder(for: .activate)
      }

      Settings.Section(title: "App") {
        LaunchAtLogin.Toggle()
      }
    }
  }
}

struct GeneralPane_Previews: PreviewProvider {
  static var previews: some View {
    let config = UserConfig()
    try? config.bootstrapConfig()
    
    return GeneralPane()
      .environmentObject(config)
  }
}
