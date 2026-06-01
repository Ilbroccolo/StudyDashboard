import SwiftUI

struct FuturePlannerView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 40) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pianificatore Futuro")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Palette.primaryText)
                    
                    Text("Analisi degli obiettivi e struttura del piano di studio")
                        .font(.title3)
                        .foregroundColor(Palette.secondaryText)
                }
                .padding(.top, 20)
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // OBIETTIVI FUTURI
                VStack(alignment: .leading, spacing: 24) {
                    Text("OBIETTIVI A BREVE/MEDIO TERMINE")
                        .font(.headline)
                        .foregroundColor(Palette.secondaryText)
                    
                    VStack(spacing: 16) {
                        GoalCard(
                            exam: "Analisi 1",
                            date: "Appello: Luglio",
                            status: "In Corso",
                            progress: 0.65,
                            color: Palette.growthAccent
                        )
                        
                        GoalCard(
                            exam: "Programmazione ad Oggetti",
                            date: "Appello: Settembre",
                            status: "Pianificato",
                            progress: 0.0,
                            color: Palette.chartStart
                        )
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // ANALISI STRUTTURALE (IL "BLOCCO DI ANALISI")
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("STRUTTURA E SUGGERIMENTI AI")
                            .font(.headline)
                            .foregroundColor(Palette.secondaryText)
                        Spacer()
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dall'analisi delle tue sessioni passate:")
                            .font(.subheadline)
                            .foregroundColor(Palette.primaryText)
                        
                        AIInsightRow(icon: "chart.line.downtrend.xyaxis", text: "La tua resa cala dopo il terzo Pomodoro consecutivo. Pianifichiamo pause più lunghe.")
                        AIInsightRow(icon: "function", text: "I limiti di Taylor rallentano le simulazioni. Mese prossimo focalizzato solo sui limiti.")
                        AIInsightRow(icon: "calendar.badge.plus", text: "Per preparare Algoritmi a Settembre, devi iniziare le basi teoriche entro il 15 Agosto.")
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding(40)
        }
    }
}

struct GoalCard: View {
    var exam: String
    var date: String
    var status: String
    var progress: Double
    var color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exam)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.primaryText)
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(Palette.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
                
                // Mini progress
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.05)).frame(width: 100, height: 4)
                        Capsule().fill(color).frame(width: 100 * CGFloat(progress), height: 4)
                    }
                }
                .frame(width: 100, height: 4)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct AIInsightRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Palette.growthAccent)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(Palette.primaryText)
                .lineSpacing(4)
        }
    }
}
