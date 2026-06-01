import Foundation

enum ExamType: String, CaseIterable, Identifiable, Codable {
    case oral = "Orale"
    case written = "Scritto"
    case project = "Progetto"
    case multipleChoice = "Crocette"
    
    var id: String { self.rawValue }
}

struct ExamProfile: Identifiable, Codable {
    var id = UUID()
    
    // Step 1: Dati base
    var subjectName: String = ""
    var examDate: Date = Date().addingTimeInterval(86400 * 30) // Default: 30 days from now
    var examType: ExamType = .written
    
    // Step 2: Parametri di sistema (UI)
    var availableHoursPerDay: Double = 4.0
    var preferredPomodoroDuration: Int = 50 // In minutes
    var breakDuration: Int = 10 // In minutes
    
    // Step 3: Dati soggettivi (Raccolti tramite IA o Chat)
    var cognitiveInterviewAnswers: [String: String] = [:]
    
    // Output Finale: Generato dall'IA
    var aiGeneratedStrategy: String? = nil
    
    var daysUntilExam: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
    }
    
    var totalEstimatedStudyHours: Double {
        Double(daysUntilExam) * availableHoursPerDay
    }
}
