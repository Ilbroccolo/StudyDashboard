import SwiftUI

struct StartDayView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    
    var greetingPart1: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "BUONGIORNO," }
        else if hour < 18 { return "BUON POMERIGGIO," }
        else { return "BUONASERA," }
    }
    
    var body: some View {
        ZStack {
            Palette.mainBackground.ignoresSafeArea()
            
            HStack(spacing: 20) {
                // COLONNA SINISTRA: L'Impatto Tipografico
                VStack(alignment: .center, spacing: 16) {
                    Text("\(greetingPart1)\nJOSEPH.")
                        .font(.system(size: 72, weight: .heavy, design: .default))
                        .foregroundColor(Palette.primaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                    
                    Text("Respira. Il tempo è il tuo alleato,\nla concentrazione la tua arma.")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Palette.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            themeManager.hasStarted = true
                        }
                    }) {
                        Text("ENTRA NEL FLOW →")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Palette.secondaryText)
                            .padding(.top, 40)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.leading, 60)
                
                Spacer()
                
                // COLONNA DESTRA: La Timeline (Orario Odierno)
                VStack(alignment: .leading, spacing: 0) {
                    TimelineNode(time: "08:30 - 13:00", title: "Mare / Stacco Totale", state: .past)
                    TimelineNode(time: "14:30 - 17:30", title: "Simulazione Analisi (Shift)", state: .past)
                    TimelineNode(time: "18:00 - 20:00", title: "Palestra", state: .past)
                    TimelineNode(time: "20:00 - 23:30", title: "Sviluppo & Debug", state: .present)
                    TimelineNode(time: "23:30", title: "Coprifuoco Schermi", state: .future, isLast: true)
                }
                .padding(.trailing, 60)
            }
        }
    }
}

// COMPONENTE: Singolo Nodo della Timeline
struct TimelineNode: View {
    enum NodeState { case past, present, future }
    
    var time: String
    var title: String
    var state: NodeState
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Struttura Linea e Pallino
            VStack(spacing: 0) {
                ZStack {
                    switch state {
                    case .past:
                        Circle().fill(Palette.secondaryText.opacity(0.5)).frame(width: 12, height: 12)
                    case .present:
                        Circle().fill(Palette.growthAccent).frame(width: 16, height: 16)
                            .shadow(color: Palette.growthAccent.opacity(0.6), radius: 8) // Effetto Glow
                    case .future:
                        Circle().stroke(Palette.secondaryText, lineWidth: 2).frame(width: 12, height: 12)
                    }
                }
                .frame(height: 24) // Allinea il pallino con il testo
                
                if !isLast {
                    Rectangle()
                        .fill(Palette.secondaryText.opacity(0.3))
                        .frame(width: 2)
                        // Altezza della linea per distanziare gli elementi
                        .frame(height: 50) 
                }
            }
            
            // Testo
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(state == .present ? Palette.primaryText : Palette.secondaryText.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 18, weight: state == .present ? .semibold : .regular))
                    .foregroundColor(state == .present ? Palette.primaryText : Palette.secondaryText.opacity(0.6))
            }
            .padding(.top, 2)
        }
    }
}
