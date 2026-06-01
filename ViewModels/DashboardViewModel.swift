import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isChatEnabled: Bool = true
    
    @Published var selectedImagePath: String? = nil
    
    // Error tracking
    @Published var errorAnalyses: [ErrorAnalysis] = [] {
        didSet {
            StorageManager.shared.saveErrorAnalyses(errorAnalyses)
        }
    }
    
    @Published var rankSystem = RankSystem() {
        didSet {
            StorageManager.shared.saveXP(rankSystem.experiencePoints)
        }
    }
    
    // To-Do
    @Published var currentToDos: [ToDoItem] = []
    @Published var completedExercises: [ToDoItem] = [] {
        didSet {
            StorageManager.shared.saveCompletedExercises(completedExercises)
        }
    }
    
    // Storico Sessioni
    @Published var sessionHistory: [StudySessionHistory] = []
    
    // Global Tracker Anti-AFK
    @Published var unverifiedStudySeconds: Int = 0 {
        didSet {
            StorageManager.shared.saveUnverifiedSeconds(unverifiedStudySeconds)
        }
    }
    @Published var showAFKPopup: Bool = false
    @Published var isGlobalTimerRunning: Bool = true
    
    private var globalAppTimer: AnyCancellable?
    private var afkTimeoutTimer: AnyCancellable?
    private let afkCheckInterval = 25 * 60 // 25 minuti
    private let afkTimeoutLimit = 3 * 60 // 3 minuti di tolleranza
    private var currentTimeoutSeconds = 0
    
    func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            selectedImagePath = panel.url?.path
        }
    }
    
    // Pomodoro
    @Published var timeRemaining: Int = 50 * 60
    @Published var isTimerRunning: Bool = false
    @Published var isBreakTime: Bool = false
    
    private var timer: AnyCancellable?
    
    func setCustomTimer(minutes: Int) {
        // Solo se il timer non sta girando, per evitare bug strani
        if !isTimerRunning {
            self.timeRemaining = minutes * 60
            self.totalPomodoroTime = minutes * 60
        }
    }
    
    func clearErrorReports() {
        self.errorAnalyses.removeAll()
    }
    
    // Vigilante Agent
    @Published var lastInteractionTime: Date = Date()
    private var vigilanteTimer: AnyCancellable?
    
    init() {
        // Carica dati persistenti
        let savedXP = StorageManager.shared.loadXP()
        self.rankSystem.experiencePoints = savedXP
        self.unverifiedStudySeconds = StorageManager.shared.loadUnverifiedSeconds()
        
        self.errorAnalyses = StorageManager.shared.loadErrorAnalyses()
        self.completedExercises = StorageManager.shared.loadCompletedExercises()
        
        if let savedBlocks = StorageManager.shared.loadSchedule() {
            self.dailyBlocks = savedBlocks
        } else {
            generateDefaultSchedule()
        }
        
        checkTimeAndSetContext()
        // Setup timer to check time periodically
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkTimeAndSetContext()
        }
        
        // Setup Vigilante Timer (controlla ogni minuto)
        vigilanteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.checkVigilanteStatus()
        }
        
        sendInitialGreeting()
        setupMockHistory()
        setupGlobalTimer()
    }
    
    // MARK: - Global Tracker Anti-AFK
    private func setupGlobalTimer() {
        globalAppTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            
            if self.isGlobalTimerRunning {
                self.unverifiedStudySeconds += 1
                
                // Se raggiungiamo l'intervallo e non c'è già il popup, lo mostriamo
                if self.unverifiedStudySeconds > 0 && self.unverifiedStudySeconds % self.afkCheckInterval == 0 && !self.showAFKPopup {
                    self.triggerAFKPopup()
                }
            }
        }
    }
    
    private func triggerAFKPopup() {
        self.showAFKPopup = true
        VoiceService.shared.speak("Ehi, sei ancora lì a studiare?")
        self.currentTimeoutSeconds = 0
        
        // Avvia il countdown del timeout
        afkTimeoutTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.currentTimeoutSeconds += 1
            
            if self.currentTimeoutSeconds >= self.afkTimeoutLimit {
                self.handleAFKTimeout()
            }
        }
    }
    
    func confirmStillStudying() {
        self.showAFKPopup = false
        self.afkTimeoutTimer?.cancel()
        self.afkTimeoutTimer = nil
        self.isGlobalTimerRunning = true // Assicurati che sia in esecuzione
        
        // Converti i secondi in XP (es. 1 min = 1 XP) e resetta
        let earnedXP = self.unverifiedStudySeconds / 60
        if earnedXP > 0 {
            self.rankSystem.experiencePoints += earnedXP
            
            // Aggiungiamo una entry anonima fittizia se superiamo le 2 ore? O semplicemente diamo gli XP?
            // Visto che è un Global Tracker, aggiungiamo XP e basta al profilo.
        }
        self.unverifiedStudySeconds = 0
    }
    
    private func handleAFKTimeout() {
        self.showAFKPopup = false
        self.afkTimeoutTimer?.cancel()
        self.afkTimeoutTimer = nil
        
        // Blocca il timer
        self.isGlobalTimerRunning = false
        VoiceService.shared.speak("Timer bloccato. Sembra che tu ti sia allontanato.")
        
        // Resetta i secondi non verificati punitivi
        self.unverifiedStudySeconds = 0
    }
    
    // Riprendi dal blocco
    func resumeGlobalTimer() {
        self.isGlobalTimerRunning = true
    }
    
    private func setupMockHistory() {
        if sessionHistory.isEmpty {
            // Aggiungi la sessione di OGGI (6 ore = 2 preimpostate + 4 di programmazione/chat assieme)
            sessionHistory.append(StudySessionHistory(id: UUID(), date: Date(), durationMinutes: 360, xpEarned: 600, aiGeneratedName: nil))
            
            // Crea 3 fittizie per gli ultimi 3 giorni
            for i in 1...3 {
                let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                sessionHistory.append(StudySessionHistory(id: UUID(), date: date, durationMinutes: 240, xpEarned: 400, aiGeneratedName: nil))
            }
            generateNamesForHistory()
        }
    }
    
    private func generateNamesForHistory() {
        Task {
            let gemini = GeminiService()
            for i in 0..<sessionHistory.count {
                if sessionHistory[i].aiGeneratedName == nil {
                    do {
                        let name = try await gemini.generateSessionName(durationMinutes: sessionHistory[i].durationMinutes, xp: sessionHistory[i].xpEarned)
                        DispatchQueue.main.async {
                            self.sessionHistory[i].aiGeneratedName = name
                        }
                    } catch {
                        print("Errore IA generazione nome: \(error)")
                        DispatchQueue.main.async {
                            self.sessionHistory[i].aiGeneratedName = "Sessione Standard"
                        }
                    }
                }
            }
        }
    }
    
    private func checkVigilanteStatus() {
        // Se non stiamo facendo un Pomodoro o se siamo in pausa, non disturbare
        guard isTimerRunning && !isBreakTime else { return }
        
        let elapsedSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        
        // 12 minuti = 720 secondi
        if elapsedSinceLastInteraction > 720 {
            // Evita di spammare se c'è già l'ultimo messaggio del vigilante
            if let lastMsg = messages.last, lastMsg.text.contains("vedo che sei fermo") {
                return
            }
            
            let vigilanteMessage = ChatMessage(text: "Joseph, vedo che sei fermo da 12 minuti. Su quale passaggio sei bloccato? Usa gli appunti o dimmi cosa non ti torna.", role: .system)
            messages.append(vigilanteMessage)
            VoiceService.shared.speak("Joseph, vedo che sei fermo da un po'. Tutto ok?")
            lastInteractionTime = Date() // Reset per non ripetere subito
        }
    }
    
    @Published var dailyBlocks: [TimeBlock] = [] {
        didSet {
            StorageManager.shared.saveSchedule(dailyBlocks)
        }
    }
    @Published var currentBlockIndex: Int? = nil
    
    func checkTimeAndSetContext() {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let currentTimeValue = hour * 60 + minute
        
        // Bedtime check (23:30)
        if hour == 23 && minute >= 30 || hour < 5 {
            // Avviso per andare a dormire, ma la chat rimane abilitata
            addSystemMessage("È ora di spegnere lo schermo per abbassare l'adrenalina. Il recupero fa parte dell'allenamento. Vai a letto.")
        }
        
        isChatEnabled = true
        
        // Determina il blocco corrente
        currentBlockIndex = nil
        for (index, block) in dailyBlocks.enumerated() {
            let startParts = block.startTime.split(separator: ":").compactMap { Int($0) }
            let endParts = block.endTime.split(separator: ":").compactMap { Int($0) }
            
            if startParts.count == 2, endParts.count == 2 {
                let startValue = startParts[0] * 60 + startParts[1]
                let endValue = endParts[0] * 60 + endParts[1]
                
                if currentTimeValue >= startValue && currentTimeValue < endValue {
                    currentBlockIndex = index
                    break
                }
            }
        }
    }
    
    func generateDefaultSchedule() {
        var blocks: [TimeBlock] = [
            TimeBlock(startTime: "08:30", endTime: "10:00", activity: "Risveglio e Pianificazione Giornata"),
            TimeBlock(startTime: "10:00", endTime: "13:00", activity: "Studio Intenso: Analisi e Matematica"),
            TimeBlock(startTime: "13:00", endTime: "14:00", activity: "Pranzo e Pausa Leggera"),
            TimeBlock(startTime: "14:00", endTime: "17:00", activity: "Studio: Laboratorio I e Programmazione C"),
            TimeBlock(startTime: "17:00", endTime: "18:00", activity: "Revisione, Esercizi o Sessione Extra"),
            TimeBlock(startTime: "18:00", endTime: "19:30", activity: "Palestra / Attività Fisica"),
            TimeBlock(startTime: "19:30", endTime: "20:30", activity: "Cena"),
            TimeBlock(startTime: "20:30", endTime: "22:30", activity: "Relax, Lettura o Side Project"),
            TimeBlock(startTime: "22:30", endTime: "23:00", activity: "Preparazione Sonno")
        ]
        self.dailyBlocks = blocks
        self.checkTimeAndSetContext()
    }
    
    func showMasterLimits() {
        let masterText = """
        # 🔥 Sessione Master: Il Boss Finale di Taylor
        
        Ecco i 5 limiti livello Esame progettati per te:
        
        ### Esercizio 1: L'Inganno del Coseno
        $$ \\lim_{x \\to 0} \\frac{\\ln(1 + x \\sin x) - x^2}{\\cos(x^2) - 1} $$
        
        ### Esercizio 2: Esponenziali e Radici
        $$ \\lim_{x \\to 0} \\frac{e^{x^2} - \\sqrt{1 + 2x^2}}{x^4} $$
        
        ### Esercizio 3: Grado +1
        $$ \\lim_{x \\to 0} \\frac{\\sin(\\ln(1+x)) - x + \\frac{x^2}{2}}{x^3} $$
        
        ### Esercizio 4: Taylor vs De L'Hôpital
        $$ \\lim_{x \\to 0} \\frac{\\arctan(x) - \\sin(x)}{x^2 \\ln(1+x)} $$
        
        ### Esercizio 5: Il Mix Letale
        $$ \\lim_{x \\to 0} \\frac{1 - \\cos(x \\sqrt{2}) + \\ln(1 - x^2)}{x^4} $$
        
        Risolvili su carta, poi dimmi i passaggi qui e li valutiamo assieme!
        """
        
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(text: masterText, role: .ai))
        }
    }
    
    // Messaggio iniziale per evitare la chat vuota
    private func sendInitialGreeting() {
        if messages.isEmpty {
            let greeting = ChatMessage(text: "Inizializzazione completata. Sono l'Agente Gemini. Tutti i sistemi sono online e la persistenza è attiva. Come posso aiutarti oggi?", role: .system)
            messages.append(greeting)
            VoiceService.shared.speak("Sistemi online. Benvenuto Joseph.")
        }
    }
    
    func updateCurrentToDos() {
        if dailyBlocks.isEmpty { generateDefaultSchedule() }
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTimeString = formatter.string(from: date)
        
        var foundBlock: TimeBlock?
        for block in dailyBlocks {
            if currentTimeString >= block.startTime && currentTimeString < block.endTime {
                foundBlock = block
                break
            }
        }
        
        if let block = foundBlock {
            currentToDos = [ToDoItem(text: block.activity, isShifted: block.isShifted ?? false, isLocked: !isChatEnabled)]
        } else {
            currentToDos = [ToDoItem(text: "Attività fuori orario", isLocked: !isChatEnabled)]
        }
    }
    
    func shiftSchedule(imprevisto: String) async {
        do {
            let blocksDescriptions = dailyBlocks.map { "\($0.startTime)-\($0.endTime): \($0.activity)" }.joined(separator: ", ")
            let prompt = "Ho questo imprevisto: '\(imprevisto)'. Modifica e riorganizza il seguente calendario spostando gli orari: \(blocksDescriptions)."
            let newBlocks = try await geminiService.generateSchedule(userRequest: prompt)
            DispatchQueue.main.async {
                self.dailyBlocks = newBlocks
                self.checkTimeAndSetContext()
            }
        } catch {
            print("Errore shift schedule: \(error)")
        }
    }
    
    func completeTask(_ item: ToDoItem) {
        if let index = currentToDos.firstIndex(where: { $0.id == item.id }) {
            withAnimation {
                var completedItem = currentToDos.remove(at: index)
                completedItem.isCompleted = true
                completedExercises.insert(completedItem, at: 0)
            }
        }
    }
    
    // Gamification
    @Published var exerciseStartTime: Date? = nil
    
    let geminiService = GeminiService()
    let ollamaService = OllamaService()
    
    @Published var pendingAnalyses: [PendingAnalysis] = []

    func startExercise() {
        exerciseStartTime = Date()
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty, isChatEnabled else { return }
        
        // Calcolo punteggio se l'esercizio era in corso
        var timeMessage = ""
        if let startTime = exerciseStartTime {
            let elapsedMinutes = Int(Date().timeIntervalSince(startTime) / 60)
            if elapsedMinutes > 10 {
                rankSystem.experiencePoints -= 10
                timeMessage = " (Tempo: \(elapsedMinutes)m - Troppo lento, -10 XP)"
            } else {
                rankSystem.experiencePoints += 15
                timeMessage = " (Tempo: \(elapsedMinutes)m - Ottimo, +15 XP)"
            }
            exerciseStartTime = nil // Reset timer
        }
        
        // Resetta il Vigilante Agent
        lastInteractionTime = Date()
        
        let userMsg = ChatMessage(text: inputText + timeMessage, role: .user, imagePath: selectedImagePath)
        messages.append(userMsg)
        
        let sentText = inputText
        let imageToProcess = selectedImagePath
        
        inputText = ""
        selectedImagePath = nil
        
        // Aggiungiamo un messaggio "in caricamento"
        let loadingMsg = ChatMessage(text: "...", role: .ai)
        messages.append(loadingMsg)
        
        Task {
            do {
                // Agente Calendario (Pianificazione)
                if sentText.lowercased().contains("pianifica") || sentText.lowercased().contains("calendario") || sentText.lowercased().contains("giornata") {
                    let newBlocks = try await geminiService.generateSchedule(userRequest: sentText)
                    await MainActor.run {
                        self.messages.removeAll(where: { $0.id == loadingMsg.id })
                        self.dailyBlocks = newBlocks
                        self.checkTimeAndSetContext()
                        self.messages.append(ChatMessage(text: "Ho aggiornato il tuo calendario per oggi e l'ho salvato. Guarda il tracker a destra.", role: .system))
                        VoiceService.shared.speak("Calendario aggiornato.")
                    }
                    return
                }
                
                // 1. Chiamata a Gemini API (Tutor Normale) con Memoria (ultimi 6 messaggi)
                let recentHistory = Array(self.messages.dropLast(2).suffix(6))
                let aiResponseText = try await geminiService.generateResponse(userMessage: sentText, history: recentHistory, imagePath: imageToProcess)
                
                await MainActor.run {
                    self.messages.removeAll(where: { $0.id == loadingMsg.id })
                    self.messages.append(ChatMessage(text: aiResponseText, role: .ai))
                    VoiceService.shared.speak(aiResponseText) // Feedback vocale
                    if imageToProcess != nil {
                        self.messages.append(ChatMessage(text: "Ho analizzato l'immagine allegata.", role: .system))
                    }
                    
                    // 2. Chiamata a Ollama API in background (analisi JSON) gratuita e locale
                    if sentText.contains("limite") || sentText.contains("taylor") || sentText.contains("integrale") || sentText.contains("C") || sentText.contains("malloc") || sentText.contains("pointer") || sentText.contains("array") {
                        
                        let backgroundTutorResponse = aiResponseText
                        
                        Task.detached {
                            do {
                                if let errorAnalysis = try await self.ollamaService.analyzeError(userMessage: sentText, tutorResponse: backgroundTutorResponse) {
                                    await MainActor.run {
                                        if !self.errorAnalyses.contains(where: { $0.category == errorAnalysis.category }) {
                                            self.errorAnalyses.append(errorAnalysis)
                                            VoiceService.shared.speak("Analisi profonda completata da Ollama. Ho aggiornato la scheda.")
                                        }
                                        if errorAnalysis.severity.lowercased() == "alta" {
                                            self.rankSystem.experiencePoints -= 5
                                        }
                                    }
                                }
                                await self.processPendingAnalyses()
                            } catch {
                                print("Ollama non disponibile, salvo in coda pending.")
                                let pending = PendingAnalysis(userMessage: sentText, tutorResponse: backgroundTutorResponse, timestamp: Date())
                                await MainActor.run {
                                    self.pendingAnalyses.append(pending)
                                }
                            }
                        }
                    }
                }
                

            } catch {
                await MainActor.run {
                    self.messages.removeAll(where: { $0.id == loadingMsg.id })
                    if let urlError = error as? URLError, urlError.code == .userAuthenticationRequired {
                        self.messages.append(ChatMessage(text: "⚠️ ERRORE CRITICO: La chiave API di Gemini è mancante o invalida in Secrets.swift! Inserisci la tua API Key per attivare l'intelligenza artificiale.", role: .system))
                    } else {
                        self.messages.append(ChatMessage(text: "Errore API Gemini: \(error.localizedDescription)", role: .system))
                    }
                }
            }
        }
    }
    // Resilienza: processa in background se torna online
    func processPendingAnalyses() async {
        guard !pendingAnalyses.isEmpty else { return }
        
        var remaining: [PendingAnalysis] = []
        for pending in pendingAnalyses {
            do {
                if let errorAnalysis = try await ollamaService.analyzeError(userMessage: pending.userMessage, tutorResponse: pending.tutorResponse) {
                    await MainActor.run {
                        if !self.errorAnalyses.contains(where: { $0.category == errorAnalysis.category }) {
                            self.errorAnalyses.append(errorAnalysis)
                        }
                    }
                }
            } catch {
                remaining.append(pending)
            }
        }
        await MainActor.run {
            self.pendingAnalyses = remaining
        }
    }
    
    private func addSystemMessage(_ text: String) {
        if !messages.contains(where: { $0.text == text && $0.role == .system }) {
            messages.append(ChatMessage(text: text, role: .system))
        }
    }
    
    // Pomodoro Logic
    func toggleTimer() {
        if isTimerRunning {
            timer?.cancel()
            isTimerRunning = false
        } else {
            isTimerRunning = true
            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.cancel()
                    self.isTimerRunning = false
                    self.isBreakTime.toggle()
                    self.timeRemaining = self.isBreakTime ? 10 * 60 : 50 * 60
                    self.totalPomodoroTime = self.timeRemaining
                    self.toggleTimer() // Auto-start next phase
                }
            }
        }
    }
    
    @Published var totalPomodoroTime: Int = 50 * 60
    
    @Published var showWellnessCheck = false
    private var wellnessTimer: Timer?
    private var dismissWellnessTimer: Timer?

    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func addFiveMinutes() {
        timeRemaining += 5 * 60
        totalPomodoroTime += 5 * 60
    }
    
    func startWellnessCheck() {
        // Ogni 30 minuti avvia il check di benessere
        wellnessTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.triggerWellnessCheck()
            }
        }
    }
    
    private func triggerWellnessCheck() {
        showWellnessCheck = true
        // Scompare da solo dopo 10 secondi se l'utente non risponde
        dismissWellnessTimer?.invalidate()
        dismissWellnessTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showWellnessCheck = false
            }
        }
    }
    
    func dismissWellness() {
        dismissWellnessTimer?.invalidate()
        showWellnessCheck = false
    }
}
