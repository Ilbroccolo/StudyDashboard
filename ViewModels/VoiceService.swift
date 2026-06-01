import Foundation
import AppKit
import Combine

class VoiceService: NSObject, ObservableObject, NSSpeechSynthesizerDelegate {
    static let shared = VoiceService()
    
    private let synthesizer = NSSpeechSynthesizer()
    @Published var isVoiceEnabled: Bool = true
    @Published var isSpeaking: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        // Opzionale: impostare una voce specifica italiana se disponibile
        // if let itVoice = NSSpeechSynthesizer.availableVoices.first(where: { $0.rawValue.contains("it-IT") }) {
        //     synthesizer.setVoice(itVoice)
        // }
    }
    
    func speak(_ text: String) {
        guard isVoiceEnabled else { return }
        
        // Pulizia basica del markdown per la lettura (rimuove *, #, etc)
        let cleanText = text
            .replacingOccurrences(of: "\\*\\*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "#", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\$", with: " ", options: .regularExpression)
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        }
        
        synthesizer.startSpeaking(cleanText)
        isSpeaking = true
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        }
        isSpeaking = false
    }
    
    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
