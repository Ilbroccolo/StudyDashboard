import SwiftUI

struct CalendarWidget: View {
    @State private var isExpanded = false
    
    // Genera i giorni della settimana corrente o del mese in base allo stato
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(isExpanded ? "MESE ATTUALE" : "SETTIMANA ATTUALE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.secondaryText)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Palette.secondaryText)
                        .padding(4)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                MonthView()
            } else {
                WeekView()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct WeekView: View {
    let days = CalendarHelper.getCurrentWeek()
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.date) { day in
                DayCell(day: day)
            }
        }
    }
}

struct MonthView: View {
    let days = CalendarHelper.getCurrentMonth()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // Intestazione giorni
            HStack(spacing: 8) {
                ForEach(["L", "M", "M", "G", "V", "S", "D"], id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Palette.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.date) { day in
                    if day.isPlaceholder {
                        Color.clear.frame(height: 28) // Spazio vuoto
                    } else {
                        DayCell(day: day)
                    }
                }
            }
        }
    }
}

struct DayCell: View {
    var day: CalendarDay
    
    var body: some View {
        VStack(spacing: 4) {
            if day.showWeekday {
                Text(day.weekdaySymbol)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(day.isToday ? Palette.primaryText : Palette.secondaryText)
            }
            
            ZStack {
                if day.isToday {
                    Circle()
                        .stroke(Palette.growthAccent, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Palette.growthAccent.opacity(0.2)))
                } else if day.isCompleted {
                    Circle()
                        .fill(Palette.growthAccent.opacity(0.2))
                        .frame(width: 28, height: 28)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 28, height: 28)
                }
                
                Text("\(day.dayNumber)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(day.isToday || day.isCompleted ? Palette.primaryText : Palette.secondaryText)
                
                if day.isCompleted {
                    Circle()
                        .fill(Palette.growthAccent)
                        .frame(width: 4, height: 4)
                        .offset(y: 18)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Strutture di Supporto
struct CalendarDay: Hashable {
    var date: Date
    var dayNumber: Int
    var weekdaySymbol: String
    var isToday: Bool
    var isCompleted: Bool = false
    var isPlaceholder: Bool = false
    var showWeekday: Bool = true
}

struct CalendarHelper {
    static func getCurrentWeek() -> [CalendarDay] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Lunedì
        let today = Date()
        
        // Trova l'inizio della settimana (Lunedì)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        var days: [CalendarDay] = []
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "it_IT")
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let dayNumber = calendar.component(.day, from: date)
                let weekdayIndex = calendar.component(.weekday, from: date)
                let symbol = String(dateFormatter.shortWeekdaySymbols[weekdayIndex - 1].prefix(1)).uppercased()
                
                let isToday = calendar.isDateInToday(date)
                
                // Segna completati i 3 giorni precedenti ad oggi
                let startOfToday = calendar.startOfDay(for: today)
                let startOfDate = calendar.startOfDay(for: date)
                let diff = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
                let isCompleted = diff > 0 && diff <= 3
                
                days.append(CalendarDay(date: date, dayNumber: dayNumber, weekdaySymbol: symbol, isToday: isToday, isCompleted: isCompleted))
            }
        }
        
        return days
    }
    
    static func getCurrentMonth() -> [CalendarDay] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Lunedì
        let today = Date()
        
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: today) else { return [] }
        
        let startWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = (startWeekday == 1) ? 6 : (startWeekday - 2)
        
        var days: [CalendarDay] = []
        
        for i in 0..<offset {
            let placeholderDate = calendar.date(byAdding: .day, value: -offset + i, to: startOfMonth)!
            days.append(CalendarDay(date: placeholderDate, dayNumber: 0, weekdaySymbol: "", isToday: false, isPlaceholder: true, showWeekday: false))
        }
        
        let startOfToday = calendar.startOfDay(for: today)
        
        for i in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfMonth) {
                let dayNumber = calendar.component(.day, from: date)
                let isToday = calendar.isDateInToday(date)
                
                let startOfDate = calendar.startOfDay(for: date)
                let diff = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
                let isCompleted = diff > 0 && diff <= 3
                
                days.append(CalendarDay(date: date, dayNumber: dayNumber, weekdaySymbol: "", isToday: isToday, isCompleted: isCompleted, showWeekday: false))
            }
        }
        
        return days
    }
}
