import SwiftUI

enum AppRoute: String, Hashable, CaseIterable {
    case studyRoom = "Sala Studio"
    case personalDashboard = "Profilo Personale"
    case futurePlanner = "Pianificatore Futuro"
    case examWizard = "Nuovo Esame"
}

struct ContentView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var theme = ThemeManager.shared
    
    @State private var selectedRoute: AppRoute? = .studyRoom
    
    var body: some View {
        ZStack {
            NavigationSplitView {
                // Left Column: Navigator
                NavigatorColumn(viewModel: viewModel, selectedRoute: $selectedRoute)
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 350)
            } detail: {
                // Center & Right Columns scambiano in base alla Route
                ZStack {
                    Palette.mainBackground.ignoresSafeArea()
                    
                    switch selectedRoute {
                    case .studyRoom:
                        // La vecchia Sala Studio: Chat + Tracker in HSplitView o HStack
                        HSplitView {
                            ChatColumn(viewModel: viewModel)
                                .frame(minWidth: 400, idealWidth: 600)
                            
                            TrackerColumn(viewModel: viewModel)
                                .frame(minWidth: 250, idealWidth: 280, maxWidth: 350)
                        }
                    case .personalDashboard:
                        PersonalDashboardView(viewModel: viewModel)
                    case .futurePlanner:
                        FuturePlannerView(viewModel: viewModel)
                    case .examWizard:
                        ExamWizardView(viewModel: viewModel)
                    case .none:
                        Text("Seleziona una voce dalla sidebar")
                            .foregroundColor(Palette.secondaryText)
                    }
                }
            }
            .navigationSplitViewStyle(.balanced)
            .overlay(
                Group {
                    if viewModel.showAFKPopup {
                        ZStack {
                            Color.black.opacity(0.8)
                                .ignoresSafeArea()
                                .blur(radius: 10)
                            
                            VStack(spacing: 24) {
                                Image(systemName: "eyes")
                                    .font(.system(size: 64))
                                    .foregroundColor(Palette.growthAccent)
                                
                                Text("Ehi, sei ancora lì?")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Palette.primaryText)
                                
                                Text("Dimostrami che non sei su Netflix.\nHai 3 minuti per cliccare prima che il timer si blocchi.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Palette.secondaryText)
                                
                                Button(action: {
                                    viewModel.confirmStillStudying()
                                }) {
                                    Text("Sì, sto studiando!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 16)
                                        .background(Palette.growthAccent)
                                        .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 16)
                            }
                            .padding(40)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Palette.growthAccent.opacity(0.5), lineWidth: 2)
                            )
                        }
                        .transition(.opacity)
                        .zIndex(100)
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        withAnimation(.easeInOut) { theme.hasStarted = false }
                    }) {
                        Image(systemName: "house.fill")
                            .foregroundColor(Palette.secondaryText)
                    }
                    .help("Torna alla Home")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) { theme.isDarkMode.toggle() }
                    }) {
                        Image(systemName: theme.isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .foregroundColor(theme.isDarkMode ? .yellow : .orange)
                    }
                    .help("Cambia Tema")
                }
            }
            .onAppear {
                viewModel.startWellnessCheck()
            }
            
            // Wellness Check Overlay (in alto o in basso)
            if viewModel.showWellnessCheck {
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.title2)
                            .foregroundColor(Palette.growthAccent)
                        
                        Text("Come stai, Joseph? Se sei esaurito clicca qui. Se non rispondi, so che sei concentrato.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.dismissWellness()
                            // Eventualmente pausa il Pomodoro o suggerisci una pausa
                            if viewModel.isTimerRunning {
                                viewModel.toggleTimer()
                            }
                        }) {
                            Text("HO BISOGNO DI PAUSA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Palette.chartCritical)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Palette.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
                    .padding(40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
                .animation(.spring(), value: viewModel.showWellnessCheck)
            }
            
            // Dim overlay during break
            if viewModel.isBreakTime {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                VStack {
                    Text("Pausa di 10 Minuti")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Alzati, bevi acqua, non guardare lo schermo.")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            // L'Overlay della Home / Splash Screen
            if !theme.hasStarted {
                StartDayView(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(200) // Assicura che sia sempre in primissimo piano
            }
        }
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
    }
}

