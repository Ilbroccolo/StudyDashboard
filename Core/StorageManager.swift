import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let defaults = UserDefaults.standard
    
    // Keys
    private let xpKey = "com.antigravity.experiencePoints.v2"
    private let scheduleKey = "com.antigravity.dailyBlocks.v2"
    private let scheduleDateKey = "com.antigravity.scheduleDate.v2"
    private let completedExercisesKey = "com.antigravity.completedExercises.v2"
    private let unverifiedSecondsKey = "com.antigravity.unverifiedSeconds.v2"
    private let errorAnalysesKey = "com.antigravity.errorAnalyses.v2"
    
    private init() {}
    
    // MARK: - Experience Points (Rank)
    func saveXP(_ xp: Int) {
        defaults.set(xp, forKey: xpKey)
    }
    
    func loadXP() -> Int {
        return defaults.integer(forKey: xpKey) // Returns 0 if not found
    }
    
    // MARK: - Schedule (TimeBlocks)
    func saveSchedule(_ blocks: [TimeBlock]) {
        if let encoded = try? JSONEncoder().encode(blocks) {
            defaults.set(encoded, forKey: scheduleKey)
            defaults.set(Date(), forKey: scheduleDateKey)
        }
    }
    
    func loadSchedule() -> [TimeBlock]? {
        // Only load if the saved schedule is from today
        if let savedDate = defaults.object(forKey: scheduleDateKey) as? Date {
            if !Calendar.current.isDateInToday(savedDate) {
                return nil
            }
        } else {
            // No date means it's an old save, let's regenerate to be safe
            return nil
        }
        
        if let savedData = defaults.data(forKey: scheduleKey),
           let decoded = try? JSONDecoder().decode([TimeBlock].self, from: savedData) {
            return decoded
        }
        return nil
    }
    
    // MARK: - Completed Exercises (ToDoItem)
    func saveCompletedExercises(_ exercises: [ToDoItem]) {
        if let encoded = try? JSONEncoder().encode(exercises) {
            defaults.set(encoded, forKey: completedExercisesKey)
        }
    }
    
    func loadCompletedExercises() -> [ToDoItem] {
        if let savedData = defaults.data(forKey: completedExercisesKey),
           let decoded = try? JSONDecoder().decode([ToDoItem].self, from: savedData) {
            return decoded
        }
        return []
    }
    
    // MARK: - Tracker Anti-AFK
    func saveUnverifiedSeconds(_ seconds: Int) {
        defaults.set(seconds, forKey: unverifiedSecondsKey)
    }
    
    func loadUnverifiedSeconds() -> Int {
        return defaults.integer(forKey: unverifiedSecondsKey)
    }
    
    // MARK: - Error Analyses (Ollama)
    func saveErrorAnalyses(_ errors: [ErrorAnalysis]) {
        if let encoded = try? JSONEncoder().encode(errors) {
            defaults.set(encoded, forKey: errorAnalysesKey)
        }
    }
    
    func loadErrorAnalyses() -> [ErrorAnalysis] {
        if let savedData = defaults.data(forKey: errorAnalysesKey),
           let decoded = try? JSONDecoder().decode([ErrorAnalysis].self, from: savedData) {
            return decoded
        }
        return []
    }
}
