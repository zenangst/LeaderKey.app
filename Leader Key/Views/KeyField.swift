import SwiftUI

struct KeyField: View {
  @Binding var text: String
  let placeholder: String
  @FocusState private var isFocused: Bool

  var body: some View {
    TextField(placeholder, text: $text)
      .frame(width: 32)
      .textFieldStyle(.roundedBorder)
      .multilineTextAlignment(.center)
      .onChange(of: text) { newValue in
        if newValue.count > 1 {
          text = String(newValue.suffix(1))
        }
      }
      .focused($isFocused)
      .onChange(of: isFocused) { focused in
        if focused {
          DispatchQueue.main.async {
            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSText.selectAll(_:)), with: nil)
          }
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidChangeNotification)) { _ in
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSText.selectAll(_:)), with: nil)
      }
  }
}

#Preview {
  struct Container: View {
    @State var text = "a"
    
    var body: some View {
      VStack(spacing: 20) {
        KeyField(text: $text, placeholder: "Key")
        Text("Current value: '\(text)'")
      }
      .padding()
    }
  }
  
  return Container()
} 