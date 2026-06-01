import SwiftUI

struct PersonalDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 40) {
                
                // HEADER PROFILO
                HStack(spacing: 24) {
                    Circle()
                        .fill(Palette.growthAccent.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text("JZ")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Palette.growthAccent)
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Joseph Zucchelli")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Palette.primaryText)
                        
                        Text("Studente in Missione • \(viewModel.rankSystem.currentLevel)")
                            .font(.title3)
                            .foregroundColor(Palette.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("XP TOTALI")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Palette.secondaryText)
                        Text("\(viewModel.rankSystem.experiencePoints)")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(Palette.growthAccent)
                    }
                }
                .padding(.top, 20)
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // PROFILAZIONE APPRENDIMENTO
                VStack(alignment: .leading, spacing: 24) {
                    Text("PROFILO DI APPRENDIMENTO")
                        .font(.headline)
                        .foregroundColor(Palette.secondaryText)
                    
                    HStack(spacing: 24) {
                        ProfileStatBox(title: "PUNTI DI FORZA", value: "Logica, Sintesi", icon: "brain.head.profile", color: Palette.growthAccent)
                        ProfileStatBox(title: "DA MIGLIORARE", value: "Focus Prolungato", icon: "exclamationmark.triangle", color: .orange)
                        ProfileStatBox(title: "STILE COGNITIVO", value: "Visivo / Pratico", icon: "eye.fill", color: Palette.chartStart)
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // STATISTICHE REALI
                VStack(alignment: .leading, spacing: 24) {
                    Text("METRICHE REALI")
                        .font(.headline)
                        .foregroundColor(Palette.secondaryText)
                    
                    HStack(spacing: 24) {
                        MetricBlock(title: "Ore Totali (Stima)", value: "\(viewModel.rankSystem.experiencePoints / 100)h", subtitle: "Basato sugli XP")
                        MetricBlock(title: "Sessioni Pomodoro", value: "\(viewModel.rankSystem.experiencePoints / 50)", subtitle: "Completate")
                        MetricBlock(title: "Ritenzione (Media)", value: "85%", subtitle: "Nelle simulazioni")
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // STORICO SESSIONI E PERCORSI (IA)
                VStack(alignment: .leading, spacing: 24) {
                    Text("STORICO SESSIONI & PERCORSI (IA)")
                        .font(.headline)
                        .foregroundColor(Palette.secondaryText)
                    
                    if viewModel.sessionHistory.isEmpty {
                        Text("Nessuna sessione registrata. Inizia a studiare!")
                            .foregroundColor(Palette.secondaryText)
                    } else {
                        Table(viewModel.sessionHistory) {
                            TableColumn("Data") { session in
                                Text(session.date, style: .date)
                                    .foregroundColor(Palette.secondaryText)
                            }
                            TableColumn("Titolo Percorso (Generato da IA)") { session in
                                HStack {
                                    if let name = session.aiGeneratedName {
                                        Text(name)
                                            .fontWeight(.bold)
                                            .foregroundColor(Palette.growthAccent)
                                    } else {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                        Text("Ollama in elaborazione...")
                                            .foregroundColor(Palette.secondaryText)
                                            .italic()
                                    }
                                }
                            }
                            TableColumn("Durata") { session in
                                Text("\(session.durationMinutes / 60)h \(session.durationMinutes % 60)m")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Palette.primaryText)
                            }
                            TableColumn("XP") { session in
                                Text("+\(session.xpEarned) XP")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Palette.statusTag)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(minHeight: 250)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
            .padding(40)
        }
    }
}

struct ProfileStatBox: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.secondaryText)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Palette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct MetricBlock: View {
    var title: String
    var value: String
    var subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Palette.secondaryText)
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(Palette.primaryText)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Palette.statusTag)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
