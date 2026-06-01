import SwiftUI

struct NavigatorColumn: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedRoute: AppRoute?
    
    var body: some View {
        List(selection: $selectedRoute) {
            
            Section("Dashboard Navigazione") {
                NavigationLink(value: AppRoute.studyRoom) {
                    Label("Sala Studio", systemImage: "macwindow")
                }
                NavigationLink(value: AppRoute.personalDashboard) {
                    Label("Profilo Personale", systemImage: "person.crop.square.fill")
                }
                NavigationLink(value: AppRoute.futurePlanner) {
                    Label("Pianificatore", systemImage: "calendar.badge.clock")
                }
                NavigationLink(value: AppRoute.examWizard) {
                    Label("Nuovo Esame", systemImage: "plus.square.dashed")
                        .foregroundColor(Palette.growthAccent)
                }
            }
            
            Section("Oggi") {
                // Objective Block
                CardView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OBIETTIVO PRIMARIO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.secondaryText)
                    
                    Text(UserContext.primaryObjective)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.primaryText)
                    
                    Text("Target: \(UserContext.primaryTarget)")
                        .font(.subheadline)
                        .foregroundColor(Palette.growthAccent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Mini-Calendario Settimanale Dinamico
            CalendarWidget()
            
            // Timeline (Orario Odierno)
            CardView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("TIMELINE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(viewModel.dailyBlocks.enumerated()), id: \.element.id) { index, block in
                            HStack(alignment: .top, spacing: 16) {
                                // Tracking line & dots
                                VStack(spacing: 0) {
                                    ZStack {
                                        if let current = viewModel.currentBlockIndex {
                                            if index < current {
                                                // Passato
                                                Circle()
                                                    .fill(Palette.secondaryText)
                                                    .frame(width: 12, height: 12)
                                            } else if index == current {
                                                // Presente
                                                Circle()
                                                    .stroke(Palette.growthAccent, lineWidth: 3)
                                                    .frame(width: 16, height: 16)
                                                    .background(Circle().fill(Palette.cardBackground))
                                                    .shadow(color: Palette.growthAccent.opacity(0.5), radius: 4)
                                            } else {
                                                // Futuro
                                                Circle()
                                                    .stroke(Palette.secondaryText, lineWidth: 2)
                                                    .frame(width: 12, height: 12)
                                                    .background(Circle().fill(Palette.cardBackground))
                                            }
                                        } else {
                                            Circle()
                                                .stroke(Palette.secondaryText, lineWidth: 2)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    
                                    if index != viewModel.dailyBlocks.count - 1 {
                                        Rectangle()
                                            .fill(Palette.secondaryText.opacity(0.3))
                                            .frame(width: 2, height: 30)
                                    }
                                }
                                
                                // Testo
                                VStack(alignment: .leading, spacing: 4) {
                                    let isCurrent = viewModel.currentBlockIndex == index
                                    let isPast = viewModel.currentBlockIndex != nil && index < viewModel.currentBlockIndex!
                                    
                                    Text("\(block.startTime) - \(block.endTime)")
                                        .font(.caption2)
                                        .foregroundColor(isCurrent ? Palette.growthAccent : Palette.secondaryText)
                                    
                                    Text(block.activity)
                                        .font(.caption)
                                        .foregroundColor(isPast ? Palette.secondaryText : Palette.primaryText)
                                        .opacity(isPast ? 0.6 : 1.0)
                                }
                                .padding(.top, -2)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                }
            }
            
            // Box Esercizi e Test
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundColor(Palette.growthAccent)
                        Text("ESERCIZI E TEST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Palette.secondaryText)
                    }
                    
                    Button(action: {
                        viewModel.showMasterLimits()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Limiti Livello Master")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("5 Esercizi (Taylor)")
                                    .font(.caption)
                                    .foregroundColor(Palette.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundColor(Palette.growthAccent)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            } // Chiude Section("Oggi")
        }
        .listStyle(.sidebar)
    }
}
