# 🎓 StudyDashboard

![macOS](https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Blue?style=for-the-badge&logo=swift&logoColor=white)
![Gemini API](https://img.shields.io/badge/Gemini_1.5_Flash-Powered-orange?style=for-the-badge&logo=google&logoColor=white)
![Ollama](https://img.shields.io/badge/Ollama-Local_Inference-white?style=for-the-badge&logo=meta&logoColor=black)

StudyDashboard è un'applicazione macOS nativa, sviluppata interamente in SwiftUI con pattern architetturale MVVM. Rappresenta l'avanguardia degli ambienti di studio digitali, fondendo tecniche di deep work (Pomodoro) con un ecosistema multi-agente basato su Large Language Models (LLM).

L'obiettivo principale dell'applicazione non è fornire le risposte allo studente, ma agire come un **tutor socratico**, pungolando l'utente, penalizzandolo in caso di errori metodologici e gestendo in modo autonomo le pause e i blocchi di studio.

---

## 🧠 Gestione dell'Intelligenza Artificiale (Multi-Agent System)

Il vero cuore tecnico della piattaforma è la sua architettura AI ibrida (Cloud + Edge), concepita per bilanciare latenza, intelligenza deduttiva e costi. Il sistema si basa su due motori separati che collaborano asincronamente:

### 1. Primary Engine: Gemini (Cloud)
Gestito dal `GeminiService`, agisce come l'agente conversazionale principale.
- **Tutor Socratico**: Non fornisce mai la soluzione diretta (zero-shot). Viene istruito tramite System Prompts per obbligare lo studente a scomporre i problemi matematici o algoritmici.
- **Multimodalità (Vision)**: Permette l'upload di screenshot o immagini (es. formule matematiche, blocchi di codice C/Swift). L'immagine viene processata assieme al prompt testuale per fornire un feedback contestuale.
- **Agente di Pianificazione**: Tramite chiamate dedicate, analizza eventuali imprevisti o modifiche d'orario e rigenera l'intera struttura dei blocchi temporali della giornata.
- **Generazione Dinamica UI**: Riconosce e renderizza formule LaTeX tramite la libreria `SwiftUIMath`.

### 2. Shadow Critic Engine: Ollama (Local/Edge)
Gestito dall'`OllamaService`, è un modello locale (es. Llama 3 o Mistral) che opera in totale background, in modalità invisibile per l'utente, garantendo inferenze a costo zero e zero-latenza di rete per le task ricorsive.
- **Structured Output (JSON)**: Il modello locale riceve l'input dell'utente e la risposta appena fornita da Gemini, analizzando l'interazione. Ritorna esclusivamente un output JSON parsabile.
- **Gamification Penalizzante**: Ollama categorizza gli errori dello studente (es. errore di calcolo, lacuna teorica, distrazione) e valuta la gravità ("Alta", "Media", "Bassa"). Se viene rilevata una lacuna grave o una dipendenza passiva dall'IA, l'engine deduce punti Esperienza (XP) dal profilo dell'utente in tempo reale.
- **Resilienza**: Le query a Ollama vengono messe in una coda asincrona (Task/Actor-based). Se il demone locale di Ollama è offline, le task vengono accodate e processate non appena il servizio torna disponibile.

---

## 📐 Struttura delle Pagine e Views (Architettura UI)

L'interfaccia segue i princìpi del **Neumorfismo** unito a un design dashboard modulare, sviluppato in SwiftUI. La Window principale suddivide il layout in tre colonne logiche.

### `ContentView.swift` (Main Layout)
Il container principale che ospita la struttura a tre colonne (`NavigatorColumn`, `ChatColumn`, `TrackerColumn`). Usa `Combine` e `@EnvironmentObject` per iniettare lo stato globale (il `DashboardViewModel`) in tutta l'alberatura delle view.

### `StartDayView.swift`
Una view transitoria, dal forte impatto visivo tipografico, che accoglie l'utente al lancio dell'app. Oltre al greeting iniziale, avvia i task di fetching del calendario e innesca la transizione verso il layout tripartito.

### Colonna Sinistra: `NavigatorColumn.swift`
Il centro di comando per la navigazione e lo status dell'utente.
- **Gamification Card**: Mostra il Rank corrente dell'utente (es. "Iniziato", "Maestro"), i punti XP attuali e una progress bar animata verso il prossimo livello.
- **Navigazione Interna**: Switch di view (Chat, Profilo, Pianificazione) usando enum di routing iniettati come State.

### Colonna Centrale: `ChatColumn.swift`
L'hub dell'interazione con l'IA.
- **ScrollView Proxy**: Scroll automatico all'ultimo messaggio in arrivo tramite ID tracking.
- **Message Bubbles**: Riconoscono il ruolo (`user`, `ai`, `system`) e applicano stilizzazioni diverse. Supportano l'integrazione fluida di testo markdown e formule LaTeX.
- **Input System (MacTextField)**: Implementazione di un custom `NSViewRepresentable` per aggirare le limitazioni di `TextField` nativo su macOS (gestione fluida dell'invio con `Enter` e new-line con `Shift+Enter`).

### Colonna Destra: `TrackerColumn.swift`
Dedicata al Deep Work, alla telemetria e all'ecosistema di terze parti.
- **Pomodoro Engine**: Gestione reattiva dei timer, con transizioni di stato (Focus/Break).
- **Global Anti-AFK (Vigilante)**: Un timer hardware globale (`Timer.publish`) che traccia passivamente i secondi di inattività. Se l'utente non interagisce per periodi superiori alle soglie pre-impostate, blocca il timer di studio e innesca chiamate vocali in Text-To-Speech (tramite `AVSpeechSynthesizer` in `VoiceService.swift`).
- **Spotify Manager**: Sfrutta protocolli IPC (`AppleScript`) per comunicare localmente con l'app desktop di Spotify, permettendo all'utente di vedere la traccia in esecuzione e comandare la riproduzione (Play/Pause, Next) senza alcun context switch.

### Views Secondarie
- **`PersonalDashboardView.swift`**: La scheda tecnica dello studente, mostra la history delle sessioni, lo split di studio e l'audit log (Error Analysis) generato dal Critical Engine (Ollama).
- **`ExamWizardView.swift`**: Flusso multi-step modale per l'inserimento formale di un esame, che converte le preferenze e lo scheduling in profili JSON parsati internamente.
- **`FuturePlannerView.swift`**: Calendario espanso basato su Grid layout per l'allocazione massiva a lungo termine.

---

## 🛠 Tech Stack Dettagliato

- **Linguaggio**: Swift 5.9
- **Framework UI**: SwiftUI (macOS 14+ target)
- **State Management**: Combine (`@StateObject`, `@Published`, `AnyCancellable` per la gestione esplicita del ciclo di vita dei timer).
- **Concorrenza**: Swift Concurrency (`async/await`, `Task`, `MainActor` isolation).
- **Persistenza**: `UserDefaults` struct-encoded via `Codable` per memorizzazione rapida, gestito tramite un Singleton centralizzato (`StorageManager`).
- **Integrazioni Esterne**: 
  - *GoogleGenerativeAI SDK* (Network/API).
  - *Ollama HTTP API* (Localhost REST).
  - *NSAppleScript* (Inter-Process Communication per Spotify).
  - *AVFoundation* (TTS locale per vigilante agent).
  - *SwiftUIMath* (Package esterno per rendering equazioni).

## 🚀 Setup & Installazione

1. Clona il repository:
   ```bash
   git clone https://github.com/Ilbroccolo/StudyDashboard.git
   ```
2. **Setup Chiavi API**:
   Apri il file `Core/Secrets.swift` e inserisci il token di Gemini. *(Nota: per questioni di sicurezza, questo branch `main` non traccia le chiavi personali nella history)*.
   ```swift
   struct Secrets {
       static let geminiApiKey = "INSERISCI_QUI_LA_TUA_CHIAVE"
   }
   ```
3. **Setup Ollama (Integrazione Critica)**:
   - Installa [Ollama](https://ollama.com).
   - Apri il terminale e scarica un modello leggero: `ollama run llama3` o `ollama run mistral`.
   - L'applicazione interrogherà automaticamente `http://localhost:11434` in background durante le tue sessioni di studio.

4. Compila ed esegui tramite Xcode o riga di comando (`swift run`).

---
*Architected for Flow State and Deep Work mastery.*
