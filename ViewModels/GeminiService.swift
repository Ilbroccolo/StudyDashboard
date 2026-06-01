import Foundation
import AppKit

class GeminiService {
    
    // Risposta JSON di Gemini v1beta
    struct GeminiResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String
                }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }
    
    // L'endpoint deve usare l'ultimo modello (Maggio 2026)
    let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent"
    
    let systemPrompt = """
    Sei un Tutor di Analisi Matematica (focus Analisi 1).
    Il tuo obiettivo è guidare lo studente (che ha come target 19.5 punti) facendolo ragionare.
    REGOLE FONDAMENTALI:
    1. NON dare MAI la soluzione completa.
    2. Dai solo un "hint" (suggerimento) mirato.
    3. Fai particolare attenzione ai 5 Quesiti Tattici del Master Plan:
       - Quesito 1 (Taylor): Sviluppo algebrico puro per x -> 0, focus sul grado dell'o-piccolo.
       - Quesito 2 (Asintoti): Limiti agli estremi e ricerca di m e q.
       - Quesito 4 (Funzioni Integrali): Teorema Fondamentale del Calcolo e derivate.
       - Quesito 5 (Integrali Impropri): Confronto asintotico, parametro alpha.
       - Quesito 7 (Successioni): Gerarchia infiniti e Criterio del Rapporto.
       - Jolly (Limiti 2D): Restrizioni su y=mx.
    4. Sii breve e conciso.
    """
    
    func generateResponse(userMessage: String, history: [ChatMessage] = [], imagePath: String? = nil) async throws -> String {
        guard !Secrets.geminiApiKey.isEmpty else {
            return "Errore: Inserisci la tua API Key in Secrets.swift"
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiApiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var finalPrompt = systemPrompt
        
        // Costruzione del contesto storico
        if !history.isEmpty {
            finalPrompt += "\n\n[CONTESTO PRECEDENTE]\nEcco gli ultimi messaggi per darti il contesto della conversazione:\n"
            for msg in history {
                let roleStr = (msg.role == .user) ? "Studente" : "Tu (Tutor)"
                finalPrompt += "- \(roleStr): \(msg.text)\n"
            }
            finalPrompt += "[FINE CONTESTO PRECEDENTE]\n"
        }
        
        // Agente Ispettore C (Heuristica)
        if userMessage.contains("#include") || userMessage.contains("int main") || userMessage.contains("malloc") {
            finalPrompt += """
            
            [MODALITÀ ISPETTORE CODICE C ATTIVA]
            L'utente ha inviato codice C. Analizza severamente:
            1. Memory leaks (assenza di free).
            2. Complessità asintotica (Big-O di tempo e spazio).
            3. Errori sui puntatori.
            Tagga la risposta con [⚠️ LEAK], [⚡ O(N)], o [✅ SAFE].
            """
        }
        
        let promptText = "\(finalPrompt)\n\nNuovo messaggio dello studente: \(userMessage)"
        
        var parts: [[String: Any]] = [
            ["text": promptText]
        ]
        
        // Aggiungo l'immagine se presente
        if let path = imagePath, let image = NSImage(contentsOfFile: path), let tiffData = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData), let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {
            let base64Image = jpegData.base64EncodedString()
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": base64Image
                ]
            ])
        }
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                return "Ops! Abbiamo superato il limite di token gratuiti per minuto di Gemini (Errore 429). Fai una pausa di 30 secondi e riproviamo!"
            }
            if let errorText = String(data: data, encoding: .utf8) {
                print("Gemini API Error: \(errorText)")
                return "ERRORE API GEMINI: \(errorText)"
            }
            return "Errore nella comunicazione con l'IA."
        }
        
        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return result.candidates.first?.content.parts.first?.text ?? "Errore nel parsing della risposta di Gemini."
    }
        
    func generateSchedule(userRequest: String) async throws -> [TimeBlock] {
        guard !Secrets.geminiApiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiApiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let schedulePrompt = """
        Sei un Agente di Pianificazione. L'utente vuole aggiornare il suo calendario di studio/vita.
        Restituisci ESCLUSIVAMENTE un JSON array valido che rappresenta il nuovo calendario.
        Ogni oggetto deve avere:
        "startTime": "HH:MM",
        "endTime": "HH:MM",
        "activity": "Descrizione"
        
        Nessun testo, solo JSON puro, in formato array [ {...}, {...} ].
        Richiesta utente: \(userRequest)
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": schedulePrompt]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let rawText = result.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotDecodeRawData)
        }
        
        // Estrazione Regex sicura dell'array JSON
        let pattern = "\\[.*\\]"
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let nsString = rawText as NSString
        let results = regex.matches(in: rawText, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let cleanedJson = nsString.substring(with: match.range)
        
        guard let decodedData = cleanedJson.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let blocks = try JSONDecoder().decode([TimeBlock].self, from: decodedData)
        return blocks
    }
    
    // MARK: - Agente Ispettore C / Errori
    func analyzeCodeError(userMessage: String, tutorResponse: String) async throws -> [ErrorAnalysis] {
        guard !Secrets.geminiApiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiApiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let analysisPrompt = """
        Sei un Agente Ispettore C e Analista di Codice.
        L'utente ha chiesto: '\(userMessage)'
        Il Tutor ha risposto: '\(tutorResponse)'
        
        Analizza la conversazione per trovare eventuali concetti mancanti, memory leak, errori di complessità (O(N)) o semplici incomprensioni matematiche.
        Restituisci ESCLUSIVAMENTE un JSON array valido.
        Ogni oggetto deve avere:
        "category": "Titolo categoria (es. Memory Leak, Syntax, Limite di Taylor)",
        "specificIssue": "Dettaglio dell'errore",
        "severity": "Alta", "Media" o "Bassa",
        "progress": un numero decimale da 0.0 a 1.0 (es. 0.4 se sta migliorando, 0.1 se è bloccato),
        "frequency": "Elevata", "Moderata" o "Rara"
        
        Nessun testo, solo JSON puro in formato array.
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": analysisPrompt]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let rawText = result.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotDecodeRawData)
        }
        
        let pattern = "\\[.*\\]"
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let nsString = rawText as NSString
        let results = regex.matches(in: rawText, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let cleanedJson = nsString.substring(with: match.range)
        
        guard let decodedData = cleanedJson.data(using: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let analyses = try JSONDecoder().decode([ErrorAnalysis].self, from: decodedData)
        return analyses
    }
    
    // Generatore Titoli Sessione per la Dashboard
    func generateSessionName(durationMinutes: Int, xp: Int) async throws -> String {
        guard !Secrets.geminiApiKey.isEmpty else {
            return "Sessione Epica (Offline)"
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiApiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let promptText = """
        Sei un IA che dà titoli epici, nerd e motivazionali alle sessioni di studio.
        L'utente ha appena completato una sessione di \(durationMinutes) minuti, guadagnando \(xp) XP.
        Genera UN SOLO titolo (massimo 4 parole) senza spiegazioni, senza virgolette.
        Esempi: "Maratona di Derivate", "Speedrun dei Limiti", "Grind Asintotico", "Dominio Assoluto".
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return "Sessione Indomabile"
        }
        
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let text = decoded.candidates.first?.content.parts.first?.text {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Sessione Misteriosa"
    }
}
