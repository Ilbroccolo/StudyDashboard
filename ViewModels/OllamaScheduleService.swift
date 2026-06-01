import Foundation

class OllamaScheduleService {
    
    let endpoint = "http://localhost:11434/api/generate"
    let model = "llama3"
    
    let systemPrompt = """
    Sei il Gestore Logistico di uno studente di Ingegneria.
    Lo studente ha un "Master Plan" giornaliero composto da blocchi di tempo (TimeBlock).
    Ci è stato comunicato un IMPREVISTO (es. "Vado al mare stamattina").
    
    Il tuo compito è riorganizzare i blocchi di tempo rispettando questa REGOLA D'ORO:
    1. Salva la Simulazione Pura: se salta la mattina, DEVE diventare l'attività del pomeriggio (es. 14:30 - 17:30).
    2. Sacrifica il Debug: se non c'è tempo nel pomeriggio, spostalo alla sera (es. 20:00 - 21:30) o cancellalo del tutto per salvare il resto.
    3. Mantieni l'Allenamento in Palestra fisso (es. 18:00 - 20:00). Non si tocca.
    4. Sostituisci il blocco dell'imprevisto con la nuova attività (es. 08:30-13:00 "Mare / Imprevisto").
    
    Riceverai l'elenco attuale dei blocchi in formato JSON e l'imprevisto.
    Devi restituire in output ESCLUSIVAMENTE il nuovo array JSON dei blocchi, senza alcun testo aggiuntivo.
    
    Esempio di formato di output atteso:
    [
      {"startTime": "08:30", "endTime": "13:00", "activity": "Mare", "isShifted": true},
      {"startTime": "13:00", "endTime": "14:30", "activity": "Pausa Pranzo", "isShifted": false},
      {"startTime": "14:30", "endTime": "17:30", "activity": "Simulazione Quesiti 1, 2, 4, 5, 7", "isShifted": true},
      {"startTime": "18:00", "endTime": "20:00", "activity": "Palestra", "isShifted": false},
      {"startTime": "20:00", "endTime": "21:30", "activity": "Debug Errori Analisi", "isShifted": true}
    ]
    """
    
    func reorganizeSchedule(currentBlocks: [TimeBlock], imprevisto: String) async throws -> [TimeBlock] {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let blocksData = try encoder.encode(currentBlocks)
        let blocksString = String(data: blocksData, encoding: .utf8) ?? "[]"
        
        let promptText = "\(systemPrompt)\n\n--- PIANO ATTUALE ---\n\(blocksString)\n\n--- IMPREVISTO ---\n\(imprevisto)\n\nRestituisci SOLO IL NUOVO ARRAY JSON."
        
        let body: [String: Any] = [
            "model": model,
            "prompt": promptText,
            "format": "json",
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
        
        if let dataFromString = jsonString.data(using: .utf8) {
            do {
                let newBlocks = try JSONDecoder().decode([TimeBlock].self, from: dataFromString)
                return newBlocks
            } catch {
                print("OllamaSchedule Decode Error: \(error)")
                throw error
            }
        }
        throw URLError(.cannotParseResponse)
    }
}
