import Foundation

class OllamaService {
    
    // Default endpoint for Ollama local API
    let endpoint = "http://localhost:11434/api/generate"
    
    // Modify this if you downloaded a different model (e.g. mistral)
    let model = "llama3" 
    
    let systemPrompt = """
    Sei un Analista Dati invisibile integrato in un'app di studio.
    Il tuo compito è leggere lo storico tra uno Studente e un Tutor di Matematica e restituire in output ESCLUSIVAMENTE un JSON valido, senza testo discorsivo.
    Devi classificare l'errore commesso dallo studente all'interno di ESATTAMENTE UNA di queste 6 categorie:
    - "Taylor"
    - "Asintoti"
    - "Funzioni Integrali"
    - "Integrali Impropri"
    - "Successioni"
    - "Limiti 2D"
    
    Se non rientra in queste o non c'è errore, restituisci {"category": "Nessuno", "specificIssue": "Nessun errore rilevato", "severity": "Bassa", "progress": 1.0, "frequency": "Rara"}.
    
    Il JSON deve avere questa esatta struttura:
    {
      "category": "Una delle categorie sopra citate",
      "specificIssue": "Breve descrizione del problema",
      "severity": "Alta, Media o Bassa",
      "progress": 0.3, // un decimale tra 0.0 e 1.0
      "frequency": "Elevata, Moderata o Rara"
    }
    """
    
    func analyzeError(userMessage: String, tutorResponse: String) async throws -> ErrorAnalysis? {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let promptText = "\(systemPrompt)\n\n--- STORICO ---\nStudente: \(userMessage)\nTutor: \(tutorResponse)\n\nRestituisci SOLO IL JSON."
        
        let body: [String: Any] = [
            "model": model,
            "prompt": promptText,
            "format": "json", // Forziamo Ollama a rispondere in JSON (richiede Ollama >= 0.1.29)
            "stream": false
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct OllamaResponse: Decodable {
            let response: String
        }
        
        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
        let jsonString = result.response
        
        // Decodifichiamo la stringa JSON in ErrorAnalysis
        if let dataFromString = jsonString.data(using: .utf8) {
            do {
                let analysis = try JSONDecoder().decode(ErrorAnalysis.self, from: dataFromString)
                // Se Ollama non ha trovato un errore reale, ritorniamo nil per non inquinare la UI
                if analysis.category == "Nessuno" { return nil }
                return analysis
            } catch {
                print("Ollama JSON Decode Error: \(error)")
                return nil
            }
        }
        return nil
    }
}

