import Foundation

enum MessageRole {
    case user
    case ai
    case system
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let role: MessageRole
    var imagePath: String? = nil
}

struct ErrorAnalysis: Codable, Identifiable {
    var id: String { category }
    let category: String
    let specificIssue: String
    let severity: String // "Alta", "Media", "Bassa"
    let progress: Double // da 0.0 a 1.0
    let frequency: String // es. "Elevata", "Moderata", "Rara"
}

struct PendingAnalysis: Codable, Identifiable {
    let id = UUID()
    let userMessage: String
    let tutorResponse: String
    let timestamp: Date
}

struct ToDoItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    var isCompleted: Bool = false
    var isShifted: Bool = false
    var isLocked: Bool = false
}

struct TimeBlock: Codable, Identifiable, Equatable {
    var id = UUID()
    let startTime: String // es. "10:00"
    let endTime: String // es. "13:00"
    let activity: String
    var isShifted: Bool? = false
    
    private enum CodingKeys: String, CodingKey {
        case startTime, endTime, activity, isShifted
    }
}

struct RankSystem {
    var experiencePoints: Int = 0
    
    var currentLevel: String {
        switch experiencePoints {
        case ..<0: return "Studente Nabbo"
        case 0..<50: return "Studente Nabbo"
        case 50..<150: return "Analista Junior"
        case 150..<300: return "Cacciatore di Limiti"
        case 300...: return "Dio dell'Hôpital"
        default: return "Studente Nabbo"
        }
    }
    
    var nextLevelThreshold: Int {
        switch experiencePoints {
        case ..<50: return 50
        case 50..<150: return 150
        case 150..<300: return 300
        case 300...: return 9999
        default: return 50
        }
    }
    
    var progress: Double {
        let currentThreshold = currentBaseThreshold()
        let range = Double(nextLevelThreshold - currentThreshold)
        let currentXp = Double(experiencePoints - currentThreshold)
        return range > 0 ? max(0, min(1, currentXp / range)) : 1.0
    }
    
    private func currentBaseThreshold() -> Int {
        switch experiencePoints {
        case ..<50: return 0
        case 50..<150: return 50
        case 150..<300: return 150
        case 300...: return 300
        default: return 0
        }
    }
}

struct StudySessionHistory: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let durationMinutes: Int
    let xpEarned: Int
    var aiGeneratedName: String?
}
