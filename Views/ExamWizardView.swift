import SwiftUI

struct ExamWizardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var currentStep = 1
    @State private var profile = ExamProfile()
    
    // IA Chat State per Step 3
    @State private var aiInputText = ""
    @State private var aiChatLog: [(role: String, text: String)] = [
        ("ai", "Ciao! Dimmi, qual è l'argomento che ti spaventa di più di questo esame e come preferisci di solito studiare? (Es. schemi, flashcard, lettura ripetuta)")
    ]
    @State private var isGeneratingPlan = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header e Progress Bar
            VStack(alignment: .leading, spacing: 16) {
                Text("Wizard Nuovo Esame")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Palette.primaryText)
                
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { step in
                        Rectangle()
                            .fill(step <= currentStep ? Palette.growthAccent : Color.white.opacity(0.1))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
            }
            .padding(24)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch currentStep {
                    case 1:
                        step1View()
                    case 2:
                        step2View()
                    case 3:
                        step3View()
                    case 4:
                        step4View()
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Footer (Navigation Buttons)
            HStack {
                if currentStep > 1 {
                    Button("Indietro") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Palette.secondaryText)
                }
                
                Spacer()
                
                if currentStep < 4 {
                    Button(action: {
                        if currentStep == 3 {
                            generateAIPlan()
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }) {
                        Text(currentStep == 3 ? "Genera Piano con IA" : "Avanti")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Palette.growthAccent)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(currentStep == 1 && profile.subjectName.isEmpty)
                } else {
                    Button(action: {
                        // Salva e chiudi o vai alla Dashboard
                        // viewModel.saveExamProfile(profile)
                        withAnimation {
                            currentStep = 1
                            profile = ExamProfile()
                        }
                    }) {
                        Text("Salva Piano e Inizia")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Palette.growthAccent)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.2))
        }
    }
    
    // MARK: - Step 1: Dati Base
    @ViewBuilder
    private func step1View() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Inquadramento Materia")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("NOME MATERIA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.secondaryText)
                
                MacTextField(placeholder: "Es. Analisi Matematica II", text: $profile.subjectName, onSubmit: {})
                    .frame(height: 32)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("DATA ESAME")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.secondaryText)
                
                DatePicker("", selection: $profile.examDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("MODALITÀ ESAME")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.secondaryText)
                
                Picker("", selection: $profile.examType) {
                    ForEach(ExamType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    // MARK: - Step 2: UI Setup
    @ViewBuilder
    private func step2View() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Parametri di Carico")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.primaryText)
            
            Text("Imposta questi valori oggettivi affinché l'IA non sballi i calcoli temporali.")
                .font(.subheadline)
                .foregroundColor(Palette.secondaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ORE DI STUDIO AL GIORNO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.secondaryText)
                    Spacer()
                    Text(String(format: "%.1f h", profile.availableHoursPerDay))
                        .fontWeight(.bold)
                        .foregroundColor(Palette.growthAccent)
                }
                
                Slider(value: $profile.availableHoursPerDay, in: 1...12, step: 0.5)
                    .accentColor(Palette.growthAccent)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DURATA POMODORO (FOCUS)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.secondaryText)
                    Spacer()
                    Text("\(profile.preferredPomodoroDuration) min")
                        .fontWeight(.bold)
                        .foregroundColor(Palette.growthAccent)
                }
                
                Slider(value: Binding(
                    get: { Double(profile.preferredPomodoroDuration) },
                    set: { profile.preferredPomodoroDuration = Int($0) }
                ), in: 25...120, step: 5)
                .accentColor(Palette.growthAccent)
            }
        }
    }
    
    // MARK: - Step 3: Intervista Cognitiva
    @ViewBuilder
    private func step3View() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Intervista Diagnostica")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.primaryText)
            
            Text("Rispondi onestamente. Queste informazioni guideranno la creazione del prompt per cucirti un metodo di studio addosso.")
                .font(.subheadline)
                .foregroundColor(Palette.secondaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<aiChatLog.count, id: \.self) { index in
                    let chat = aiChatLog[index]
                    HStack {
                        if chat.role == "user" { Spacer() }
                        Text(chat.text)
                            .padding(12)
                            .background(chat.role == "ai" ? Color.white.opacity(0.05) : Palette.chartEnd)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        if chat.role == "ai" { Spacer() }
                    }
                }
            }
            .padding(.vertical)
            
            HStack {
                MacTextField(placeholder: "Rispondi all'IA...", text: $aiInputText, onSubmit: {
                    sendToAI()
                })
                .frame(height: 32)
                
                Button(action: { sendToAI() }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(aiInputText.isEmpty ? Palette.secondaryText : Palette.growthAccent)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(aiInputText.isEmpty)
            }
            .padding(12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
        }
    }
    
    private func sendToAI() {
        guard !aiInputText.isEmpty else { return }
        aiChatLog.append(("user", aiInputText))
        profile.cognitiveInterviewAnswers["Q\(aiChatLog.count)"] = aiInputText
        aiInputText = ""
        
        // Simula la risposta o manda a GeminiService
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            aiChatLog.append(("ai", "Ottimo. Considerando la modalità \(profile.examType.rawValue), quanta teoria pura c'è rispetto agli esercizi pratici?"))
        }
    }
    
    private func generateAIPlan() {
        isGeneratingPlan = true
        withAnimation { currentStep = 4 }
        
        // Simula la chiamata a Gemini per generare il piano finale
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            profile.aiGeneratedStrategy = """
            ### 🧠 Piano Strategico per \(profile.subjectName)
            
            **Analisi Profilo:**
            Hai \(profile.daysUntilExam) giorni a disposizione, per un totale di \(String(format: "%.0f", profile.totalEstimatedStudyHours)) ore.
            Il tuo carico ideale è strutturato su blocchi da \(profile.preferredPomodoroDuration) minuti.
            
            **Strategia (Ibrida):**
            1. **Fase 1 (Teoria Core - \(profile.daysUntilExam / 3) giorni):** Costruisci flashcard. Hai detto che preferisci questo metodo per memorizzare.
            2. **Fase 2 (Pratica Intensa - \(profile.daysUntilExam / 3) giorni):** Usa il blocco da \(profile.preferredPomodoroDuration) minuti solo per esercizi a valanga, vista la natura \(profile.examType.rawValue) dell'esame.
            3. **Fase 3 (Simulazione - Ultimi giorni):** Abbassa i blocchi a 25 min, simulando lo stress d'esame.
            """
            isGeneratingPlan = false
        }
    }
    
    // MARK: - Step 4: Output Finale
    @ViewBuilder
    private func step4View() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Il Tuo Piano Personalizzato")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.primaryText)
            
            if isGeneratingPlan {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Palette.growthAccent))
                    Text("Analisi dell'intervista cognitiva in corso...")
                        .foregroundColor(Palette.secondaryText)
                }
                .padding()
            } else if let strategy = profile.aiGeneratedStrategy {
                Text(strategy)
                    .foregroundColor(Palette.primaryText)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }
}
