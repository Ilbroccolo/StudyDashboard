import SwiftUI
import AppKit

struct MacTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var onSubmit: () -> Void
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var textBinding: Binding<String>
        var onSubmitClosure: () -> Void
        
        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            self.textBinding = text
            self.onSubmitClosure = onSubmit
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                self.textBinding.wrappedValue = textField.stringValue
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                self.onSubmitClosure()
                return true
            }
            return false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 14)
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
}
