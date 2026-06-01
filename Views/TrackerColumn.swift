import SwiftUI

struct TrackerColumn: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    @StateObject private var spotifyManager = SpotifyManager()

    @State private var isPulsing = false
    @State private var showImprovementDetails = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) { // Spaziatura generosa (Stitch)
                
                // RANK SYSTEM & XP
                VStack(alignment: .leading, spacing: 12) {
                    Text("RANK ATTUALE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.secondaryText)
                    
                    HStack(alignment: .bottom) {
                        Text(viewModel.rankSystem.currentLevel)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.primaryText)
                        Spacer()
                        Text("\(viewModel.rankSystem.experiencePoints) XP")
                            .font(.system(.body, design: .monospaced)) // Monospaced for numbers
                            .fontWeight(.bold)
                            .foregroundColor(Palette.growthAccent)
                    }
                    
                    // Flat Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: geometry.size.width, height: 6)
                            
                            Capsule()
                                .fill(Palette.growthAccent)
                                .frame(width: max(0, geometry.size.width * CGFloat(viewModel.rankSystem.progress)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                Divider().overlay(Color.white.opacity(0.05)) // Whisper Border
                
                // Pomodoro Timer
                VStack(spacing: 24) {
                    Text(viewModel.isBreakTime ? "PAUSA" : "FOCUS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.isBreakTime ? Palette.growthAccent : .orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ZStack {
                        // Semicircle Sfondo Flat
                        Circle()
                            .trim(from: 0.0, to: 0.5)
                            .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(180))
                        
                        // Semicircle Progresso Flat
                        let progress = 1.0 - (Double(viewModel.timeRemaining) / Double(max(1, viewModel.totalPomodoroTime)))
                        let trimProgress = 0.5 * max(0, min(1.0, progress))
                        Circle()
                            .trim(from: 0.0, to: trimProgress)
                            .stroke(Palette.growthAccent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(180))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.timeRemaining) // Spring physics
                        
                        // Testo Timer Monospaced
                        Text(viewModel.timeString)
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(Palette.primaryText)
                            .offset(y: -15)
                    }
                    .frame(height: 100, alignment: .top)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.toggleTimer()
                        }) {
                            Text(viewModel.isTimerRunning ? "Pausa" : "Inizia")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.05))
                                .foregroundColor(Palette.primaryText)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            viewModel.addFiveMinutes()
                        }) {
                            Text("+5")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Palette.growthAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Palette.growthAccent.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Preset per il Timer (Solo in Pausa)
                    if !viewModel.isTimerRunning {
                        HStack(spacing: 12) {
                            ForEach([25, 50, 90], id: \.self) { min in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.setCustomTimer(minutes: min)
                                    }
                                }) {
                                    Text("\(min)m")
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Palette.secondaryText)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // Flat Spotify Widget
                HStack(spacing: 16) {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(spotifyManager.currentTrack == "Non in riproduzione" ? Palette.secondaryText : Palette.growthAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if spotifyManager.currentTrack == "Non in riproduzione" {
                            Text("Spotify Disconnesso")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Palette.primaryText)
                            
                            Button(action: {
                                if let url = URL(string: "spotify://") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("Apri l'app")
                                    .font(.caption)
                                    .foregroundColor(Palette.growthAccent)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text(spotifyManager.currentTrack)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Palette.primaryText)
                                .lineLimit(1)
                            if !spotifyManager.currentArtist.isEmpty {
                                Text(spotifyManager.currentArtist)
                                    .font(.caption)
                                    .foregroundColor(Palette.secondaryText)
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                    
                    if spotifyManager.currentTrack != "Non in riproduzione" {
                        HStack(spacing: 12) {
                            Button(action: { spotifyManager.previousTrack() }) {
                                Image(systemName: "backward.fill").foregroundColor(Palette.secondaryText)
                            }.buttonStyle(PlainButtonStyle())
                            
                            Button(action: { spotifyManager.togglePlayPause() }) {
                                Image(systemName: spotifyManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Palette.primaryText)
                            }.buttonStyle(PlainButtonStyle())
                            
                            Button(action: { spotifyManager.nextTrack() }) {
                                Image(systemName: "forward.fill").foregroundColor(Palette.secondaryText)
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // Scheda di Miglioramento Flat
                Button(action: {
                    showImprovementDetails = true
                }) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("SCHEDA ERRORI")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Palette.secondaryText)
                            
                            Spacer()
                            
                            if !viewModel.errorAnalyses.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        viewModel.clearErrorReports()
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Archivia storici errori")
                            }
                        }
                        
                        if viewModel.errorAnalyses.isEmpty {
                            Text("Nessun errore tracciato finora.")
                                .font(.subheadline)
                                .foregroundColor(Palette.secondaryText)
                        } else {
                            ForEach(viewModel.errorAnalyses.prefix(3)) { error in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(error.category)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Palette.primaryText)
                                        Spacer()
                                        Text(error.severity)
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(severityColor(error.severity).opacity(0.2))
                                            .foregroundColor(severityColor(error.severity))
                                            .cornerRadius(4)
                                    }
                                    
                                    // Flat Progress Bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.05))
                                                .frame(width: geometry.size.width, height: 4)
                                            
                                            Capsule()
                                                .fill(severityColor(error.severity))
                                                .frame(width: max(0, geometry.size.width * CGFloat(error.progress)), height: 4)
                                        }
                                    }
                                    .frame(height: 4)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .sheet(isPresented: $showImprovementDetails) {
            ImprovementDetailsPopup(viewModel: viewModel)
        }
    }
    
    func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "alta": return Palette.chartCritical
        case "media": return .orange
        case "bassa": return Palette.growthAccent
        default: return Palette.statusTag
        }
    }
}

struct ImprovementDetailsPopup: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Palette.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Dettagli Miglioramento")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.primaryText)
                    Spacer()
                    
                    if !viewModel.errorAnalyses.isEmpty {
                        Button(action: {
                            withAnimation {
                                viewModel.clearErrorReports()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.title)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .padding(.trailing, 8)
                        .buttonStyle(PlainButtonStyle())
                        .help("Archivia storici errori")
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Palette.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.errorAnalyses.isEmpty {
                            Text("Nessun dato da mostrare.")
                                .foregroundColor(Palette.secondaryText)
                        } else {
                            ForEach(viewModel.errorAnalyses) { error in
                                CardView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(error.category)
                                                .font(.headline)
                                                .foregroundColor(Palette.primaryText)
                                            Spacer()
                                            Text(error.severity)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.orange.opacity(0.8)) // Default to orange for popup simplicity or use a function
                                                .cornerRadius(8)
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                        }
                                        
                                        Text("Problema: \(error.specificIssue)")
                                            .font(.subheadline)
                                            .foregroundColor(Palette.secondaryText)
                                            .padding(.top, 4)
                                            
                                        Text("Frequenza stimata: \(error.frequency)")
                                            .font(.caption)
                                            .foregroundColor(Palette.statusTag)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
