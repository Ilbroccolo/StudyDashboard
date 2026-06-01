import SwiftUI
import SwiftUIMath

struct ChatColumn: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var voiceService = VoiceService.shared
    @State private var isInputFocused: Bool = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sala Studio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Palette.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        voiceService.isVoiceEnabled.toggle()
                        if !voiceService.isVoiceEnabled {
                            voiceService.stop()
                        }
                    }) {
                        Image(systemName: voiceService.isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(voiceService.isVoiceEnabled ? Palette.growthAccent : Palette.secondaryText)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text("Motore di Ragionamento con Focus Mode")
                    .font(.subheadline)
                    .foregroundColor(Palette.secondaryText)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
            .padding(.top, 8)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Timer dell'Esercizio (Visibile se in corso)
            if let startTime = viewModel.exerciseStartTime {
                let currentElapsed = Int(Date().timeIntervalSince(startTime) / 60)
                HStack {
                    Text("⏱️ Esercizio in corso: \(currentElapsed) min")
                        .font(.caption)
                        .foregroundColor(currentElapsed > 10 ? Palette.chartCritical : Palette.growthAccent)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal, 8)
            } else {
                HStack {
                    Button(action: {
                        viewModel.startExercise()
                    }) {
                        Text("🚀 Inizia Esercizio")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Palette.growthAccent)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            
            // Input Area
            VStack(spacing: 0) {
                if let imagePath = viewModel.selectedImagePath, let nsImage = NSImage(contentsOfFile: imagePath) {
                    HStack {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .cornerRadius(8)
                        
                        Button(action: {
                            viewModel.selectedImagePath = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Palette.chartCritical)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.selectImage()
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20))
                            .foregroundColor(Palette.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    MacTextField(placeholder: "Scrivi messaggio...", text: $viewModel.inputText, onSubmit: {
                        viewModel.sendMessage()
                    })
                    .frame(height: 24)
                    
                    Button(action: {
                        viewModel.sendMessage()
                        isInputFocused = true
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.inputText.isEmpty && viewModel.selectedImagePath == nil ? Palette.secondaryText : Palette.growthAccent)
                    }
                    .disabled(viewModel.inputText.isEmpty && viewModel.selectedImagePath == nil)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(24)
                .onTapGesture {
                    isInputFocused = true
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isInputFocused ? Palette.growthAccent : Color.white.opacity(0.1), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isInputFocused = true
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if let path = message.imagePath, let nsImage = NSImage(contentsOfFile: path) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
                
                if !message.text.isEmpty {
                    if message.role == .ai {
                        advancedParsedText()
                            .padding(.vertical, 8)
                    } else {
                        Text(message.text)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Palette.chartEnd)
                            .cornerRadius(16)
                    }
                }
            }
            .frame(maxWidth: message.role == .ai ? .infinity : 400, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role != .user { Spacer() }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func advancedParsedText() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let blocks = message.text.components(separatedBy: "$$")
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                if index % 2 == 1 {
                    // Multi-line Math Block
                    Math(block.trimmingCharacters(in: .whitespacesAndNewlines))
                        .mathTypesettingStyle(.display)
                        .foregroundColor(Palette.primaryText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
                } else {
                    // Normal text
                    let lines = block.components(separatedBy: "\n")
                    ForEach(Array(lines.enumerated()), id: \.offset) { lIndex, line in
                        if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                            parseNormalLine(line)
                        }
                    }
                }
            }
        }
    }
    
    func parseNormalLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("### ") {
            return AnyView(Text(trimmed.dropFirst(4)).font(.headline).foregroundColor(Palette.primaryText).bold())
        } else if trimmed.hasPrefix("## ") {
            return AnyView(Text(trimmed.dropFirst(3)).font(.title3).foregroundColor(Palette.primaryText).bold())
        } else if trimmed.hasPrefix("# ") {
            return AnyView(Text(trimmed.dropFirst(2)).font(.title2).foregroundColor(Palette.primaryText).bold())
        } else {
            return AnyView(parseInline(line))
        }
    }
    
    func parseInline(_ line: String) -> Text {
        let normalizedLine = line.replacingOccurrences(of: "\\)", with: "\\(")
        let parts = normalizedLine.components(separatedBy: "\\(")
        var result = Text("")
        for (i, part) in parts.enumerated() {
            if i % 2 == 1 { // Inline Math
                result = result + Text(" \(part) ").foregroundColor(Palette.growthAccent).font(.system(.body, design: .monospaced))
            } else {
                let boldParts = part.components(separatedBy: "**")
                for (j, bPart) in boldParts.enumerated() {
                    if j % 2 == 1 { // Bold
                        result = result + Text(bPart).bold().foregroundColor(Palette.primaryText)
                    } else { // Code inline
                        let codeParts = bPart.components(separatedBy: "`")
                        for (k, cPart) in codeParts.enumerated() {
                            if k % 2 == 1 {
                                result = result + Text(cPart).foregroundColor(Palette.secondaryText).font(.system(.body, design: .monospaced))
                            } else {
                                result = result + Text(cPart).foregroundColor(Palette.primaryText)
                            }
                        }
                    }
                }
            }
        }
        return result
    }
}
